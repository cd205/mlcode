"""Feature and Rework Side (GLOSSARY: Feature, Specification Limits, Rework Side)."""

from __future__ import annotations

import math
from dataclasses import dataclass
from enum import Enum


class ReworkSide(Enum):
    """The side of the Specification Limits where an out-of-spec value can still be reworked."""

    UPPER = "upper"
    LOWER = "lower"
    NONE = "none"


@dataclass(frozen=True)
class Feature:
    """One inspectable dimension of a part, judged against its Specification Limits [lower, upper]."""

    name: str
    lower: float
    upper: float
    rework_side: ReworkSide  # required, no default

    def __post_init__(self) -> None:
        if not isinstance(self.name, str) or not self.name:
            raise ValueError("Feature name must be a non-empty string")
        if not isinstance(self.rework_side, ReworkSide):
            raise TypeError(f"rework_side must be a ReworkSide, got {self.rework_side!r}")
        if not (math.isfinite(self.lower) and math.isfinite(self.upper)):
            raise ValueError(f"Feature {self.name!r}: Specification Limits must be finite")
        if not self.lower < self.upper:
            raise ValueError(f"Feature {self.name!r}: lower limit must be below upper limit")

    @property
    def reworkable(self) -> bool:
        return self.rework_side is not ReworkSide.NONE
