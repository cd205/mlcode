"""The engine against faithful ports of the two- and three-Feature MATLAB chains (ADR 0002, issue #6).

The MATLAB hard-codes the Rework Side above U and reuses the Initial State's means for every Rework
State, so the engine is evaluated with `per_feature` Mean Settings and UPPER-side Features. SIGMA is a
covariance matrix; the engine gets its standard deviations and correlation matrix.
"""

import warnings
from itertools import combinations

import numpy as np
import pytest

from oms import (
    CostTable,
    Feature,
    MeanSettings,
    MultivariateNormal,
    ReworkSide,
    Sequence,
    Stage,
    evaluate_sequence,
    evaluate_stage,
)
from oracles import markov_process_2_var, markov_tri_chars, probs_2var, probs_3var, s_matrix_cell, stage_cost_fun, stage_cost_fun_old

I = frozenset()
TOL = 1e-10
NUMERICAL_TOL = 1e-8  # correlated 2-3D boxes: numerical on both sides (oracles/mvncdf.py, ADR 0003)


def names(n):
    return [f"x{i + 1}" for i in range(n)]


def upsilon(n):
    """The Rework States in Υ order: by size, then lexicographically (spec §2.1)."""
    return [frozenset(g) for k in range(1, n + 1) for g in combinations(names(n), k)]


def evaluate_engine(MU, SIGMA, U, L, R_Cost=None, S_Cost=None):
    """The engine on the MATLAB's inputs: Features x1..xN, Rework Side above U, costs in Υ order."""
    n = len(MU)
    SIGMA = np.asarray(SIGMA, dtype=float)
    sigmas = np.sqrt(np.diag(SIGMA))
    corr = SIGMA / np.outer(sigmas, sigmas)
    np.fill_diagonal(corr, 1.0)  # σ² / (σ·σ) can miss 1 by rounding
    R_Cost = [0.0] * (2**n - 1) if R_Cost is None else R_Cost
    S_Cost = [0.0] * 2**n if S_Cost is None else S_Cost
    stage = Stage(
        features=tuple(
            Feature(x, lower=lo, upper=hi, rework_side=ReworkSide.UPPER) for x, lo, hi in zip(names(n), L, U)
        ),
        variation=MultivariateNormal(sigmas, corr),
        costs=CostTable(processing=0.0, rework=dict(zip(upsilon(n), R_Cost)), scrap=dict(zip([I, *upsilon(n)], S_Cost))),
    )
    return evaluate_stage(stage, MeanSettings.per_feature(stage, dict(zip(names(n), MU))))


def engine_rows(result, n):
    """[Q R] in the MATLAB's state order: rows I, Υ; columns I, Υ, Conforming, Scrapped."""
    states = [I, *upsilon(n)]
    rows = []
    for s in states:
        t = result.transitions[s]
        rows.append([t.rework.get(j, 0.0) for j in states] + [t.conform, t.scrap])
    return np.array(rows)


