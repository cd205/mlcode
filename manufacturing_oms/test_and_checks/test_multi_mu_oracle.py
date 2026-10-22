"""The engine's per_group_size Mean Settings against `StageCostFun_MultiMu` / `Probs_nVars_MultiMu` (ADR 0002, D8)."""

import warnings
from itertools import combinations

import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage, evaluate_stage
from oracles import per_group_size_from_mu_rows, stage_cost_fun_multi_mu

I = frozenset()


def evaluate_engine(MU, sigs, rho, U, L, R_Cost, S_Cost):
    """The engine on `StageCostFun_MultiMu`'s inputs: Features x1..xN, Rework Side above U, costs in Υ order."""
    names = [f"x{i + 1}" for i in range(len(L))]
    upsilon = [frozenset(g) for k in range(1, len(names) + 1) for g in combinations(names, k)]
    stage = Stage(
        features=tuple(Feature(n, lower=lo, upper=hi, rework_side=ReworkSide.UPPER) for n, lo, hi in zip(names, L, U)),
        variation=MultivariateNormal(sigs, rho),
        costs=CostTable(
            processing=0.0, rework=dict(zip(upsilon, R_Cost)), scrap=dict(zip([I, *upsilon], S_Cost))
        ),
    )
    return evaluate_stage(stage, MeanSettings.per_group_size(stage, per_group_size_from_mu_rows(MU, names)))


R6_COSTS = ([25.0, 25.0, 50.0], [150.0] * 4)


class TestTwoFeatures:
    """Eq 3.59 is exact for N ≤ 2 (ADR 0001), so every output equals the engine."""

    @pytest.mark.parametrize(
        "MU, sigs, rho, tol",
        [
            pytest.param([[6.748, 6.748], [7.022, 7.022]], [2.0, 2.0], 0.0, 1e-12, id="R6 optimum"),
            pytest.param([[6.6, 6.9], [7.1, 6.8]], [2.0, 1.5], 0.0, 1e-12, id="asymmetric"),
            pytest.param([[6.52, 6.52], [7.02, 7.02]], [2.0, 2.0], 0.8, 1e-9, id="R7 rho=0.8"),
            pytest.param([[6.57, 6.57], [7.02, 7.02]], [2.0, 2.0], -0.8, 1e-9, id="R7 rho=-0.8"),
        ],
    )
    def test_equals_the_engine(self, MU, sigs, rho, tol):
        L, U = [4.0, 4.0], [6.0, 6.0]
        F_stageC, pIC, Rwi, Sri = stage_cost_fun_multi_mu(MU, sigs, rho, U, L, *R6_COSTS)
        result = evaluate_engine(MU, sigs, rho, U, L, *R6_COSTS)

        assert F_stageC == pytest.approx(result.final_conformance, abs=tol)
        assert Rwi == pytest.approx(result.expected_rework_cost, abs=tol)
        assert Sri == pytest.approx(result.expected_scrap_cost, abs=tol)
        assert pIC == pytest.approx(1 - result.transitions[I].scrap, abs=tol)

    def test_reproduces_table_3_11_at_the_printed_means(self):
        # E(PR) = 400 f_C − 50 − Sr − Rw (D11). f_C and Sr + Rw move in their last printed digit across the
        # rounding of the means, so they are checked at the optimum (`test_optimise_tying_schemes.py`).
        MU = [[6.75, 6.75], [7.02, 7.02]]
        F_stageC, _, Rwi, Sri = stage_cost_fun_multi_mu(MU, [2, 2], 0.0, [6, 6], [4, 4], *R6_COSTS)
        assert round(400 * F_stageC - 50 - Sri - Rwi, 2) == 41.66


def test_three_features_map_each_mu_row_to_its_group_size(record_property):
    """Distinct rows for 3-, 1- and 2-Feature groups: f_C and the Rework Cost only agree if D8's row order is undone."""
    MU = [[6.0, 5.5, 5.0], [6.4, 5.9, 5.3], [6.2, 5.2, 5.6]]  # [N-Feature; 1-Feature; 2-Feature]
    sigs, L, U = [2.0, 2.5, 3.0], [3.0] * 3, [7.0] * 3
    R_Cost, S_Cost = [3, 4, 5, 6, 7, 8, 9], [2, 3, 4, 5, 6, 7, 8, 9]
    F_stageC, _, Rwi, Sri = stage_cost_fun_multi_mu(MU, sigs, 0.0, U, L, R_Cost, S_Cost)
    result = evaluate_engine(MU, sigs, 0.0, U, L, R_Cost, S_Cost)

    assert F_stageC == pytest.approx(result.final_conformance, abs=1e-12)
    assert Rwi == pytest.approx(result.expected_rework_cost, abs=1e-12)
    # Only the Eq 3.59 scrap term departs for N = 3 (ADR 0001, D1).
    difference = Sri - result.expected_scrap_cost
    record_property("eq_3_59_minus_exact", difference)
    warnings.warn(f"D1: Eq 3.59 minus exact Scrap Cost, N=3 per_group_size: {difference:.6e}", stacklevel=1)
    assert difference < 0


def test_adapter_reads_the_first_row_as_the_initial_states_group_size():
    assert per_group_size_from_mu_rows([[1, 2, 3], [4, 5, 6], [7, 8, 9]], ["a", "b", "c"]) == {
        3: {"a": 1.0, "b": 2.0, "c": 3.0},
        1: {"a": 4.0, "b": 5.0, "c": 6.0},
        2: {"a": 7.0, "b": 8.0, "c": 9.0},
    }
