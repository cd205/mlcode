"""Per-state cost table for one Stage (GLOSSARY: Processing, Rework and Scrap Cost)."""

from __future__ import annotations

import math
from collections.abc import Mapping
from dataclasses import dataclass
from itertools import combinations
from types import MappingProxyType

from oms.markov.states import State


@dataclass(frozen=True)
class CostTable:
    """Processing Cost, a Rework Cost per Rework State, and a Scrap Cost per transient state.

    States are keyed by the frozenset of reworked Feature names; the Initial State is frozenset().
    Scrap Costs are cumulative (A6): they already include value added in earlier Stages.
    Which keys are required depends on the Stage, so Stage checks them.
    """

    processing: float
    rework: Mapping[State, float]
    scrap: Mapping[State, float]

    def __post_init__(self) -> None:
        _check_cost("processing", self.processing)
        for label in ("rework", "scrap"):
            table = {frozenset(k): float(v) for k, v in getattr(self, label).items()}
            for state, value in table.items():
                _check_cost(f"{label} {sorted(state)}", value)
            object.__setattr__(self, label, MappingProxyType(table))

    @classmethod
    def additive(
        cls, processing: float, rework_per_feature: Mapping[str, float], scrap_per_feature: Mapping[str, float]
    ) -> CostTable:
        """Costs built up from one amount per Feature (thesis Tables 3.7, 3.8).

        `rework_per_feature` names exactly the reworkable Features; a Rework State costs the sum over the
        Features it reworks. `scrap_per_feature` names every Feature of the Stage; a scrapped part loses
        the value of all of them, so every state's Scrap Cost is the same total.
        """
        unknown = set(rework_per_feature) - set(scrap_per_feature)
        if unknown:
            raise ValueError(f"rework costs name Features without a scrap cost: {sorted(unknown)}")
        reworkable = list(rework_per_feature)
        groups = [frozenset(g) for size in range(1, len(reworkable) + 1) for g in combinations(reworkable, size)]
        total_scrap = sum(scrap_per_feature.values())
        return cls(
            processing=processing,
            rework={g: sum(rework_per_feature[n] for n in g) for g in groups},
            scrap={g: total_scrap for g in [frozenset(), *groups]},
        )


def _check_cost(label: str, value: float) -> None:
    if not (math.isfinite(value) and value >= 0):
        raise ValueError(f"{label} cost must be finite and non-negative, got {value!r}")