class TestProbs2Var:
    """`Probs_2Var`: the two-Feature transition probabilities, PIs/PCs/PSs/PRR and the S-matrix fill."""

    U, L = [12.0, 17.0], [8.0, 13.0]

    def test_port_reproduces_the_hand_computed_values(self):
        # Both means centred, σ = 2: every tail is t = 1 − Φ(1) and the Features are independent.
        t = 0.15865525393145707
        PIs, PCs, PSs, PRR, ptsCell = probs_2var(s_matrix_cell(2), self.U, self.L, [10.0, 15.0], np.diag([4.0, 4.0]))
        c = 1 - 2 * t
        assert PIs == pytest.approx([t * c, c * t, t * t, c * c, 1 - (1 - t) ** 2], abs=1e-15)
        assert PCs == pytest.approx([c * c, c, c, c * c], abs=1e-15)
        assert PSs == pytest.approx([1 - (1 - t) ** 2, t, t, 1 - (1 - t) ** 2], abs=1e-15)
        assert PRR == pytest.approx([t, t, t * t], abs=1e-15)
        assert ptsCell[0] == pytest.approx(np.array([[t, 0], [0, t], [t * c, c * t]]), abs=1e-15)
        assert ptsCell[1] == pytest.approx(np.array([[t * t]]), abs=1e-15)

    @pytest.mark.parametrize("MU", [(10.0, 15.0), (10.5115, 15.5651), (11.4, 14.2), (8.6, 17.3)])
    @pytest.mark.parametrize(
        "SIGMA, tol",
        [
            pytest.param([[1.0, 0.0], [0.0, 1.0]], TOL, id="independent"),
            pytest.param([[1.0, 0.0], [0.0, 2.25]], TOL, id="unequal sigma"),
            pytest.param([[1.0, 0.75], [0.75, 1.5625]], NUMERICAL_TOL, id="rho=0.6"),
            pytest.param([[2.25, -1.2], [-1.2, 1.0]], NUMERICAL_TOL, id="rho=-0.8"),
        ],
    )
    def test_engine_matches_transition_probabilities(self, MU, SIGMA, tol):
        PIs, PCs, PSs, PRR, ptsCell = probs_2var(s_matrix_cell(2), self.U, self.L, list(MU), SIGMA)
        rows = engine_rows(evaluate_engine(list(MU), SIGMA, self.U, self.L), 2)

        assert rows[0, 1:] == pytest.approx(PIs, abs=tol)  # I → {1}, {2}, {1,2}, C, X
        assert rows[:, 4] == pytest.approx(PCs, abs=tol)
        assert rows[:, 5] == pytest.approx(PSs, abs=tol)
        assert np.diag(rows[1:, 1:4]) == pytest.approx(PRR, abs=tol)
        assert rows[1:, 1:3] == pytest.approx(ptsCell[0], abs=tol)
        assert rows[3:, 3:4] == pytest.approx(ptsCell[1], abs=tol)


