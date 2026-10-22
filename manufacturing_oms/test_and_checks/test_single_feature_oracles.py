"""The engine against faithful ports of the one-Feature MATLAB (ADR 0002, issue #3).

The MATLAB hard-codes the Rework Side above U, so each oracle is called with UPPER-side inputs
(L, U, μ). The engine is evaluated on that Feature and on its reflection (−U, −L, −μ) with the
Rework Side below L, so the LOWER side is checked against the same legacy values (D14).
"""

import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage, evaluate_stage
from oracles import fun_cmc_markov, markov_process_1_var, probs_1var

I = frozenset()
X = frozenset({"x"})
TOL = 1e-10
SIDES = [ReworkSide.UPPER, ReworkSide.LOWER]


def evaluate_engine(lower, upper, mean, side, sigma, pc=0.0, rc=0.0, sc=0.0):
    """Evaluate the UPPER-side Feature (lower, upper, mean) as given, or reflected onto the LOWER side."""
    if side is ReworkSide.LOWER:
        lower, upper, mean = -upper, -lower, -mean
    stage = Stage(
        features=(Feature("x", lower=lower, upper=upper, rework_side=side),),
        variation=MultivariateNormal([sigma]),
        costs=CostTable(processing=pc, rework={X: rc}, scrap={I: sc, X: sc}),
    )
    return evaluate_stage(stage, MeanSettings.per_feature(stage, {"x": mean}))


class TestProbs1Var:
    """`Probs_1Var`: transition probabilities from the Initial State and the Rework State."""

    LOWER, UPPER, SIGMA = 3.0, 7.0, 1.7

    def test_port_reproduces_the_hand_computed_values(self):
        # μ at the centre of [3, 7], σ = 2: the rework and scrap tails are both 1 − Φ(1).
        tail = 0.15865525393145707
        pis, pcs, pss, prr, pts = probs_1var(None, [7.0], [3.0], [5.0], [[4.0]])
        assert pis == pytest.approx([tail, 1 - 2 * tail, tail], abs=1e-15)
        assert pcs == [pis[1], pis[1]]
        assert pss == [pis[2], pis[2]]
        assert prr == [pis[0]]
        assert pts == [[pis[0]]]

    @pytest.mark.parametrize("side", SIDES)
    @pytest.mark.parametrize("mean", [3.5, 5.0, 6.2, 7.0, 8.0])
    def test_engine_matches_transition_probabilities(self, side, mean):
        result = evaluate_engine(self.LOWER, self.UPPER, mean, side, self.SIGMA)
        (p_i_rework, p_i_conform, p_i_scrap), pcs, pss, prr, _ = probs_1var(
            None, [self.UPPER], [self.LOWER], [mean], [[self.SIGMA**2]]
        )

        initial, rework = result.transitions[I], result.transitions[X]
        assert initial.rework[X] == pytest.approx(p_i_rework, abs=TOL)
        assert initial.conform == pytest.approx(p_i_conform, abs=TOL)
        assert initial.scrap == pytest.approx(p_i_scrap, abs=TOL)
        assert rework.conform == pytest.approx(pcs[1], abs=TOL)
        assert rework.scrap == pytest.approx(pss[1], abs=TOL)
        assert rework.rework[X] == pytest.approx(prr[0], abs=TOL)


