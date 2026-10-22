"""Optimising the Mean Settings of a Sequence (spec §5.4) under the per_feature tying scheme."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from types import MappingProxyType
from typing import Literal

import numpy as np
from scipy.optimize import minimize

from oms.economics.sequence import ProfitBreakdown, evaluate_sequence
from oms.model.means import MeanSettings
from oms.model.sequence import Sequence

Scheme = Literal["per_feature"]
Objective = Literal["expected_profit", "production_cost"]
OptimiserMethod = Literal["L-BFGS-B", "Nelder-Mead"]  # bounded Nelder–Mead for noisy (Monte Carlo) objectives
Bounds = Mapping[str, tuple[float, float]]


@dataclass(frozen=True)
class OptimisationResult:
    """The best Mean Settings found, the objective there, and everything needed to reproduce the search."""

    means: tuple[MeanSettings, ...]  # one per Stage
    breakdown: ProfitBreakdown
    objective: Objective
    objective_value: float  # Expected Profit (maximised) or Processing + Scrap + Rework Cost (minimised)
    scheme: Scheme
    bounds: Bounds
    method: OptimiserMethod
    tol: float
    seed: int
    n_starts: int
    n_evaluations: int
    success: bool

    def __post_init__(self) -> None:
        object.__setattr__(self, "means", tuple(self.means))
        object.__setattr__(self, "bounds", MappingProxyType(dict(self.bounds)))


def optimise_means(
    sequence: Sequence,
    scheme: Scheme = "per_feature",
    *,
    objective: Objective = "expected_profit",
    bounds: Bounds | None = None,
    n_starts: int = 8,
    seed: int = 0,
    method: OptimiserMethod | None = None,
    tol: float = 1e-9,
) -> OptimisationResult:
    """Maximise Sequence Expected Profit, or minimise Processing + Scrap + Rework Cost (U2).

    Default bounds are [L − 3σ, U + 3σ] per Feature. Start points are drawn uniformly within the bounds
    from a generator seeded with `seed`, and `seed` also seeds every Monte Carlo box probability, so the
    same seed gives the same result. With no `method`, L-BFGS-B is used unless the objective contains
    Monte Carlo terms (Stages of 4 or more correlated Features), when bounded Nelder–Mead is used; that
    probe evaluation is counted. Inspection Cost doesn't depend on the Mean Settings, so maximising E(PR)
    also maximises E(PR) − I (spec §2.2).
    """
    if scheme != "per_feature":
        raise ValueError(f"unsupported tying scheme {scheme!r}; only 'per_feature' is supported")
    if objective not in ("expected_profit", "production_cost"):
        raise ValueError(f"unknown objective {objective!r}")
    if method not in (None, "L-BFGS-B", "Nelder-Mead"):
        raise ValueError(f"unsupported optimiser {method!r}")
    if n_starts < 1:
        raise ValueError("n_starts must be at least 1")
    names = [name for stage in sequence.stages for name in stage.feature_names]
    bounds_by_feature = dict(bounds) if bounds is not None else _default_bounds(sequence)
    if set(bounds_by_feature) != set(names):
        raise ValueError(f"bounds must be given for exactly {names}")
    limits = [bounds_by_feature[n] for n in names]

    def expand(theta: np.ndarray) -> tuple[MeanSettings, ...]:
        mu = dict(zip(names, map(float, theta)))
        return tuple(
            MeanSettings.per_feature(stage, {n: mu[n] for n in stage.feature_names}) for stage in sequence.stages
        )

    def evaluate(theta: np.ndarray) -> ProfitBreakdown:
        return evaluate_sequence(sequence, expand(theta), rng_seed=seed)

    def value(breakdown: ProfitBreakdown) -> float:
        return breakdown.expected_profit if objective == "expected_profit" else breakdown.production_cost

    sign = -1.0 if objective == "expected_profit" else 1.0

    def loss(theta: np.ndarray) -> float:
        return sign * value(evaluate(theta))

    rng = np.random.default_rng(seed)
    lows, highs = np.array(limits).T
    starts = rng.uniform(lows, highs, size=(n_starts, len(names)))
    n_evaluations = 0
    if method is None:
        method = "Nelder-Mead" if _has_monte_carlo_terms(evaluate(starts[0])) else "L-BFGS-B"
        n_evaluations += 1
    best = None
    for start in starts:
        if method == "L-BFGS-B":
            run = minimize(loss, start, method="L-BFGS-B", bounds=limits, options={"ftol": tol, "gtol": tol})
        else:
            run = minimize(loss, start, method="Nelder-Mead", bounds=limits, options={"xatol": tol, "fatol": tol})
        n_evaluations += int(run.nfev)
        if best is None or run.fun < best.fun:
            best = run
    assert best is not None
    breakdown = evaluate(best.x)
    return OptimisationResult(
        means=expand(best.x),
        breakdown=breakdown,
        objective=objective,
        objective_value=value(breakdown),
        scheme=scheme,
        bounds=bounds_by_feature,
        method=method,
        tol=tol,
        seed=seed,
        n_starts=n_starts,
        n_evaluations=n_evaluations,
        success=bool(best.success),
    )


def _default_bounds(sequence: Sequence) -> dict[str, tuple[float, float]]:
    return {
        f.name: (f.lower - 3 * s, f.upper + 3 * s)
        for stage in sequence.stages
        for f, s in zip(stage.features, stage.variation.standard_deviations)
    }


def _has_monte_carlo_terms(breakdown: ProfitBreakdown) -> bool:
    return any("monte_carlo" in stage.methods for stage in breakdown.stages)