class TestProbs3Var:
    """`Probs_3Var`: the three-Feature transition probabilities. Its pair Rework States drop the correlation (D15)."""

    U, L = [6.2, 7.1, 8.4], [2.1, 3.5, 2.7]  # the MATLAB's example limits
    INDEPENDENT = np.diag([2.0, 2.5, 3.0])  # the MATLAB's example SIGMA
    CORRELATED = np.array([[2.0, 0.9, -0.6], [0.9, 2.5, 0.8], [-0.6, 0.8, 3.0]])

    def test_port_reproduces_the_hand_computed_values(self):
        # Every mean centred, σ = 2, limits ±2: every tail is t = 1 − Φ(1) and the Features are independent.
        t = 0.15865525393145707
        c = 1 - 2 * t
        PIs, PCs, PSs, PRR, ptsCell = probs_3var(
            s_matrix_cell(3), [7.0] * 3, [3.0] * 3, [5.0] * 3, np.diag([4.0] * 3)
        )
        scrap3, scrap2 = 1 - (1 - t) ** 3, 1 - (1 - t) ** 2
        assert PIs == pytest.approx([t * c * c] * 3 + [t * t * c] * 3 + [t**3, c**3, scrap3], abs=1e-15)
        assert PCs == pytest.approx([c**3, c, c, c, c * c, c * c, c * c, c**3], abs=1e-15)
        assert PSs == pytest.approx([scrap3, t, t, t, scrap2, scrap2, scrap2, scrap3], abs=1e-15)
        assert PRR == pytest.approx([t, t, t, t * t, t * t, t * t, t**3], abs=1e-15)
        assert ptsCell[0][3] == pytest.approx([t * c, c * t, 0], abs=1e-15)  # {1,2} → {1}, {2}
        assert ptsCell[2] == pytest.approx(np.array([[t**3]]), abs=1e-15)

    @pytest.mark.parametrize("MU", [(6.0, 5.5, 5.0), (4.15, 5.3, 5.55), (5.2, 6.4, 3.4)])
    def test_engine_matches_independent_transition_probabilities(self, MU):
        PIs, PCs, PSs, PRR, ptsCell = probs_3var(s_matrix_cell(3), self.U, self.L, list(MU), self.INDEPENDENT)
        rows = engine_rows(evaluate_engine(list(MU), self.INDEPENDENT, self.U, self.L), 3)

        assert rows[0, 1:] == pytest.approx(PIs, abs=TOL)
        assert rows[:, 8] == pytest.approx(PCs, abs=TOL)
        assert rows[:, 9] == pytest.approx(PSs, abs=TOL)
        assert np.diag(rows[1:, 1:8]) == pytest.approx(PRR, abs=TOL)
        assert rows[1:, 1:4] == pytest.approx(ptsCell[0], abs=TOL)
        assert rows[4:, 4:7] == pytest.approx(ptsCell[1], abs=TOL)
        assert rows[7:, 7:8] == pytest.approx(ptsCell[2], abs=TOL)

    @pytest.mark.parametrize("MU", [(6.0, 5.5, 5.0), (4.15, 5.3, 5.55)])
    def test_pair_rework_states_ignore_the_correlation(self, MU):
        PIs, PCs, PSs, PRR, ptsCell = probs_3var(s_matrix_cell(3), self.U, self.L, list(MU), self.CORRELATED)
        rows = engine_rows(evaluate_engine(list(MU), self.CORRELATED, self.U, self.L), 3)
        diagonal = np.diag(np.diag(self.CORRELATED))
        uncorrelated = engine_rows(evaluate_engine(list(MU), diagonal, self.U, self.L), 3)

        # The Initial State, {1,2,3} and the one-Feature Rework States use the full SIGMA.
        assert rows[0, 1:] == pytest.approx(PIs, abs=NUMERICAL_TOL)
        assert np.diag(rows[1:4, 1:4]) == pytest.approx(PRR[:3], abs=NUMERICAL_TOL)
        assert rows[7, 1:7] == pytest.approx([*ptsCell[0][6], *ptsCell[1][3]], abs=NUMERICAL_TOL)
        assert rows[[0, 1, 2, 3, 7], 8] == pytest.approx(np.array(PCs)[[0, 1, 2, 3, 7]], abs=NUMERICAL_TOL)
        assert rows[[0, 1, 2, 3, 7], 9] == pytest.approx(np.array(PSs)[[0, 1, 2, 3, 7]], abs=NUMERICAL_TOL)
        assert rows[7:, 7:8] == pytest.approx(ptsCell[2], abs=NUMERICAL_TOL)
        # The pair Rework States {1,2}, {1,3}, {2,3} are drawn as if independent (D15).
        assert np.array(PCs)[4:7] == pytest.approx(uncorrelated[4:7, 8], abs=TOL)
        assert np.array(PSs)[4:7] == pytest.approx(uncorrelated[4:7, 9], abs=TOL)
        assert ptsCell[1][:3] == pytest.approx(uncorrelated[4:7, 4:7], abs=TOL)
        assert ptsCell[0][3:6] == pytest.approx(uncorrelated[4:7, 1:4], abs=TOL)
        assert np.abs(np.array(PCs)[4:7] - rows[4:7, 8]).min() > 1e-3

    @pytest.mark.parametrize("MU", [(6.0, 5.5, 5.0), (4.15, 5.3, 5.55)])
    def test_engine_pair_rework_states_match_probs_2var_on_the_correlated_marginal(self, MU):
        rows = engine_rows(evaluate_engine(list(MU), self.CORRELATED, self.U, self.L), 3)
        U, L, MU = (np.asarray(a) for a in (self.U, self.L, MU))

        for row, pair in zip([4, 5, 6], [[0, 1], [0, 2], [1, 2]]):
            PIs, _, _, _, _ = probs_2var(s_matrix_cell(2), U[pair], L[pair], MU[pair], self.CORRELATED[np.ix_(pair, pair)])
            first, second = (1 + i for i in pair)  # the one-Feature Rework States {i}, {j}
            engine = [rows[row, first], rows[row, second], rows[row, row], rows[row, 8], rows[row, 9]]
            assert engine == pytest.approx(PIs, abs=NUMERICAL_TOL)


