"""Tying schemes (spec §2.3): the optimiser's free parameters θ, expanded into one MeanSettings per Stage."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Literal

from oms.model.means import MeanSettings, group_size_features
from oms.model.sequence import Sequence

Scheme = Literal["per_feature", "per_group_size"]
SCHEMES: tuple[Scheme, ...] = ("per_feature", "per_group_size")


class Tying:
    """The free parameters of a Sequence under a scheme, in a fixed order, and their expansion.

    `per_feature` has one parameter per Feature. `per_group_size` has, Stage by Stage, one per Feature
    per Rework Group Size, the Initial State's group size N first (`group_size_features` order).
    """

    def __init__(self, sequence: Sequence, scheme: Scheme) -> None:
        if scheme not in SCHEMES:
            raise ValueError(f"unsupported tying scheme {scheme!r}; supported: {', '.join(SCHEMES)}")
        self.sequence = sequence
        self.scheme = scheme
        # (Stage index, Rework Group Size or None under per_feature, Feature name) per parameter
        self._slots: list[tuple[int, int | None, str]] = []
        for i, stage in enumerate(sequence.stages):
            if scheme == "per_feature":
                self._slots.extend((i, None, n) for n in stage.feature_names)
            else:
                for size, names in group_size_features(stage).items():
                    self._slots.extend((i, size, n) for n in names)

    @property
    def parameter_features(self) -> tuple[str, ...]:
        """The Feature each free parameter is a Mean Setting of, so bounds can be given per Feature."""
        return tuple(name for _, _, name in self._slots)

    def expand(self, theta: Iterable[float]) -> tuple[MeanSettings, ...]:
        """One MeanSettings per Stage from the free parameters, in `parameter_features` order."""
        values = list(map(float, theta))
        if len(values) != len(self._slots):
            raise ValueError(f"expected {len(self._slots)} free parameters, got {len(values)}")
        tables: list[dict[int | None, dict[str, float]]] = [{} for _ in self.sequence.stages]
        for (i, size, name), mu in zip(self._slots, values):
            tables[i].setdefault(size, {})[name] = mu
        if self.scheme == "per_feature":
            return tuple(MeanSettings.per_feature(s, t[None]) for s, t in zip(self.sequence.stages, tables))
        return tuple(
            MeanSettings.per_group_size(s, {k: v for k, v in t.items() if k is not None})
            for s, t in zip(self.sequence.stages, tables)
        )
