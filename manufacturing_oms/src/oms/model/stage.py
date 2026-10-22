"""Stage: Features processed together before one Inspection (GLOSSARY: Stage)."""

from __future__ import annotations

from dataclasses import dataclass

from oms.distributions.base import JointDistribution
from oms.markov.states import INITIAL_STATE, State, enumerate_states
from oms.model.costs import CostTable, InspectionCost
from oms.model.feature import Feature

MAX_FEATURES = 10


@dataclass(frozen=True)
class Stage:
    """One to ten Features, their Process Variation (means supplied separately) and their costs."""

    features: tuple[Feature, ...]
    variation: JointDistribution
    costs: CostTable
    inspection: InspectionCost = InspectionCost()

    def __post_init__(self) -> None:
        object.__setattr__(self, "features", tuple(self.features))
        if not 1 <= len(self.features) <= MAX_FEATURES:
            raise ValueError(f"a Stage has 1 to {MAX_FEATURES} Features, got {len(self.features)}")
        names = self.feature_names
        if len(set(names)) != len(names):
            raise ValueError(f"Feature names must be unique within a Stage, got {names}")
        if self.variation.dimension != len(self.features):
            raise ValueError(
                f"Process Variation has dimension {self.variation.dimension}, "
                f"but the Stage has {len(self.features)} Features"
            )
        rework_states = set(self.states) - {INITIAL_STATE}
        _check_keys("rework", set(self.costs.rework), rework_states)
        _check_keys("scrap", set(self.costs.scrap), set(self.states))

    @property
    def feature_names(self) -> tuple[str, ...]:
        return tuple(f.name for f in self.features)

    @property
    def states(self) -> tuple[State, ...]:
        """Transient states: the Initial State, then the Rework States (spec §2.1 ordering)."""
        return enumerate_states(self.features)

    @property
    def inspection_cost(self) -> float:
        """The flat Inspection Cost of this Stage per part started (U3)."""
        return self.inspection.for_features(len(self.features))


def _check_keys(label: str, given: set[State], expected: set[State]) -> None:
    if given != expected:
        missing = [sorted(s) for s in expected - given]
        extra = [sorted(s) for s in given - expected]
        raise ValueError(f"{label} costs must cover exactly the states {sorted(map(sorted, expected))}; "
                         f"missing {missing}, unexpected {extra}")