R3_COSTS = ([15.0, 12.0, 20.0], [8.0, 9.0, 11.0, 14.0])  # Table 3.1, in Υ order (Initial State first for scrap)
N3_COSTS = ([4.0, 5.0, 6.0, 8.0, 9.0, 10.0, 13.0], [2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0])


class TestStageCostFunOld:
    """`historical/StageCostFun_old`: full SIGMA, N ≤ 3 through `Probs_1/2/3Var`, Eq 3.59 scrap (D1)."""

    @pytest.mark.parametrize(
        "MU, SIGMA, L, U, costs, tol",
        [
            pytest.param([5.4], [[1.7**2]], [3.0], [7.0], ([3.0], [2.0, 5.0]), TOL, id="N=1"),
            pytest.param([10.5115, 15.5651], np.eye(2), [8, 13], [12, 17], R3_COSTS, TOL, id="N=2 R3"),
            pytest.param([10.9, 14.2], np.diag([1.0, 2.25]), [8, 13], [12, 17], R3_COSTS, TOL, id="N=2 unequal sigma"),
            pytest.param(
                [10.6, 15.4], [[1.0, 0.75], [0.75, 1.5625]], [8, 13], [12, 17], R3_COSTS, NUMERICAL_TOL, id="N=2 rho=0.6"
            ),
            pytest.param(
                [11.2, 14.4], [[2.25, -1.2], [-1.2, 1.0]], [8, 13], [12, 17], R3_COSTS, NUMERICAL_TOL, id="N=2 rho=-0.8"
            ),
        ],
    )
    def test_equals_the_engine_for_up_to_two_features(self, MU, SIGMA, L, U, costs, tol):
        out = stage_cost_fun_old(MU, SIGMA, U, L, *costs)
        result = evaluate_engine(MU, SIGMA, U, L, *costs)
        n = len(MU)

        assert out.P[: 2**n] == pytest.approx(engine_rows(result, n), abs=tol)
        assert out.M[0] == pytest.approx([result.visits[s] for s in [I, *upsilon(n)]], abs=tol)
        assert out.F_stageC == pytest.approx(result.final_conformance, abs=tol)
        assert out.pIC == pytest.approx(result.transitions[I].conform, abs=tol)
        assert out.Rwi == pytest.approx(result.expected_rework_cost, abs=tol)
        assert out.Sri == pytest.approx(result.expected_scrap_cost, abs=tol)

    @pytest.mark.parametrize("MU", [(6.0, 5.5, 5.0), (4.15, 5.3, 5.55)])
    def test_three_independent_features_differ_only_in_the_eq_3_59_scrap_term(self, MU, record_property):
        MU, SIGMA, L, U = list(MU), np.diag([2.0, 2.5, 3.0]), [2.1, 3.5, 2.7], [6.2, 7.1, 8.4]
        out = stage_cost_fun_old(MU, SIGMA, U, L, *N3_COSTS)
        result = evaluate_engine(MU, SIGMA, U, L, *N3_COSTS)

        assert out.P[:8] == pytest.approx(engine_rows(result, 3), abs=TOL)
        assert out.M[0] == pytest.approx([result.visits[s] for s in [I, *upsilon(3)]], abs=TOL)
        assert out.F_stageC == pytest.approx(result.final_conformance, abs=TOL)
        assert out.Rwi == pytest.approx(result.expected_rework_cost, abs=TOL)
        # The same Eq 3.59 as the canonical `StageCostFun`, so the same D1 shortfall.
        _, _, _, canonical_sri = stage_cost_fun(MU, np.sqrt(np.diag(SIGMA)), 0.0, U, L, *N3_COSTS)
        assert out.Sri == pytest.approx(canonical_sri, abs=1e-12)
        record_property("eq_3_59_minus_exact", out.Sri - result.expected_scrap_cost)
        assert out.Sri < result.expected_scrap_cost - 1e-4

    def test_three_correlated_features_drop_the_correlation_in_pair_rework_states(self, record_property):
        MU, L, U = [6.0, 5.5, 5.0], [2.1, 3.5, 2.7], [6.2, 7.1, 8.4]
        SIGMA = TestProbs3Var.CORRELATED
        out = stage_cost_fun_old(MU, SIGMA, U, L, *N3_COSTS)
        result = evaluate_engine(MU, SIGMA, U, L, *N3_COSTS)

        rows = engine_rows(result, 3)
        full_sigma_rows = [0, 1, 2, 3, 7]  # I, {1}, {2}, {3}, {1,2,3}
        assert out.P[full_sigma_rows] == pytest.approx(rows[full_sigma_rows], abs=NUMERICAL_TOL)
        difference = out.F_stageC - result.final_conformance
        record_property("d15_final_conformance_difference", difference)
        warnings.warn(f"D15: StageCostFun_old minus engine f_C, correlated N=3: {difference:.6e}", stacklevel=1)
        assert abs(difference) > 1e-4


