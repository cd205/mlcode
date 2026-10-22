"""Tying schemes (spec §2.3): the optimiser's free parameters θ, expanded into one MeanSettings per Stage."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any, Literal

from oms.markov.states import State, processed_features
from oms.model.means import MeanSettings, group_size_features
from oms.model.sequence import Sequence
from oms.model.stage import Stage

Scheme = Literal["per_feature", "per_group_size", "per_state"]
SCHEMES: tuple[Scheme, ...] = ("per_feature", "per_group_size", "per_state")


class Tying:
    """The free parameters of a Sequence under a scheme, in a fixed order, and their expansion.

    `per_feature` has one parameter per Feature. `per_group_size` has, Stage by Stage, one per Feature
    per Rework Group Size, the Initial State's group size N first (`group_size_features` order).
    `per_state` has, Stage by Stage, one per Feature processed in each transient state (`Stage.states`
    order): N·2^(N−1) + N per Stage when every Feature is reworkable.
    """

    def __init__(self, sequence: Sequence, scheme: Scheme) -> None:
        if scheme not in SCHEMES:
            raise ValueError(f"unsupported tying scheme {scheme!r}; supported: {', '.join(SCHEMES)}")
        self.sequence = sequence
        self.scheme = scheme
        # (Stage index, tying key, Feature name) per parameter. The key is None under per_feature, the
        # Rework Group Size under per_group_size and the state under per_state.
        self._slots: list[tuple[int, int | State | None, str]] = []
        for i, stage in enumerate(sequence.stages):
            if scheme == "per_feature":
                self._slots.extend((i, None, n) for n in stage.feature_names)
            elif scheme == "per_group_size":
                for size, names in group_size_features(stage).items():
                    self._slots.extend((i, size, n) for n in names)
            else:
                for state in stage.states:
                    self._slots.extend((i, state, n) for n in processed_features(state, stage.features))

    @property
    def parameter_features(self) -> tuple[str, ...]:
        """The Feature each free parameter is a Mean Setting of, so bounds can be given per Feature."""
        return tuple(name for _, _, name in self._slots)

    def expand(self, theta: Iterable[float]) -> tuple[MeanSettings, ...]:
        """One MeanSettings per Stage from the free parameters, in `parameter_features` order."""
        values = list(map(float, theta))
        if len(values) != len(self._slots):
            raise ValueError(f"expected {len(self._slots)} free parameters, got {len(values)}")
        # Keyed as in _slots; each scheme reads back only the keys it wrote.
        tables: list[dict[Any, dict[str, float]]] = [{} for _ in self.sequence.stages]
        for (i, key, name), mu in zip(self._slots, values):
            tables[i].setdefault(key, {})[name] = mu
        if self.scheme == "per_feature":
            return tuple(MeanSettings.per_feature(s, t[None]) for s, t in zip(self.sequence.stages, tables))
        if self.scheme == "per_group_size":
            return tuple(MeanSettings.per_group_size(s, t) for s, t in zip(self.sequence.stages, tables))
        return tuple(_checked(MeanSettings(t), s) for s, t in zip(self.sequence.stages, tables))


def _checked(means: MeanSettings, stage: Stage) -> MeanSettings:
    means.check_against(stage)
    return means
