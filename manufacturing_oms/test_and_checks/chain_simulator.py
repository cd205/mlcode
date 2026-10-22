"""Monte Carlo simulation of parts flowing through a Sequence, written fresh from assumptions A1–A7 (spec §2.4).

Used only to cross-check the engine (spec §6, issue #12). It reads the model's dataclasses for its inputs but
never imports `oms.markov` or `oms.economics`: every part is followed draw by draw through Inspection, rework
and scrap, and the estimates are plain sample means over parts, each with its standard error.
"""

from __future__ import annotations

import math
from collections.abc import Callable
from collections.abc import Sequence as Seq
from dataclasses import dataclass
from itertools import combinations

import numpy as np
from scipy.special import ndtr

from oms import GaussianCopula, MeanSettings, MultivariateNormal, ReworkSide, Sequence, Stage

State = frozenset[str]
MAX_ROUNDS = 100_000  # Inspections of one part in one Stage before the simulation gives up


@dataclass(frozen=True)
class Estimate:
    """A sample mean over parts and its standard error."""

    mean: float
    standard_error: float

    @classmethod
    def of(cls, samples: np.ndarray) -> Estimate:
        if samples.size < 2:
            raise ValueError("an estimate needs at least two parts")
        return cls(float(samples.mean()), float(samples.std(ddof=1) / math.sqrt(samples.size)))


@dataclass(frozen=True)
class SimulatedStage:
    """Per part entering the Stage."""

    n_entering: int
    final_conformance: Estimate
    visits: dict[State, Estimate]  # operations in each transient state, the initial one included
    expected_scrap_cost: Estimate
    expected_rework_cost: Estimate


@dataclass(frozen=True)
class SimulatedSequence:
    """Per part started."""

    n_started: int
    stages: tuple[SimulatedStage, ...]
    final_conformance: Estimate
    expected_profit: Estimate  # SP if the part conforms at the end, less every Processing, Rework and Scrap Cost


def simulate_sequence(sequence: Sequence, means: Seq[MeanSettings], *, n_parts: int, seed: int) -> SimulatedSequence:
    """Start `n_parts` parts; each Stage passes on only the parts it made Conforming (A5)."""
    if len(means) != len(sequence.stages):
        raise ValueError("need one Mean Setting per Stage")
    rng = np.random.default_rng(seed)
    alive = np.arange(n_parts)
    profit = np.zeros(n_parts)
    stages = []
    for stage, stage_means in zip(sequence.stages, means):
        result, conformed, cost = _simulate_stage(stage, stage_means, alive.size, rng)
        stages.append(result)
        profit[alive] -= cost
        alive = alive[conformed]
    conforming = np.zeros(n_parts)
    conforming[alive] = 1.0
    profit += sequence.selling_price * conforming
    return SimulatedSequence(n_parts, tuple(stages), Estimate.of(conforming), Estimate.of(profit))


