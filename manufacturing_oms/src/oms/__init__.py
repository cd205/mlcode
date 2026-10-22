"""Optimal Mean Setting for multi-feature manufacturing with rework and scrap."""

from oms.distributions import GaussianCopula, MultivariateNormal, Probability
from oms.economics import ProfitBreakdown, StageResult, evaluate_sequence, evaluate_stage
from oms.model import CostTable, Feature, InspectionCost, MeanSettings, ReworkSide, Sequence, Stage
from oms.optimisation import OptimisationResult, SequenceResult, StageBuilder, optimise_means, search_sequences

__all__ = [
    "CostTable",
    "Feature",
    "GaussianCopula",
    "InspectionCost",
    "MeanSettings",
    "MultivariateNormal",
    "OptimisationResult",
    "Probability",
    "ProfitBreakdown",
    "ReworkSide",
    "Sequence",
    "SequenceResult",
    "Stage",
    "StageBuilder",
    "StageResult",
    "evaluate_sequence",
    "evaluate_stage",
    "optimise_means",
    "search_sequences",
]
