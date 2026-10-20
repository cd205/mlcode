"""Optimising Mean Settings (spec §5.4). Stage 1 covers one Stage under the per_feature tying scheme."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from types import MappingProxyType
from typing import Literal

import numpy as np
from scipy.optimize import minimize

from oms.economics.stage import StageResult, evaluate_stage
from oms.model.means import MeanSettings
from oms.model.stage import Stage

Scheme = Literal["per_feature"]
Objective = Literal["expected_profit", "production_cost"]
OptimiserMethod = Literal["L-BFGS-B", "Nelder-Mead"]  # bounded Nelder–Mead for noisy (Monte Carlo) objectives
Bounds = Mapping[str, tuple[float, float]]


@dataclass(frozen=True)
class OptimisationResult:
    """The best Mean Settings found, the objective there, and everything needed to reproduce the search."""

    means: MeanSettings
    stage_result: StageResult
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
        object.__setattr__(self, "bounds", MappingProxyType(dict(self.bounds)))


def optimise_means(
    stage: Stage,
    selling_price: float,
    scheme: Scheme = "per_feature",
    *,
    objective: Objective = "expected_profit",
    bounds: Bounds | None = None,
    n_starts: int = 8,
    seed: int = 0,
    method: OptimiserMethod = "L-BFGS-B",
    tol: float = 1e-9,
) -> OptimisationResult:
    """Maximise single-Stage Expected Profit, or minimise Processing + Scrap + Rework Cost (U2).

    Default bounds are [L − 3σ, U + 3σ] per Feature. Start points are drawn uniformly within the
    bounds from a generator seeded with `seed`, so the same seed gives the same result.
    """
    if scheme != "per_feature":
        raise ValueError(f"unsupported tying scheme {scheme!r}; Stage 1 provides 'per_feature' only")
    if objective not in ("expected_profit", "production_cost"):
        raise ValueError(f"unknown objective {objective!r}")
    if method not in ("L-BFGS-B", "Nelder-Mead"):
        raise ValueError(f"unsupported optimiser {method!r}")
    if n_starts < 1:
        raise ValueError("n_starts must be at least 1")
    names = stage.feature_names
    bounds_by_feature = dict(bounds) if bounds is not None else _default_bounds(stage)
    if set(bounds_by_feature) != set(names):
        raise ValueError(f"bounds must be given for exactly {names}")
    limits = [bounds_by_feature[n] for n in names]

    def expand(theta: np.ndarray) -> MeanSettings:
        return MeanSettings.per_feature(stage, dict(zip(names, map(float, theta))))

    def value(result: StageResult) -> float:
        if objective == "expected_profit":
            return result.expected_profit(selling_price)
        return result.production_cost

    sign = -1.0 if objective == "expected_profit" else 1.0

    def loss(theta: np.ndarray) -> float:
        return sign * value(evaluate_stage(stage, expand(theta)))

    rng = np.random.default_rng(seed)
    lows, highs = np.array(limits).T
    best = None
    n_evaluations = 0
    for start in rng.uniform(lows, highs, size=(n_starts, len(names))):
        if method == "L-BFGS-B":
            run = minimize(loss, start, method="L-BFGS-B", bounds=limits, options={"ftol": tol, "gtol": tol})
        else:
            run = minimize(loss, start, method="Nelder-Mead", bounds=limits, options={"xatol": tol, "fatol": tol})
        n_evaluations += int(run.nfev)
        if best is None or run.fun < best.fun:
            best = run
    assert best is not None
    means = expand(best.x)
    stage_result = evaluate_stage(stage, means)
    return OptimisationResult(
        means=means,
        stage_result=stage_result,
        objective=objective,
        objective_value=value(stage_result),
        scheme=scheme,
        bounds=bounds_by_feature,
        method=method,
        tol=tol,
        seed=seed,
        n_starts=n_starts,
        n_evaluations=n_evaluations,
        success=bool(best.success),
    )


def _default_bounds(stage: Stage) -> dict[str, tuple[float, float]]:
    sigmas = stage.variation.standard_deviations
    return {f.name: (f.lower - 3 * s, f.upper + 3 * s) for f, s in zip(stage.features, sigmas)}
