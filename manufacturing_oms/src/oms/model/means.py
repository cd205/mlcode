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

    @classmethod
    def per_group_size(cls, stage: Stage, mu: Mapping[int, Mapping[str, float]]) -> MeanSettings:
        """One Mean Setting per Feature per Rework Group Size (thesis Eq 3.26-3.27, Sec. 3.5).

        A Rework State S uses `mu[len(S)]`. The Initial State processes every Feature, so it uses
        `mu[N]`, as does the Rework State of all N Features. `group_size_features` gives the keys needed.
        """
        layout = group_size_features(stage)
        if set(mu) != set(layout):
            raise ValueError(
                f"per_group_size needs means for exactly the group sizes {sorted(layout)}, got {sorted(mu)}"
            )
        for size, names in layout.items():
            if set(mu[size]) != set(names):
                raise ValueError(f"group size {size} needs a mean for exactly {list(names)}, got {sorted(mu[size])}")
        return cls(
            {s: {n: mu[_group_size(s, stage)][n] for n in processed_features(s, stage.features)} for s in stage.states}
        )

    def check_against(self, stage: Stage) -> None:
        """Raise unless there is a mean for every Feature processed in every state of the Stage."""
        if set(self.by_state) != set(stage.states):
            raise ValueError("Mean Settings must cover exactly the Stage's transient states")
        for state in stage.states:
            expected = set(processed_features(state, stage.features))
            if set(self.by_state[state]) != expected:
                raise ValueError(f"state {sorted(state)} needs means for exactly {sorted(expected)}")


def group_size_features(stage: Stage) -> dict[int, tuple[str, ...]]:
    """The Features needing a Mean Setting at each Rework Group Size, in state then Feature order.

    The Initial State processes all N Features, so it uses the group-size-N means. With a Rework Side of
    `none` some Features never join a Rework State, so a smaller group size may need only some of them,
    and the largest Rework State gets its own means rather than sharing the Initial State's.
    """
    layout: dict[int, set[str]] = {}
    for state in stage.states:
        layout.setdefault(_group_size(state, stage), set()).update(processed_features(state, stage.features))
    return {size: tuple(n for n in stage.feature_names if n in names) for size, names in layout.items()}


def _group_size(state: State, stage: Stage) -> int:
    return len(processed_features(state, stage.features))