def _simulate_stage(
    stage: Stage, means: MeanSettings, n: int, rng: np.random.Generator
) -> tuple[SimulatedStage, np.ndarray, np.ndarray]:
    """Follow n parts entering the Stage until each is Conforming or Scrapped.

    Returns the Stage's estimates, which parts conformed, and each part's cost in this Stage.
    """
    draw = _sampler(stage)
    names = stage.feature_names
    # Enumerated here rather than taken from the engine: the Initial State, then every non-empty subset of
    # the reworkable Features, the only sets a draw can send a part to rework.
    reworkable = [f.name for f in stage.features if f.rework_side is not ReworkSide.NONE]
    states: list[State] = [frozenset(g) for k in range(len(reworkable) + 1) for g in combinations(reworkable, k)]
    index = {s: k for k, s in enumerate(states)}
    missing = [sorted(s) for s in states if s not in means.by_state]
    if missing:
        raise ValueError(f"no Mean Settings for states {missing}")
    lower = np.array([f.lower for f in stage.features])
    upper = np.array([f.upper for f in stage.features])
    reworks_above = np.array([f.rework_side is ReworkSide.UPPER for f in stage.features])
    reworks_below = np.array([f.rework_side is ReworkSide.LOWER for f in stage.features])

    state = np.full(n, index[frozenset()])
    visits = np.zeros((n, len(states)))
    conformed = np.zeros(n, dtype=bool)
    scrap_cost = np.zeros(n)
    rework_cost = np.zeros(n)
    pending = np.arange(n)
    for _ in range(MAX_ROUNDS):
        if not pending.size:
            break
        still_pending = []
        for k in np.unique(state[pending]):
            parts = pending[state[pending] == k]
            s = states[k]
            visits[parts, k] += 1
            if s:
                rework_cost[parts] += stage.costs.rework[s]
            # The Initial State makes every Feature; a Rework State remakes only its own, the rest stay
            # conforming (A3). The draw is fresh, from the marginal of the remade Features (A4, A7).
            cols = [i for i, name in enumerate(names) if not s or name in s]
            mu = np.array([means.by_state[s][names[i]] for i in cols])
            x = mu + draw(cols, parts.size, rng)
            above, below = x > upper[cols], x < lower[cols]
            on_rework_side = (above & reworks_above[cols]) | (below & reworks_below[cols])  # part × Feature
            # One Feature on its Scrap Side scraps the part (A2), whatever the others show.
            scrapped = ((above | below) & ~on_rework_side).any(axis=1)
            to_rework = ~scrapped & on_rework_side.any(axis=1)
            scrap_cost[parts[scrapped]] += stage.costs.scrap[s]
            conformed[parts[~scrapped & ~to_rework]] = True
            rework_masks = on_rework_side[to_rework] @ (1 << np.arange(len(cols)))
            for mask in np.unique(rework_masks):
                next_state = frozenset(names[cols[j]] for j in range(len(cols)) if mask >> j & 1)
                state[parts[to_rework][rework_masks == mask]] = index[next_state]
            still_pending.append(parts[to_rework])
        pending = np.concatenate(still_pending)
    else:
        raise RuntimeError(f"parts still in rework after {MAX_ROUNDS} Inspections")

    result = SimulatedStage(
        n_entering=n,
        final_conformance=Estimate.of(conformed.astype(float)),
        visits={s: Estimate.of(visits[:, k]) for s, k in index.items()},
        expected_scrap_cost=Estimate.of(scrap_cost),
        expected_rework_cost=Estimate.of(rework_cost),
    )
    return result, conformed, stage.costs.processing + scrap_cost + rework_cost


Sampler = Callable[[list[int], int, np.random.Generator], np.ndarray]


def _sampler(stage: Stage) -> Sampler:
    """Draws of the deviations from the Mean Settings of the Features at `cols`, one row per part."""
    variation = stage.variation
    if isinstance(variation, MultivariateNormal):
        sigma = np.asarray(variation.sigmas)
        covariance = np.outer(sigma, sigma) * np.asarray(variation.corr)
        return lambda cols, n, rng: _centred_normal(covariance[np.ix_(cols, cols)], n, rng)
    if isinstance(variation, GaussianCopula):
        corr, marginals = np.asarray(variation.corr), variation.marginals

        def copula(cols: list[int], n: int, rng: np.random.Generator) -> np.ndarray:
            # Correlated normal scores, sent through each marginal's quantile function.
            z = _centred_normal(corr[np.ix_(cols, cols)], n, rng)
            return np.column_stack([marginals[i].ppf(ndtr(z[:, j])) for j, i in enumerate(cols)])

        return copula
    raise TypeError(f"the simulator can't draw {type(variation).__name__} Process Variation")


def _centred_normal(covariance: np.ndarray, n: int, rng: np.random.Generator) -> np.ndarray:
    """n draws from N(0, covariance); an eigen factor allows the singular covariance of ±1 correlation."""
    w, v = np.linalg.eigh(covariance)
    factor = v * np.sqrt(np.clip(w, 0.0, None))
    draws: np.ndarray = rng.standard_normal((n, len(covariance))) @ factor.T
    return draws
