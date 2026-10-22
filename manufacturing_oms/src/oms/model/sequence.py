"""Sequence: Stages run in series, each ending in one Inspection (GLOSSARY: Sequence)."""

from __future__ import annotations

import math
from dataclasses import dataclass

from oms.model.stage import Stage


@dataclass(frozen=True)
class Sequence:
    """The Stages a part passes through in order, and the Selling Price of a part that conforms at the end.

    The Stages are independent (A5) and group the part's Features, so no Feature appears in two Stages.
    """

    stages: tuple[Stage, ...]
    selling_price: float

    def __post_init__(self) -> None:
        object.__setattr__(self, "stages", tuple(self.stages))
        if not self.stages:
            raise ValueError("a Sequence needs at least one Stage")
        names = [name for stage in self.stages for name in stage.feature_names]
        if len(set(names)) != len(names):
            raise ValueError(f"Feature names must be unique across a Sequence's Stages, got {names}")
        if not (math.isfinite(self.selling_price) and self.selling_price >= 0):
            raise ValueError(f"Selling Price must be finite and non-negative, got {self.selling_price!r}")
