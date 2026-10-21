"""The engine against the thesis Eq 3.59 scrap formula and the Khasawneh & Bowling 2008 formula (ADR 0002, issue #5)."""

import warnings
from itertools import combinations

import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage, evaluate_stage
from oracles import k_and_b_2008_example, kandb_markov_dual_chars, stage_cost_fun

I = frozenset()
X1 = frozenset({"x1"})
X2 = frozenset({"x2"})
X12 = frozenset({"x1", "x2"})
TOL = 1e-10


def evaluate_engine(MU, sigs, rho, U, L, R_Cost, S_Cost):
    """The engine on `StageCostFun`'s inputs: Features x1..xN, Rework Side above U, costs in Υ order."""
    names = [f"x{i + 1}" for i in range(len(MU))]
    upsilon = [frozenset(g) for k in range(1, len(names) + 1) for g in combinations(names, k)]
    stage = Stage(
        features=tuple(Feature(n, lower=lo, upper=hi, rework_side=ReworkSide.UPPER) for n, lo, hi in zip(names, L, U)),
        variation=MultivariateNormal(sigs, rho),
        costs=CostTable(
            processing=0.0, rework=dict(zip(upsilon, R_Cost)), scrap=dict(zip([I, *upsilon], S_Cost))
        ),
    )
    return evaluate_stage(stage, MeanSettings.per_feature(stage, dict(zip(names, MU))))


def unit_costs(n):
    """Rework and Scrap Cost 1 in every state: the Scrap Cost is the scrap probability, the Rework Cost Σ m."""
    return [1.0] * (2**n - 1), [1.0] * 2**n


class TestEq359:
    """`StageCostFun`'s S∘D feed-in scrap (thesis Eq 3.59) against the exact Σ m_{I,j} p_{j,S} SC_j (ADR 0001, D1)."""

    @pytest.mark.parametrize(
        "MU, sigs, rho, L, U, costs",
        [
            pytest.param([5.0], [1.0], 0.0, [3.0], [7.0], ([3.0], [2.0, 5.0]), id="N=1 centred"),
            pytest.param([7.4], [1.7], 0.0, [3.0], [7.0], ([3.0], [2.0, 5.0]), id="N=1 past U"),
            pytest.param([10.5115, 15.5651], [1.0, 1.0], 0.0, [8, 13], [12, 17], unit_costs(2), id="N=2 Table 3.1"),
            pytest.param(
                [10.5115, 15.5651], [1.0, 1.0], 0.0, [8, 13], [12, 17], ([15, 12, 20], [8, 9, 11, 14]), id="N=2 R3"
            ),
            pytest.param(
                [10.9, 14.2], [1.0, 1.5], 0.0, [8, 13], [12, 17], ([15, 12, 20], [8, 9, 11, 14]), id="N=2 off-centre"
            ),
        ],
    )
    def test_equals_the_engine_for_up_to_two_features(self, MU, sigs, rho, L, U, costs):
        R_Cost, S_Cost = costs
        F_stageC, pIC, Rwi, Sri = stage_cost_fun(MU, sigs, rho, U, L, R_Cost, S_Cost)
        result = evaluate_engine(MU, sigs, rho, U, L, R_Cost, S_Cost)

        assert Sri == pytest.approx(result.expected_scrap_cost, abs=1e-12)
        assert Rwi == pytest.approx(result.expected_rework_cost, abs=1e-12)
        assert F_stageC == pytest.approx(result.final_conformance, abs=1e-12)
        assert pIC == pytest.approx(1 - result.transitions[I].scrap, abs=1e-12)

    def test_equals_the_engine_for_two_correlated_features(self):
        MU, sigs, rho, L, U = [10.6, 15.4], [1.0, 1.25], 0.6, [8, 13], [12, 17]
        R_Cost, S_Cost = [15, 12, 20], [8, 9, 11, 14]
        _, _, Rwi, Sri = stage_cost_fun(MU, sigs, rho, U, L, R_Cost, S_Cost)
        result = evaluate_engine(MU, sigs, rho, U, L, R_Cost, S_Cost)
        assert Sri == pytest.approx(result.expected_scrap_cost, abs=1e-9)
        assert Rwi == pytest.approx(result.expected_rework_cost, abs=1e-9)

    def test_reproduces_adr_0001_at_two_features(self):
        # ADR 0001's "Table 3.1 means" are the R3-oracle's, hard-coded in `K_and_B_2008_Example`.
        _, _, _, Sri = stage_cost_fun([10.55137, 15.60796], [1, 1], 0.0, [12, 17], [8, 13], *unit_costs(2))
        assert round(Sri, 7) == 0.0107240

    @pytest.mark.parametrize(
        "MU, sigs, L, U, exact, gap",
        [
            pytest.param([6, 5.5, 5], [2, 2.5, 3], [3] * 3, [7] * 3, 0.53254, -4.4e-3, id="N=3"),
            pytest.param(
                [10.560, 15.613, 12.708, 9.656], [1] * 4, [8, 13, 10, 7], [12, 17, 14, 11], 0.0185160, -4.9e-6,
                id="N=4 Table 3.8",
            ),
        ],
    )
    def test_underestimates_for_three_or_more_features(self, MU, sigs, L, U, exact, gap, record_property):
        R_Cost, S_Cost = unit_costs(len(MU))
        F_stageC, _, Rwi, Sri = stage_cost_fun(MU, sigs, 0.0, U, L, R_Cost, S_Cost)
        result = evaluate_engine(MU, sigs, 0.0, U, L, R_Cost, S_Cost)

        difference = Sri - result.expected_scrap_cost
        record_property("eq_3_59_minus_exact", difference)
        warnings.warn(f"D1: Eq 3.59 minus exact Scrap Cost, N={len(MU)}: {difference:.6e}", stacklevel=1)
        assert difference < 0
        assert float(f"{result.expected_scrap_cost:.6g}") == pytest.approx(exact, rel=1e-5)
        assert float(f"{difference:.2g}") == gap
        # Only the scrap term departs: f_C and the Rework Cost come from the same fundamental matrix.
        assert F_stageC == pytest.approx(result.final_conformance, abs=1e-12)
        assert Rwi == pytest.approx(result.expected_rework_cost, abs=1e-12)


