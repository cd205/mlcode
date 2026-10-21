"""Stage economics (spec §2.1, §5.3): Final Conformance Probability and expected costs per part started."""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import dataclass
from types import MappingProxyType

from oms.distributions.base import Method
from oms.markov.chain import StateTransitions, expected_visits, stage_transitions
from oms.markov.states import INITIAL_STATE, State
from oms.model.means import MeanSettings
from oms.model.stage import Stage


@dataclass(frozen=True)
class StageResult:
    """One Stage evaluated at given Mean Settings, per part entering the Stage.

    Processing, Scrap and Rework Costs are reported separately because the thesis's "production cost"
    sometimes includes Processing Cost and sometimes doesn't (D12).
    """

    states: tuple[State, ...]
    transitions: Mapping[State, StateTransitions]
    visits: Mapping[State, float]  # m_{I,j}
    final_conformance: float  # f_C = Σ_j m_{I,j} p_{j,C}
    scrap_probability: float  # Σ_j m_{I,j} p_{j,X}
    processing_cost: float
    expected_scrap_cost: float  # Σ_j m_{I,j} p_{j,X} SC_j (ADR 0001)
    expected_rework_cost: float  # Σ_{S≠I} m_{I,S} RC_S
    methods: frozenset[Method]
    abs_error: float  # summed bound over every box probability used

    def __post_init__(self) -> None:
        object.__setattr__(self, "transitions", MappingProxyType(dict(self.transitions)))
        object.__setattr__(self, "visits", MappingProxyType(dict(self.visits)))

    @property
    def production_cost(self) -> float:
        """Processing + Scrap + Rework Cost per part started (U2)."""
        return self.processing_cost + self.expected_scrap_cost + self.expected_rework_cost

    def expected_profit(self, selling_price: float) -> float:
        """Single-Stage Expected Profit: SP·f_C − (PC + Sr + Rw) (thesis Eq 3.44)."""
        return selling_price * self.final_conformance - self.production_cost


def evaluate_stage(stage: Stage, means: MeanSettings, *, rng_seed: int = 0) -> StageResult:
    """Evaluate one Stage at the given Mean Settings. `rng_seed` seeds the Monte Carlo boxes of 4+ Features."""
    means.check_against(stage)
    transitions = stage_transitions(stage, means, rng_seed=rng_seed)
    visits = expected_visits(stage.states, transitions)
    costs = stage.costs
    return StageResult(
        states=stage.states,
        transitions=transitions,
        visits=visits,
        final_conformance=sum(m * transitions[s].conform for s, m in visits.items()),
        scrap_probability=sum(m * transitions[s].scrap for s, m in visits.items()),
        processing_cost=costs.processing,
        expected_scrap_cost=sum(m * transitions[s].scrap * costs.scrap[s] for s, m in visits.items()),
        expected_rework_cost=sum(m * costs.rework[s] for s, m in visits.items() if s != INITIAL_STATE),
        methods=frozenset().union(*(t.methods for t in transitions.values())),
        abs_error=sum(t.abs_error for t in transitions.values()),
    )