class TestMarkovProcess1Var:
    """`MarkovProcess_1_Var`: Bowling 2004's conventional chain and the thesis's series chain."""

    SP, PC, RC, SC = 120.0, 45.0, 3.0, 3.0  # the script's hard-coded costs
    LOWER, UPPER, SIGMA = 3.0, 7.0, 1.7

    def test_port_reproduces_the_hand_computed_values(self):
        # μ at the centre of [3, 7], σ = 2: p_R = p_S = t = 1 − Φ(1), so f_C = (1 − 2t) / (1 − t).
        t = 0.15865525393145707
        out = markov_process_1_var(cut=5.0, sig11=2.0)
        assert out.fIC == pytest.approx((1 - 2 * t) / (1 - t), abs=1e-15)
        assert out.mI2 == pytest.approx(t / (1 - t), abs=1e-15)
        expected_profit = self.SP * out.fIC - self.PC - self.SC * t / (1 - t) - self.RC * out.mI2
        assert out.EPR_series == pytest.approx(expected_profit, abs=1e-12)

    def test_both_legacy_chains_give_the_same_expected_profit(self):
        out = markov_process_1_var()
        assert out.EPR_conventional == pytest.approx(out.EPR_series, abs=1e-12)

    @pytest.mark.parametrize("side", SIDES)
    @pytest.mark.parametrize("mean", [3.5, 4.5, 5.5, 7.0, 8.0])
    def test_engine_matches_visits_conformance_and_profit(self, side, mean):
        result = evaluate_engine(
            self.LOWER, self.UPPER, mean, side, self.SIGMA, pc=self.PC, rc=self.RC, sc=self.SC
        )
        out = markov_process_1_var(
            SP=self.SP, PC1=self.PC, RC1=self.RC, SC1=self.SC,
            cut=mean, sig11=self.SIGMA, LSLx1=self.LOWER, USLx1=self.UPPER,
        )

        assert result.visits[I] == pytest.approx(1.0, abs=TOL)
        assert result.visits[X] == pytest.approx(out.mI2, abs=TOL)
        assert sum(result.visits.values()) == pytest.approx(out.m11, abs=TOL)  # D13: merged chain
        assert result.final_conformance == pytest.approx(out.fIC, abs=TOL)
        assert result.final_conformance == pytest.approx(out.f12, abs=TOL)
        assert result.scrap_probability == pytest.approx(out.fIS, abs=TOL)
        assert result.expected_profit(self.SP) == pytest.approx(out.EPR_series, abs=TOL)
        assert result.expected_profit(self.SP) == pytest.approx(out.EPR_conventional, abs=TOL)


class TestFunCMCMarkov:
    """`Fun_CMC_Markov`: the production-code profit function, its limits and costs hard-coded."""

    SP, PC, SC, RC = 21.0, 7.0, 15.0, 7.0
    LOWER, UPPER, SIGMA = 2.0, 8.0, 1.0

    def test_port_reproduces_the_hand_computed_values(self):
        # μ at the centre of [2, 8], σ = 1: p_R = p_S = t = 1 − Φ(3).
        t = 0.0013498980316301035
        out = fun_cmc_markov(5.0)
        assert out.TOT_Confm == pytest.approx((1 - 2 * t) / (1 - t), abs=1e-15)
        assert out.TOT_Rwork == pytest.approx(t / (1 - t), abs=1e-12)
        expected_profit = self.SP * out.TOT_Confm - self.PC - (self.SC + self.RC) * t / (1 - t)
        assert out.Profit == pytest.approx(expected_profit, abs=1e-12)

    @pytest.mark.parametrize("side", SIDES)
    @pytest.mark.parametrize("mean", [3.0, 4.0, 5.0, 6.5, 7.2, 8.5])
    def test_engine_matches_visits_conformance_and_profit(self, side, mean):
        result = evaluate_engine(
            self.LOWER, self.UPPER, mean, side, self.SIGMA, pc=self.PC, rc=self.RC, sc=self.SC
        )
        out = fun_cmc_markov(mean)

        assert result.visits[X] == pytest.approx(out.TOT_Rwork, abs=TOL)
        assert result.final_conformance == pytest.approx(out.TOT_Confm, abs=TOL)
        assert result.scrap_probability == pytest.approx(out.TOT_Scrap, abs=TOL)
        assert result.production_cost == pytest.approx(out.ProdCost, abs=TOL)
        assert result.expected_profit(self.SP) == pytest.approx(out.Profit, abs=TOL)