class TestKhasawnehBowling2008:
    """R3-oracle: `K_and_B_2008_Example` with `KandBMarkov_DualChars`, the Table 3.1 literature formula (D7)."""

    SIGMA = [[1.0, 0.0], [0.0, 1.0]]
    LX, LY, UX, UY = 8.0, 13.0, 12.0, 17.0

    def test_expected_profit_at_the_printed_means(self):
        assert round(k_and_b_2008_example(MU=[10.5514, 15.6080]).EP, 4) == 71.1592

    def test_expected_profit_at_the_scripts_means(self):
        assert round(k_and_b_2008_example().EP, 4) == 71.1592

    @pytest.mark.parametrize("mu", [(10.55137, 15.60796), (10.0, 15.0), (11.2, 14.1), (9.0, 16.5)])
    def test_engine_matches_transitions_visits_and_conformance(self, mu):
        result = evaluate_engine(list(mu), [1.0, 1.0], 0.0, [self.UX, self.UY], [self.LX, self.LY], *unit_costs(2))
        out = kandb_markov_dual_chars(list(mu), self.SIGMA, self.LX, self.LY, self.UX, self.UY)

        initial = result.transitions[I]
        assert initial.rework[X1] == pytest.approx(out.p12, abs=TOL)
        assert initial.rework[X2] == pytest.approx(out.p13, abs=TOL)
        assert initial.rework[X12] == pytest.approx(out.p14, abs=TOL)
        assert initial.conform == pytest.approx(out.p15, abs=TOL)
        assert initial.scrap == pytest.approx(out.p16, abs=TOL)
        assert result.transitions[X1].rework[X1] == pytest.approx(out.p22, abs=TOL)
        assert result.transitions[X1].conform == pytest.approx(out.p25, abs=TOL)
        assert result.transitions[X1].scrap == pytest.approx(out.p26, abs=TOL)
        assert result.transitions[X2].rework[X2] == pytest.approx(out.p33, abs=TOL)
        assert result.transitions[X2].conform == pytest.approx(out.p35, abs=TOL)
        assert result.transitions[X2].scrap == pytest.approx(out.p36, abs=TOL)
        assert result.visits[X1] == pytest.approx(out.m12, abs=TOL)
        assert result.visits[X2] == pytest.approx(out.m13, abs=TOL)
        assert result.visits[X12] == pytest.approx(out.m14, abs=TOL)
        assert result.final_conformance == pytest.approx(out.f15, abs=TOL)
        assert result.scrap_probability == pytest.approx(out.f16, abs=TOL)
