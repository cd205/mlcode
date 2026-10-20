"""Per-state cost table for one Stage (GLOSSARY: Processing, Rework and Scrap Cost)."""

from __future__ import annotations

import math
from collections.abc import Mapping
from dataclasses import dataclass
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


def _check_cost(label: str, value: float) -> None:
    if not (math.isfinite(value) and value >= 0):
        raise ValueError(f"{label} cost must be finite and non-negative, got {value!r}")
