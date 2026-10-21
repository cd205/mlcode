"""Transition probabilities and the absorbing-chain solve for one Stage (thesis Eq 3.28-3.30, spec §2.1)."""

from __future__ import annotations

import math
from collections.abc import Mapping, Sequence
from dataclasses import dataclass, field
from types import MappingProxyType
from typing import TYPE_CHECKING

import numpy as np

from oms.distributions.base import JointDistribution, Method, Probability
from oms.markov.states import State, enumerate_states, processed_features
from oms.model.feature import Feature, ReworkSide

if TYPE_CHECKING:
    from oms.model.means import MeanSettings
    from oms.model.stage import Stage

Interval = tuple[float, float]


@dataclass(frozen=True)
class StateTransitions:
    """Where one draw from a transient state goes: Conforming, Scrapped, or a Rework State."""

    conform: float
    scrap: float
    rework: Mapping[State, float] = field(default_factory=dict)
    methods: frozenset[Method] = frozenset({"analytic"})
    abs_error: float = 0.0  # summed bound over this state's box probabilities

    def __post_init__(self) -> None:
        object.__setattr__(self, "rework", MappingProxyType(dict(self.rework)))


def stage_transitions(stage: Stage, means: MeanSettings, *, rng_seed: int = 0) -> dict[State, StateTransitions]:
    """Box probabilities of each state's draw, from the marginal distribution of the Features it processes.

    Every box is computed with the same `rng_seed`, so Monte Carlo boxes share their random numbers.
    """
    by_name = {f.name: (i, f) for i, f in enumerate(stage.features)}
    result = {}
    for state in stage.states:
        drawn = processed_features(state, stage.features)
        indices = [by_name[n][0] for n in drawn]
        features = [by_name[n][1] for n in drawn]
        mu = [means.by_state[state][n] for n in drawn]
        result[state] = _draw_transitions(features, stage.variation.marginal(indices), mu, rng_seed)
    return result


def _draw_transitions(
    features: Sequence[Feature], variation: JointDistribution, mu: Sequence[float], rng_seed: int
) -> StateTransitions:
    def box(intervals: Sequence[Interval]) -> Probability:
        lower, upper = [lo for lo, _ in intervals], [hi for _, hi in intervals]
        return variation.box_probability(mu, lower, upper, rng_seed=rng_seed)

    within_limits = [(f.lower, f.upper) for f in features]
    rework = {
        target: box([_rework_interval(f) if f.name in target else within_limits[i] for i, f in enumerate(features)])
        for target in enumerate_states(features)[1:]  # the Rework States reachable from this draw
    }
    conform = box(within_limits)
    not_scrapped = box([_not_scrapped_interval(f) for f in features])
    parts = [conform, not_scrapped, *rework.values()]
    return StateTransitions(
        conform=conform.value,
        scrap=max(0.0, 1.0 - not_scrapped.value),
        rework={state: p.value for state, p in rework.items()},
        methods=frozenset(p.method for p in parts),
        abs_error=sum(p.abs_error for p in parts),
    )


def _rework_interval(feature: Feature) -> Interval:
    if feature.rework_side is ReworkSide.UPPER:
        return (feature.upper, math.inf)
    if feature.rework_side is ReworkSide.LOWER:
        return (-math.inf, feature.lower)
    raise ValueError(f"Feature {feature.name!r} has no Rework Side")


def _not_scrapped_interval(feature: Feature) -> Interval:
    if feature.rework_side is ReworkSide.UPPER:
        return (feature.lower, math.inf)
    if feature.rework_side is ReworkSide.LOWER:
        return (-math.inf, feature.upper)
    return (feature.lower, feature.upper)


def expected_visits(states: Sequence[State], transitions: Mapping[State, StateTransitions]) -> dict[State, float]:
    """m_{I,j}: the Initial-State row of the fundamental matrix M = (I − Q)⁻¹.

    The diagonal of I − Q is built from each state's outflow rather than 1 − p_{s,s}, which keeps
    precision when a Rework State almost always loops back on itself.
    """
    index = {s: k for k, s in enumerate(states)}
    a = np.zeros((len(states), len(states)))
    for s, t in transitions.items():
        outflow = t.conform + t.scrap
        for target, p in t.rework.items():
            if target == s:
                continue
            a[index[s], index[target]] -= p
            outflow += p
        if outflow <= 0.0:
            raise ValueError(f"a part in state {sorted(s)} can never leave it; Mean Settings are degenerate")
        a[index[s], index[s]] = outflow
    initial_row = np.linalg.solve(a.T, np.eye(len(states))[0])
    return {s: float(initial_row[index[s]]) for s in states}
