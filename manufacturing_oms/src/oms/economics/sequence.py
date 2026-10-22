"""Sequence economics (spec §2.2, §5.3, thesis Eq 3.78): Expected Profit per part started."""

from __future__ import annotations

import math
from collections.abc import Sequence as Seq
from dataclasses import dataclass

from oms.economics.stage import StageResult, evaluate_stage
from oms.model.means import MeanSettings
from oms.model.sequence import Sequence


@dataclass(frozen=True)
class ProfitBreakdown:
    """A Sequence evaluated at given Mean Settings. Every money amount is per part started.

    A Stage's Processing, Scrap and Rework Costs are weighted by its reach probability r_i, the chance a
    part gets that far. Inspection Cost is a flat charge per part started, not weighted by r_i, so
    re-inspection after rework is free (spec §2.2, thesis Table 3.9).
    """

    stages: tuple[StageResult, ...]  # each per part entering its Stage
    reach_probabilities: tuple[float, ...]  # r_i = Π_{l<i} f_{C,l}
    final_conformance: float  # Π_i f_{C,i}
    revenue: float  # SP · Π_i f_{C,i}
    processing_costs: tuple[float, ...]  # PC_i · r_i
    scrap_costs: tuple[float, ...]  # Sr_i · r_i
    rework_costs: tuple[float, ...]  # Rw_i · r_i
    inspection_costs: tuple[float, ...]  # In_i, flat

    @property
    def production_cost(self) -> float:
        """Processing + Scrap + Rework Cost over the whole Sequence (U2)."""
        return sum(self.processing_costs) + sum(self.scrap_costs) + sum(self.rework_costs)

    @property
    def expected_profit(self) -> float:
        """E(PR) = SP · Π_i f_{C,i} − Σ_i (PC_i + Sr_i + Rw_i) · r_i (thesis Eq 3.78)."""
        return self.revenue - self.production_cost

    @property
    def inspection_cost(self) -> float:
        """I = Σ_i In_i."""
        return sum(self.inspection_costs)

    @property
    def expected_profit_after_inspection(self) -> float:
        """E(PR) − I. The optimal means are the same as for E(PR), since I doesn't depend on them."""
        return self.expected_profit - self.inspection_cost


def evaluate_sequence(sequence: Sequence, means: Seq[MeanSettings], *, rng_seed: int = 0) -> ProfitBreakdown:
    """Evaluate each Stage at its Mean Settings and combine them in series. `rng_seed` is passed to every Stage."""
    if len(means) != len(sequence.stages):
        raise ValueError(f"need one Mean Setting per Stage: {len(sequence.stages)} Stages, {len(means)} given")
    results = tuple(evaluate_stage(stage, m, rng_seed=rng_seed) for stage, m in zip(sequence.stages, means))
    reach = tuple(math.prod(r.final_conformance for r in results[:i]) for i in range(len(results)))
    final_conformance = math.prod(r.final_conformance for r in results)
    return ProfitBreakdown(
        stages=results,
        reach_probabilities=reach,
        final_conformance=final_conformance,
        revenue=sequence.selling_price * final_conformance,
        processing_costs=tuple(r.processing_cost * p for r, p in zip(results, reach)),
        scrap_costs=tuple(r.expected_scrap_cost * p for r, p in zip(results, reach)),
        rework_costs=tuple(r.expected_rework_cost * p for r, p in zip(results, reach)),
        inspection_costs=tuple(stage.inspection_cost for stage in sequence.stages),
    )