class TestPRRDefect:
    """D5: `StageCostFun` keeps only the non-zero self-loops of Q; `StageCostFun_old` indexes them explicitly."""

    # x1's mean is 40σ below U, so its rework tail underflows to exactly 0 in every port.
    MU, SIGMA, L, U = [-28.0, 15.0], np.eye(2), [-100.0, 13.0], [12.0, 17.0]

    def test_canonical_port_errors_when_a_self_loop_probability_is_zero(self):
        # MATLAB's PRR(a) then runs past the shortened vector ("Index exceeds the number of array elements").
        with pytest.raises(IndexError):
            stage_cost_fun(self.MU, [1.0, 1.0], 0.0, self.U, self.L, *R3_COSTS)

    def test_historical_port_still_equals_the_engine(self):
        out = stage_cost_fun_old(self.MU, self.SIGMA, self.U, self.L, *R3_COSTS)
        result = evaluate_engine(self.MU, self.SIGMA, self.U, self.L, *R3_COSTS)
        assert out.P[1, 1] == 0.0
        assert out.Sri == pytest.approx(result.expected_scrap_cost, abs=TOL)
        assert out.Rwi == pytest.approx(result.expected_rework_cost, abs=TOL)
        assert out.F_stageC == pytest.approx(result.final_conformance, abs=TOL)


