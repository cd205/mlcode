"""`evaluate_sequence` against a faithful port of the `Costs_MultiStage_MultiFeature` script (ADR 0002, issue #7).

The script composes thesis Eq 3.78 from `StageCostFun_old` and from `StageCostFun`. It has no Inspection
Cost and hard-codes the Rework Side above U, so the engine gets UPPER-side Features and no Inspection
Cost, and evaluates with `per_feature` Mean Settings.
"""

from itertools import combinations

import numpy as np
import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Sequence, Stage, evaluate_sequence
from oracles import TWO_STAGE_DUAL_FEATURE, TWO_STAGE_SINGLE_FEATURE, costs_multi_stage_multi_feature

TOL = 1e-10
NUMERICAL_TOL = 1e-8  # correlated 2D boxes: numerical on both sides (oracles/mvncdf.py, ADR 0003)


def evaluate_engine(SP, PC, U_cell, L_cell, MU_cell, SIGMA_cell, S_Cost_cell, R_Cost_cell):
    """The engine on the script's inputs. Stage i's Features are s{i}x1..s{i}xN; costs are in Υ order."""
    stages, means = [], []
    for i, (pc, U, L, MU, SIGMA, S_Cost, R_Cost) in enumerate(
        zip(PC, U_cell, L_cell, MU_cell, SIGMA_cell, S_Cost_cell, R_Cost_cell), start=1
    ):
        names = [f"s{i}x{j + 1}" for j in range(len(MU))]
        upsilon = [frozenset(g) for k in range(1, len(names) + 1) for g in combinations(names, k)]
        SIGMA = np.asarray(SIGMA, dtype=float)
        sigmas = np.sqrt(np.diag(SIGMA))
        corr = SIGMA / np.outer(sigmas, sigmas)
        np.fill_diagonal(corr, 1.0)
        stage = Stage(
            features=tuple(Feature(n, lower=lo, upper=hi, rework_side=ReworkSide.UPPER) for n, lo, hi in zip(names, L, U)),
            variation=MultivariateNormal(sigmas, corr),
            costs=CostTable(
                processing=pc, rework=dict(zip(upsilon, R_Cost)), scrap=dict(zip([frozenset(), *upsilon], S_Cost))
            ),
        )
        stages.append(stage)
        means.append(MeanSettings.per_feature(stage, dict(zip(names, MU))))
    return evaluate_sequence(Sequence(tuple(stages), SP), means)


def with_means(block, *MU_cell):
    return {**block, "MU_cell": [list(mu) for mu in MU_cell]}


def correlated(block, rho):
    return {
        **block,
        "SIGMA_cell": [
            [[s[0][0], rho * np.sqrt(s[0][0] * s[1][1])], [rho * np.sqrt(s[0][0] * s[1][1]), s[1][1]]]
            for s in block["SIGMA_cell"]
        ],
    }


def assert_engine_matches(block, tol, rho=0.0):
    out = costs_multi_stage_multi_feature(**block, rho=rho)
    engine = evaluate_engine(**block)
    per_stage = [p + s + r for p, s, r in zip(engine.processing_costs, engine.scrap_costs, engine.rework_costs)]
    for loop in (out.old_method, out.new_method):
        assert [r.final_conformance for r in engine.stages] == pytest.approx(loop.F_stageC_vec[1:], abs=tol)
        assert per_stage == pytest.approx(loop.ProdCost, abs=tol)
        assert engine.production_cost == pytest.approx(loop.ProdCost_total, abs=tol)
        assert engine.expected_profit == pytest.approx(loop.EP, abs=tol)


class TestScriptBlocks:
    def test_r5_block_matches_the_engine(self):
        assert_engine_matches(TWO_STAGE_SINGLE_FEATURE, TOL)

    def test_r5_block_rounds_to_the_printed_profit(self):
        # The script's second mean is 15.575, not Table 3.5's 15.591; both round to 71.41.
        assert round(costs_multi_stage_multi_feature(**TWO_STAGE_SINGLE_FEATURE).old_method.EP, 2) == 71.41

    def test_dual_feature_block_matches_the_engine(self):
        assert_engine_matches(TWO_STAGE_DUAL_FEATURE, TOL)


class TestNearbyInputs:
    @pytest.mark.parametrize(
        "MU_cell", [([10.466], [15.591]), ([9.2], [16.4]), ([11.5], [14.0]), ([12.3], [15.0])]
    )
    def test_single_feature_stages(self, MU_cell):
        assert_engine_matches(with_means(TWO_STAGE_SINGLE_FEATURE, *MU_cell), TOL)

    @pytest.mark.parametrize("MU_cell", [([11.0, 16.2], [14.0, 11.5]), ([9.5, 14.5], [10.0, 9.0])])
    def test_dual_feature_stages(self, MU_cell):
        assert_engine_matches(with_means(TWO_STAGE_DUAL_FEATURE, *MU_cell), TOL)

    @pytest.mark.parametrize("rho", [0.6, -0.4])
    def test_correlated_dual_feature_stages(self, rho):
        block = correlated(with_means(TWO_STAGE_DUAL_FEATURE, [11.0, 16.2], [14.0, 11.5]), rho)
        assert_engine_matches(block, NUMERICAL_TOL, rho=rho)
