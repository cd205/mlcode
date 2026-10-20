"""Mean Settings: one mean vector per transient state over the Features it processes (spec §2.3)."""

from __future__ import annotations

import math
from collections.abc import Mapping
from dataclasses import dataclass
from types import MappingProxyType

from oms.markov.states import State, processed_features
from oms.model.stage import Stage


@dataclass(frozen=True)
class MeanSettings:
    """The full per-state form. The tying-scheme constructors expand fewer free parameters into it."""

    by_state: Mapping[State, Mapping[str, float]]

    def __post_init__(self) -> None:
        table = {
            frozenset(state): MappingProxyType({name: float(mu) for name, mu in means.items()})
            for state, means in self.by_state.items()
        }
        for state, means in table.items():
            for name, mu in means.items():
                if not math.isfinite(mu):
                    raise ValueError(f"Mean Setting of {name!r} in state {sorted(state)} must be finite")
        object.__setattr__(self, "by_state", MappingProxyType(table))

    @classmethod
    def per_feature(cls, stage: Stage, mu: Mapping[str, float]) -> MeanSettings:
        """One Mean Setting per Feature, used in every state (thesis Sec. 3.5, Case I)."""
        if set(mu) != set(stage.feature_names):
            raise ValueError(f"per_feature needs a mean for exactly {stage.feature_names}, got {sorted(mu)}")
        return cls({s: {n: mu[n] for n in processed_features(s, stage.features)} for s in stage.states})

    def check_against(self, stage: Stage) -> None:
        """Raise unless there is a mean for every Feature processed in every state of the Stage."""
        if set(self.by_state) != set(stage.states):
            raise ValueError("Mean Settings must cover exactly the Stage's transient states")
        for state in stage.states:
            expected = set(processed_features(state, stage.features))
            if set(self.by_state[state]) != expected:
                raise ValueError(f"state {sorted(state)} needs means for exactly {sorted(expected)}")