class TestMarkovTriChars:
    """`Markov_TriChars`: an independent three-Feature script. It stops at S2 (undefined `p210`), so only
    its transition probabilities exist; its pair Rework States pass σ where `mvncdf` takes a variance (D16)."""

    A, B = [3.0, 3.0, 3.0], [7.0, 7.0, 7.0]  # the script's limits

    def test_port_reproduces_the_hand_computed_values(self):
        # The script's own inputs: means centred, σ = 2, so every tail is t = 1 − Φ(1) ...
        t = 0.15865525393145707
        c = 1 - 2 * t
        out = markov_tri_chars()
        assert out.ConformPrt == pytest.approx(c**3, abs=1e-15)
        assert out.conformpartchk == pytest.approx(c**3, abs=1e-15)
        assert [out.RW1, out.RW2, out.RW3] == pytest.approx([t * c * c] * 3, abs=1e-15)
        assert [out.RW12, out.RW13, out.RW23, out.RW123] == pytest.approx([t * t * c] * 3 + [t**3], abs=1e-15)
        assert out.Scrap == pytest.approx(1 - (1 - t) ** 3, abs=1e-15)
        assert out.ShouldEqOne == pytest.approx(1.0, abs=1e-15)
        assert [out.p22, out.p2S] == pytest.approx([t, t], abs=1e-15)
        # ... except in the pair states, which see variance 2: the tail is 1 − Φ(2/√2) = 1 − Φ(√2).
        t_pair = 0.07864960352514251
        assert out.p55 == pytest.approx(t_pair**2, abs=1e-15)
        assert out.p5S == pytest.approx(1 - (1 - t_pair) ** 2, abs=1e-15)

    @pytest.mark.parametrize("cut", [(5.0, 5.0, 5.0), (6.3, 4.4, 5.9), (3.6, 6.8, 7.4)])
    @pytest.mark.parametrize("sigma", [1.0, 2.0, 0.7])
    def test_engine_matches_transition_probabilities(self, cut, sigma):
        out = markov_tri_chars(cut=list(cut), A=self.A, B=self.B, sig11=sigma, sig22=sigma, sig33=sigma)
        rows = engine_rows(evaluate_engine(list(cut), np.diag([sigma**2] * 3), self.B, self.A), 3)

        initial = [out.RW1, out.RW2, out.RW3, out.RW12, out.RW13, out.RW23, out.RW123, out.ConformPrt, out.Scrap]
        assert rows[0, 1:] == pytest.approx(initial, abs=TOL)
        assert np.diag(rows[1:4, 1:4]) == pytest.approx([out.p22, out.p33, out.p44], abs=TOL)
        assert rows[1:4, 9] == pytest.approx([out.p2S, out.p3S, out.p4S], abs=TOL)
        assert rows[7, 9] == pytest.approx(out.p8S, abs=TOL)

        # The pair Rework States are drawn with standard deviation √σ instead of σ (D16).
        pair_rows = engine_rows(evaluate_engine(list(cut), np.diag([sigma] * 3), self.B, self.A), 3)
        pairs = [out.p55, out.p66, out.p77], [out.p5S, out.p6S, out.p7S]
        assert np.diag(pair_rows[4:7, 4:7]) == pytest.approx(pairs[0], abs=TOL)
        assert pair_rows[4:7, 9] == pytest.approx(pairs[1], abs=TOL)
        if sigma == 1.0:  # √σ = σ: harmless
            assert np.diag(rows[4:7, 4:7]) == pytest.approx(pairs[0], abs=TOL)
            assert rows[4:7, 9] == pytest.approx(pairs[1], abs=TOL)
        else:
            assert np.abs(rows[4:7, 9] - pairs[1]).max() > 1e-3


