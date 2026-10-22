"""Reference case R8 (thesis Tables 3.8, 3.9 and Fig 3.27): every Inspection placement for four ordered Features.

The Features are made in the order f1, f2, f3, f4. A Sequence groups them into Stages, each followed by
one Inspection. Costs follow the thesis's allocation (p. 109): a Stage's Processing and Rework Costs add up
over its Features, and its Scrap Cost is cumulative (A6), the Scrap Costs of every Feature made so far.
"""

import warnings

import pytest
from scipy.optimize import minimize

from oms import (
    CostTable,
    Feature,
    InspectionCost,
    MeanSettings,
    MultivariateNormal,
    ReworkSide,
    Stage,
    evaluate_sequence,
    search_sequences,
)
from oracles import stage_cost_fun

SELLING_PRICE = 120.0
TABLE_3_8 = {  # Feature: (PC, RC, SC, L, U), σ = 1
    "f1": (25.0, 15.0, 10.0, 8.0, 12.0),
    "f2": (20.0, 12.0, 17.0, 13.0, 17.0),
    "f3": (12.0, 8.0, 5.0, 10.0, 14.0),
    "f4": (15.0, 10.0, 12.0, 7.0, 11.0),
}
FEATURES = tuple(Feature(n, lower=L, upper=U, rework_side=ReworkSide.UPPER) for n, (*_, L, U) in TABLE_3_8.items())
FEATURE_NAMES = tuple(TABLE_3_8)


def table_3_8_stage(features, upstream):
    """A Stage of Table 3.8 Features, with Scrap Costs that include the value of the upstream Features."""
    names = [f.name for f in features]
    stage_costs = CostTable.additive(
        processing=sum(TABLE_3_8[n][0] for n in names),
        rework_per_feature={n: TABLE_3_8[n][1] for n in names},
        scrap_per_feature={n: TABLE_3_8[n][2] for n in names},
    )
    upstream_scrap = sum(TABLE_3_8[f.name][2] for f in upstream)
    return Stage(
        features=features,
        variation=MultivariateNormal([1.0] * len(features)),
        costs=CostTable(
            processing=stage_costs.processing,
            rework=stage_costs.rework,
            scrap={state: cost + upstream_scrap for state, cost in stage_costs.scrap.items()},
        ),
        inspection=InspectionCost(per_stage=0.5, per_feature=0.5),
    )


# Fig 3.27's Sequences, identified from Table 3.9: a Feature's optimal mean moves only when its Stage changes.
FIG_3_27 = {
    1: (("f1",), ("f2",), ("f3",), ("f4",)),
    2: (("f1", "f2"), ("f3",), ("f4",)),
    3: (("f1",), ("f2", "f3"), ("f4",)),
    4: (("f1",), ("f2",), ("f3", "f4")),
    5: (("f1", "f2"), ("f3", "f4")),
    6: (("f1",), ("f2", "f3", "f4")),
    7: (("f1", "f2", "f3"), ("f4",)),
    8: (("f1", "f2", "f3", "f4"),),
}
# Table 3.9's I column, with Seq 8 corrected from the printed 3 to 0.5 + 4 × 0.5 (D10a).
INSPECTION_COST = {1: 4.0, 2: 3.5, 3: 3.5, 4: 3.5, 5: 3.0, 6: 3.0, 7: 3.0, 8: 2.5}


@pytest.fixture(scope="module")
def ranked():
    """The search's results, as returned."""
    return search_sequences(FEATURES, table_3_8_stage, SELLING_PRICE, "per_feature")


@pytest.fixture(scope="module")
def r8(ranked):
    """The search's results keyed by Fig 3.27's Sequence number."""
    return {number(r): r for r in ranked}


def number(result):
    return next(k for k, groups in FIG_3_27.items() if groups == result.stage_features)


def test_every_inspection_placement_is_searched(r8):
    assert sorted(r8) == list(range(1, 9))  # 2^(4−1) Sequences


def test_inspection_cost_per_sequence(r8):
    assert {k: r.inspection_cost for k, r in r8.items()} == INSPECTION_COST


