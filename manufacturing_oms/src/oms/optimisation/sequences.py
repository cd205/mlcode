"""Sequence search over Inspection positions (spec §5.4, thesis Tables 3.8–3.9, Fig 3.27)."""

from __future__ import annotations

from collections.abc import Callable, Iterator
from collections.abc import Sequence as Seq
from dataclasses import dataclass
from itertools import combinations
from typing import Any

from oms.model.feature import Feature
from oms.model.sequence import Sequence
from oms.model.stage import Stage
from oms.optimisation.means import OptimisationResult, optimise_means
from oms.optimisation.tying import Scheme

# Called as stage_builder(features, upstream): the Stage making `features`, given the Features made in the
# Stages before it, so that cumulative Scrap Costs (A6) can include their value.
StageBuilder = Callable[[tuple[Feature, ...], tuple[Feature, ...]], Stage]


@dataclass(frozen=True)
class SequenceResult:
    """One Inspection placement of the ordered Features, with its optimised Mean Settings and its ranks."""

    sequence: Sequence
    optimisation: OptimisationResult
    rank: int  # 1 for the highest E(PR)
    rank_after_inspection: int  # 1 for the highest E(PR) − I

    @property
    def stage_features(self) -> tuple[tuple[str, ...], ...]:
        """The Feature names of each Stage, in order."""
        return tuple(stage.feature_names for stage in self.sequence.stages)

    @property
    def expected_profit(self) -> float:
        return self.optimisation.breakdown.expected_profit

    @property
    def inspection_cost(self) -> float:
        return self.optimisation.breakdown.inspection_cost

    @property
    def expected_profit_after_inspection(self) -> float:
        return self.optimisation.breakdown.expected_profit_after_inspection


def search_sequences(
    features_in_order: Seq[Feature],
    stage_builder: StageBuilder,
    selling_price: float,
    scheme: Scheme = "per_feature",
    **opt_kwargs: Any,
) -> list[SequenceResult]:
    """Optimise every Sequence of the Features, kept in manufacturing order, over all 2^(N−1) Inspection placements.

    Each Sequence's Mean Settings are optimised by `optimise_means(sequence, scheme, **opt_kwargs)`. The
    results are ranked by E(PR) at those Mean Settings, best first, and each also carries its rank by
    E(PR) − Inspection Cost. Ties keep the enumeration order: Serial first, then fewer Inspections.
    """
    features = tuple(features_in_order)
    if not features:
        raise ValueError("search_sequences needs at least one Feature")
    sequences = []
    for groups in _groupings(features):
        stages = []
        for i, group in enumerate(groups):
            stage = stage_builder(group, tuple(f for g in groups[:i] for f in g))
            if stage.features != group:
                raise ValueError(f"stage_builder must return a Stage of exactly {[f.name for f in group]}, "
                                 f"got {list(stage.feature_names)}")
            stages.append(stage)
        sequences.append(Sequence(stages=tuple(stages), selling_price=selling_price))
    optimisations = [optimise_means(sequence, scheme, **opt_kwargs) for sequence in sequences]

    def ranks(key: Callable[[OptimisationResult], float]) -> list[int]:
        order = sorted(range(len(optimisations)), key=lambda j: -key(optimisations[j]))
        return [order.index(j) + 1 for j in range(len(optimisations))]

    by_profit = ranks(lambda o: o.breakdown.expected_profit)
    after_inspection = ranks(lambda o: o.breakdown.expected_profit_after_inspection)
    results = [
        SequenceResult(sequence, optimisation, rank=by_profit[j], rank_after_inspection=after_inspection[j])
        for j, (sequence, optimisation) in enumerate(zip(sequences, optimisations))
    ]
    return sorted(results, key=lambda r: r.rank)


def _groupings(features: tuple[Feature, ...]) -> Iterator[tuple[tuple[Feature, ...], ...]]:
    """Every split of the ordered Features into consecutive Stages: an Inspection may follow any of the first N−1."""
    gaps = range(1, len(features))
    for n_cuts in range(len(features) - 1, -1, -1):
        for cuts in combinations(gaps, n_cuts):
            edges = (0, *cuts, len(features))
            yield tuple(features[a:b] for a, b in zip(edges, edges[1:]))