class TestMarkovProcess2Var:
    """`MarkovProcess_2_Var`: two one-Feature Stages in series, by Bowling 2004's chain, the thesis's series
    chain and the generalised multi-Stage form. The engine evaluates each Stage, and `evaluate_sequence`
    composes E(PR) by Eq 3.78."""

    SP, PC, RC, SC = 100.0, (4.0, 6.0), (1.0, 2.0), (5.0, 3.0)  # the script's hard-coded costs

    def test_port_reproduces_the_hand_computed_values(self):
        # Both means centred (σ = 2 on [3, 7], σ = 4 on [1, 9]): every tail is t = 1 − Φ(1).
        t = 0.15865525393145707
        f = (1 - 2 * t) / (1 - t)  # each Stage's f_C
        s = r = t / (1 - t)  # each Stage's scrap probability and expected rework visits
        out = markov_process_2_var(CUT=[5.0, 5.0], sig11=2.0, sig22=4.0, LSLx1=3.0, LSLx2=1.0, USLx1=7.0, USLx2=9.0)
        expected_profit = self.SP * f * f - (4 + 6 * f) - (5 * s + 3 * f * s) - (1 * r + 2 * f * r)
        assert out.fI1_C == pytest.approx(f, abs=1e-15)
        assert out.mI1_2 == pytest.approx(r, abs=1e-15)
        assert out.SR_Tot == pytest.approx(5 * s + 3 * f * s, abs=1e-14)
        assert out.EPR_generalised == pytest.approx(expected_profit, abs=1e-12)

    def test_the_three_legacy_chains_give_the_same_expected_profit(self):
        out = markov_process_2_var()
        assert out.EPR_conventional == pytest.approx(out.EPR_generalised, abs=1e-12)
        assert out.EPR_modified == pytest.approx(out.EPR_generalised, abs=1e-12)

    @pytest.mark.parametrize(
        "CUT, sigmas",
        [((5.0, 6.9), (1.5, 3.9)), ((4.2, 4.8), (1.5, 3.9)), ((6.1, 5.2), (0.8, 0.6)), ((2.0, 7.5), (1.1, 2.0))],
    )
    def test_engine_matches_each_stage_and_the_sequence_profit(self, CUT, sigmas):
        L, U = (1.0, 3.0), (7.0, 6.0)  # the script's limits
        out = markov_process_2_var(
            SP=self.SP, PC1=self.PC[0], PC2=self.PC[1], RC1=self.RC[0], RC2=self.RC[1], SC1=self.SC[0], SC2=self.SC[1],
            CUT=list(CUT), sig11=sigmas[0], sig22=sigmas[1], LSLx1=L[0], LSLx2=L[1], USLx1=U[0], USLx2=U[1],
        )
        first, second = (
            evaluate_engine([CUT[i]], [[sigmas[i] ** 2]], [U[i]], [L[i]], [self.RC[i]], [self.SC[i]] * 2) for i in (0, 1)
        )
        x = frozenset({"x1"})

        assert [first.transitions[I].rework[x], first.transitions[I].conform, first.transitions[I].scrap] == pytest.approx(
            [out.p11, out.p12, out.p14], abs=TOL
        )
        assert [second.transitions[I].rework[x], second.transitions[I].conform, second.transitions[I].scrap] == (
            pytest.approx([out.p22, out.p23, out.p24], abs=TOL)
        )
        assert first.visits[x] == pytest.approx(out.mI1_2, abs=TOL)
        assert first.visits[x] == pytest.approx(out.mIi2, abs=TOL)
        assert second.visits[x] == pytest.approx(out.mI2_2, abs=TOL)
        assert second.visits[x] == pytest.approx(out.mIIii2, abs=TOL)
        assert first.final_conformance == pytest.approx(out.fI1_C, abs=TOL)
        assert second.final_conformance == pytest.approx(out.fI2_C, abs=TOL)
        assert first.final_conformance * second.final_conformance == pytest.approx(out.f13, abs=TOL)
        assert first.final_conformance * second.final_conformance == pytest.approx(out.fIC, abs=TOL)
        assert second.scrap_probability == pytest.approx(out.f24, abs=TOL)
        assert second.scrap_probability == pytest.approx(out.fIIS, abs=TOL)
        assert [first.expected_scrap_cost, first.expected_rework_cost] == pytest.approx([out.SR_1, out.RW_1], abs=TOL)
        assert [second.expected_scrap_cost, second.expected_rework_cost] == pytest.approx([out.SR_2, out.RW_2], abs=TOL)

        stages = [
            Stage(
                features=(Feature(n, lower=L[i], upper=U[i], rework_side=ReworkSide.UPPER),),
                variation=MultivariateNormal([sigmas[i]]),
                costs=CostTable(processing=self.PC[i], rework={frozenset({n}): self.RC[i]},
                                scrap={I: self.SC[i], frozenset({n}): self.SC[i]}),
            )
            for i, n in enumerate(["x1", "x2"])
        ]
        means = [MeanSettings.per_feature(stage, {stage.feature_names[0]: CUT[i]}) for i, stage in enumerate(stages)]
        sequence = evaluate_sequence(Sequence(tuple(stages), self.SP), means)
        assert sequence.reach_probabilities == pytest.approx([1.0, out.fI1_C], abs=TOL)
        assert sum(sequence.scrap_costs) == pytest.approx(out.SR_Tot, abs=TOL)
        expected_profit = sequence.expected_profit
        assert expected_profit == pytest.approx(out.EPR_conventional, abs=TOL)
        assert expected_profit == pytest.approx(out.EPR_modified, abs=TOL)
        assert expected_profit == pytest.approx(out.EPR_generalised, abs=TOL)