# Table 3.9: optimal means [f1, f2, f3, f4] and E(PR), as printed.
TABLE_3_9 = {
    1: ([10.389, 15.537, 12.674, 9.660], 41.7523),
    2: ([10.482, 15.535, 12.667, 9.660], 41.4665),
    3: ([10.388, 15.570, 12.666, 9.660], 41.6588),
    4: ([10.388, 15.537, 12.711, 9.659], 41.6501),
    5: ([10.482, 15.535, 12.711, 9.659], 41.3642),
    6: ([10.388, 15.615, 12.710, 9.657], 41.4215),
    7: ([10.516, 15.568, 12.664, 9.660], 41.2628),
    8: ([10.560, 15.613, 12.708, 9.656], 40.8657),
}
# Printed means the search misses by more than half a unit in the last place (D18, D19). Each is checked
# against the corrected value or the looser tolerance instead.
CORRECTED_MEANS = {(1, 2): 12.667}  # Seq 1's f3 Stage is the same as Seq 2's (D18)
LOOSE_MEANS = {(6, 1), (6, 2), (8, 3)}  # within one unit; E(PR) is flat there (D19)
SERIAL_AND_PAIRS = (1, 2, 3, 4, 5)  # every Stage has at most 2 Features, so Eq 3.59 is exact (ADR 0001)


def means_of(result):
    """The per_feature Mean Settings in Feature order, read from each Stage's Initial State."""
    return [mu for means in result.optimisation.means for mu in means.by_state[frozenset()].values()]


@pytest.mark.parametrize("k", list(TABLE_3_9))
def test_optimal_means(r8, k):
    for i, (found, printed) in enumerate(zip(means_of(r8[k]), TABLE_3_9[k][0])):
        expected = CORRECTED_MEANS.get((k, i), printed)
        tolerance = 1e-3 if (k, i) in LOOSE_MEANS else 5e-4
        assert found == pytest.approx(expected, abs=tolerance), f"Seq {k}, f{i + 1}"


@pytest.mark.parametrize("k", SERIAL_AND_PAIRS)
def test_expected_profit_as_printed(r8, k):
    assert round(r8[k].expected_profit, 4) == TABLE_3_9[k][1]


def eq_3_59_expected_profit(result, mu=None):
    """Thesis Eq 3.78 composed from the `StageCostFun` oracle, whose scrap term is Eq 3.59.

    `mu` maps each Feature to its mean; by default the search's means.
    """
    mu = dict(zip(FEATURE_NAMES, means_of(result))) if mu is None else mu
    expected_profit, reach = 0.0, 1.0
    for stage in result.sequence.stages:
        f_c, _, rework, scrap = stage_cost_fun(
            [mu[f.name] for f in stage.features],
            list(stage.variation.standard_deviations),
            0.0,
            [f.upper for f in stage.features],
            [f.lower for f in stage.features],
            [stage.costs.rework[s] for s in stage.states[1:]],
            [stage.costs.scrap[s] for s in stage.states],
        )
        expected_profit -= reach * (stage.costs.processing + scrap + rework)
        reach *= f_c
    return expected_profit + SELLING_PRICE * reach


class TestEq359Gap:
    """Seqs 6–8 each have a Stage of 3 or 4 Features, where the thesis's Eq 3.59 undercounts scrap (ADR 0001, D1)."""

    @pytest.mark.parametrize("k", list(TABLE_3_9))
    def test_eq_3_59_reproduces_every_printed_expected_profit(self, r8, k):
        assert round(eq_3_59_expected_profit(r8[k]), 4) == TABLE_3_9[k][1]

    @pytest.mark.parametrize("k", SERIAL_AND_PAIRS)
    def test_eq_3_59_equals_the_engine_up_to_two_features(self, r8, k):
        assert eq_3_59_expected_profit(r8[k]) == pytest.approx(r8[k].expected_profit, abs=1e-10)

    @pytest.mark.parametrize("k", (6, 7, 8))
    def test_the_engine_is_lower_by_the_eq_3_59_gap(self, r8, k):
        gap = r8[k].expected_profit - eq_3_59_expected_profit(r8[k])
        warnings.warn(f"D1: engine minus Eq 3.59 E(PR), R8 Seq {k}: {gap:.6e}", stacklevel=1)
        assert -5e-4 < gap < -1e-5  # the extra expected scrap, about 1 to 2 in the 4th decimal
        assert round(r8[k].expected_profit, 4) < TABLE_3_9[k][1]


# Table 3.9's E(PR) − I with Seqs 6–8 corrected (D10b), and both rankings, best first.
EXPECTED_PROFIT_AFTER_INSPECTION = {
    1: 37.7523, 2: 37.9665, 3: 38.1588, 4: 38.1501, 5: 38.3642, 6: 38.4215, 7: 38.2628, 8: 38.3657
}
RANKED_BY_EXPECTED_PROFIT = [1, 3, 4, 2, 6, 5, 7, 8]  # Rank 1
RANKED_AFTER_INSPECTION = [6, 8, 5, 7, 3, 4, 2, 1]  # Rank 2, corrected (D10b)


class TestRanking:
    def test_results_are_ranked_by_expected_profit(self, ranked):
        assert [number(r) for r in ranked] == RANKED_BY_EXPECTED_PROFIT
        assert [r.rank for r in ranked] == list(range(1, 9))

    def test_rank_after_inspection(self, r8):
        by_rank = sorted(r8, key=lambda k: r8[k].rank_after_inspection)
        assert by_rank == RANKED_AFTER_INSPECTION

    @pytest.mark.parametrize("k", list(TABLE_3_9))
    def test_expected_profit_after_inspection(self, r8, k):
        result = r8[k]
        assert result.expected_profit_after_inspection == result.expected_profit - INSPECTION_COST[k]
        # Seqs 6–8 carry the Eq 3.59 gap, so the corrected values are compared with the oracle's E(PR).
        oracle = eq_3_59_expected_profit(result) - INSPECTION_COST[k]
        assert round(oracle, 4) == EXPECTED_PROFIT_AFTER_INSPECTION[k]
        if k in SERIAL_AND_PAIRS:
            assert round(result.expected_profit_after_inspection, 4) == EXPECTED_PROFIT_AFTER_INSPECTION[k]
        else:  # lower by the Eq 3.59 gap (D1)
            assert -5e-4 < result.expected_profit_after_inspection - EXPECTED_PROFIT_AFTER_INSPECTION[k] < 0


class TestInputs:
    def test_one_feature_has_one_sequence(self):
        (result,) = search_sequences(FEATURES[:1], table_3_8_stage, SELLING_PRICE, n_starts=1)
        assert result.stage_features == (("f1",),)
        assert (result.rank, result.rank_after_inspection) == (1, 1)

    def test_needs_a_feature(self):
        with pytest.raises(ValueError, match="at least one Feature"):
            search_sequences((), table_3_8_stage, SELLING_PRICE)

    def test_stage_builder_must_make_the_features_it_is_given(self):
        def reversed_stage(features, upstream):
            return table_3_8_stage(features[::-1], upstream)

        with pytest.raises(ValueError, match="stage_builder must return a Stage of exactly"):
            search_sequences(FEATURES[:2], reversed_stage, SELLING_PRICE, n_starts=1)


class TestPrintedMeans:
    """The pass rule for evaluation (spec §6): E(PR) at Table 3.9's printed means rounds to the printed E(PR)."""

    @staticmethod
    def printed_means(k):
        return dict(zip(FEATURE_NAMES, TABLE_3_9[k][0]))

    @staticmethod
    def engine_expected_profit(result, mu):
        means = [MeanSettings.per_feature(s, {n: mu[n] for n in s.feature_names}) for s in result.sequence.stages]
        return evaluate_sequence(result.sequence, means).expected_profit

    @pytest.mark.parametrize("k", [k for k in SERIAL_AND_PAIRS if k != 1])
    def test_engine_at_the_printed_means(self, r8, k):
        assert round(self.engine_expected_profit(r8[k], self.printed_means(k)), 4) == TABLE_3_9[k][1]

    def test_seq_1_needs_the_corrected_f3_mean(self, r8):
        printed = self.printed_means(1)
        assert round(self.engine_expected_profit(r8[1], printed), 4) == 41.7522  # 12.674 as printed (D18)
        corrected = {**printed, "f3": CORRECTED_MEANS[(1, 2)]}
        assert round(self.engine_expected_profit(r8[1], corrected), 4) == TABLE_3_9[1][1]

    @pytest.mark.parametrize("k", (6, 7, 8))
    def test_eq_3_59_at_the_printed_means(self, r8, k):
        assert round(eq_3_59_expected_profit(r8[k], self.printed_means(k)), 4) == TABLE_3_9[k][1]


@pytest.mark.parametrize("k", (6, 8))
def test_eq_3_59_optimum_puts_the_loose_means_where_the_engine_does(r8, k):
    """D19: the scrap formula doesn't move the optimum enough to explain the loosely matched printed means."""
    result = r8[k]

    def loss(mu):
        return -eq_3_59_expected_profit(result, dict(zip(FEATURE_NAMES, mu)))

    oracle = minimize(loss, means_of(result), method="Nelder-Mead", options={"xatol": 1e-7, "fatol": 1e-12})
    assert oracle.x == pytest.approx(means_of(result), abs=1e-4)
    for _, i in sorted(m for m in LOOSE_MEANS if m[0] == k):
        assert abs(oracle.x[i] - TABLE_3_9[k][0][i]) > 4e-4  # the printed mean is about as far from either optimum
