"""Evaluating a Parallel Stage of several Gaussian Features (spec §2.1, §5.3): R3, R4 and the §6 properties."""

import numpy as np
import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage, evaluate_stage

I = frozenset()
A = frozenset({"a"})
B = frozenset({"b"})
AB = frozenset({"a", "b"})
SELLING_PRICE = 120.0


def table_3_features():
    """Thesis Tables 3.1 and 3.7: L = [8, 13], U = [12, 17], σ = 1, Rework Side above U."""
    return (
        Feature("a", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),
        Feature("b", lower=13.0, upper=17.0, rework_side=ReworkSide.UPPER),
    )


def evaluate_at(stage, **mu):
    return evaluate_stage(stage, MeanSettings.per_feature(stage, mu))


class TestR3:
    """Thesis Table 3.1, Eq 3.44: Scrap Cost differs by state."""

    @pytest.fixture
    def stage(self):
        return Stage(
            features=table_3_features(),
            variation=MultivariateNormal([1.0, 1.0]),
            costs=CostTable(
                processing=45.0,
                rework={A: 15.0, B: 12.0, AB: 20.0},
                scrap={I: 8.0, A: 9.0, B: 11.0, AB: 14.0},
            ),
        )

    def test_expected_profit_at_the_printed_means(self, stage):
        result = evaluate_at(stage, a=10.5115, b=15.5651)
        assert round(result.expected_profit(SELLING_PRICE), 4) == 71.4287


class TestR4:
    """Thesis Table 3.7: additive Rework Costs, Scrap Cost 10 + 17 = 27 from every state."""

    @pytest.fixture
    def stage(self):
        return Stage(
            features=table_3_features(),
            variation=MultivariateNormal([1.0, 1.0]),
            costs=CostTable.additive(
                processing=45.0, rework_per_feature={"a": 15.0, "b": 12.0}, scrap_per_feature={"a": 10.0, "b": 17.0}
            ),
        )

    def test_expected_profit_at_the_printed_means(self, stage):
        result = evaluate_at(stage, a=10.537, b=15.590)
        assert round(result.expected_profit(SELLING_PRICE), 2) == 71.17

    def test_production_cost_at_the_printed_minimum(self, stage):
        result = evaluate_at(stage, a=10.128, b=15.181)
        assert round(result.production_cost, 3) == 46.753


# ---- §6 property tests on correlated Stages -------------------------------------------------------

SIDES = {"upper": ReworkSide.UPPER, "lower": ReworkSide.LOWER, "none": ReworkSide.NONE}


def correlated_stage(names, sides, corr, sigmas=None, limits=None):
    """A Parallel Stage with distinct, additive costs so that misrouted probability shows up in money."""
    n = len(names)
    limits = limits or [(8.0 + 5 * i, 12.0 + 5 * i) for i in range(n)]
    features = tuple(
        Feature(name, lower=lo, upper=hi, rework_side=SIDES[side]) for name, side, (lo, hi) in zip(names, sides, limits)
    )
    rework = {f.name: 10.0 + 3 * i for i, f in enumerate(features) if f.reworkable}
    scrap = {f.name: 5.0 + 2 * i for i, f in enumerate(features)}
    return Stage(
        features=features,
        variation=MultivariateNormal(sigmas or [1.0 + 0.25 * i for i in range(n)], corr),
        costs=CostTable.additive(45.0, rework, scrap),
    )


THREE_CORR = [[1.0, 0.6, -0.3], [0.6, 1.0, 0.2], [-0.3, 0.2, 1.0]]
STAGES = {
    "2D ρ=0.7": (("a", "b"), ("upper", "upper"), 0.7, {"a": 10.6, "b": 15.4}),
    "2D ρ=−0.8 mixed sides": (("a", "b"), ("upper", "lower"), -0.8, {"a": 10.4, "b": 14.6}),
    "3D": (("a", "b", "c"), ("upper", "lower", "upper"), THREE_CORR, {"a": 10.5, "b": 14.5, "c": 20.4}),
    "3D one side none": (("a", "b", "c"), ("upper", "none", "lower"), THREE_CORR, {"a": 10.5, "b": 15.0, "c": 19.6}),
}


@pytest.fixture(params=list(STAGES), ids=list(STAGES))
def case(request):
    names, sides, corr, mu = STAGES[request.param]
    stage = correlated_stage(names, sides, corr)
    return stage, mu, evaluate_stage(stage, MeanSettings.per_feature(stage, mu))


class TestProperties:
    def test_uses_deterministic_box_probabilities(self, case):
        _, _, result = case
        assert "monte_carlo" not in result.methods
        assert result.abs_error <= 1e-8

    def test_probabilities_lie_in_the_unit_interval(self, case):
        _, _, result = case
        for t in result.transitions.values():
            assert all(0.0 <= p <= 1.0 for p in [t.conform, t.scrap, *t.rework.values()])

    def test_each_row_of_q_and_r_sums_to_one(self, case):
        _, _, result = case
        for t in result.transitions.values():
            assert t.conform + t.scrap + sum(t.rework.values()) == pytest.approx(1.0, abs=1e-8)

    def test_every_part_eventually_conforms_or_is_scrapped(self, case):
        _, _, result = case
        assert result.final_conformance + result.scrap_probability == pytest.approx(1.0, abs=1e-8)
        assert all(m >= 0 for m in result.visits.values())

    def test_every_reworkable_subset_is_a_state_distinct_from_the_initial_state(self, case):
        stage, _, result = case
        reworkable = frozenset(f.name for f in stage.features if f.reworkable)
        assert len(result.states) == 2 ** len(reworkable)
        assert reworkable in result.states and reworkable != I
        # From I the part can land in any Rework State, including the all-Features one.
        assert set(result.transitions[I].rework) == set(result.states) - {I}
        # A Rework State S only redraws S, so it can loop back to itself or move to a subset of S.
        for state in result.states[1:]:
            assert set(result.transitions[state].rework) == {s for s in result.states[1:] if s <= state}

    def test_results_do_not_depend_on_feature_order(self, case):
        stage, mu, result = case
        order = list(reversed(range(len(stage.features))))
        corr = np.asarray(stage.variation.corr)[np.ix_(order, order)]
        permuted = Stage(
            features=tuple(stage.features[i] for i in order),
            variation=MultivariateNormal([stage.variation.sigmas[i] for i in order], corr),
            costs=stage.costs,
        )
        other = evaluate_stage(permuted, MeanSettings.per_feature(permuted, mu))
        assert other.final_conformance == pytest.approx(result.final_conformance, abs=1e-8)
        assert other.visits == pytest.approx(dict(result.visits), abs=1e-8)
        assert other.expected_profit(SELLING_PRICE) == pytest.approx(result.expected_profit(SELLING_PRICE), abs=1e-6)

    def test_mirroring_a_feature_leaves_every_result_unchanged(self, case):
        # Reflect the first Feature: limits and mean change sign, its Rework Side flips, and so do its correlations.
        stage, mu, result = case
        first = stage.features[0]
        flipped = {ReworkSide.UPPER: ReworkSide.LOWER, ReworkSide.LOWER: ReworkSide.UPPER}[first.rework_side]
        mirrored_feature = Feature(first.name, lower=-first.upper, upper=-first.lower, rework_side=flipped)
        sign = np.ones(len(stage.features))
        sign[0] = -1.0
        corr = np.asarray(stage.variation.corr) * np.outer(sign, sign)
        mirrored = Stage(
            features=(mirrored_feature, *stage.features[1:]),
            variation=MultivariateNormal(stage.variation.sigmas, corr),
            costs=stage.costs,
        )
        other = evaluate_stage(mirrored, MeanSettings.per_feature(mirrored, {**mu, first.name: -mu[first.name]}))
        assert other.final_conformance == pytest.approx(result.final_conformance, abs=1e-8)
        assert other.visits == pytest.approx(dict(result.visits), abs=1e-8)
        assert other.expected_scrap_cost == pytest.approx(result.expected_scrap_cost, abs=1e-6)
        assert other.expected_rework_cost == pytest.approx(result.expected_rework_cost, abs=1e-6)


class TestLimitingCases:
    @pytest.mark.parametrize("corr", [0.0, 0.5, -0.5])
    def test_far_towards_the_rework_side_always_conforms_eventually(self, corr):
        stage = correlated_stage(("a", "b"), ("upper", "lower"), corr)
        # 5σ past U for a and 5σ below L for b: almost every draw lands on the Rework Side again.
        result = evaluate_stage(stage, MeanSettings.per_feature(stage, {"a": 17.0, "b": 6.75}))
        assert result.final_conformance == pytest.approx(1.0, abs=1e-6)
        assert max(result.visits.values()) > 1e4

    @pytest.mark.parametrize("corr", [0.0, 0.5, -0.5])
    def test_far_towards_the_scrap_side_never_conforms(self, corr):
        stage = correlated_stage(("a", "b"), ("upper", "lower"), corr)
        result = evaluate_stage(stage, MeanSettings.per_feature(stage, {"a": -2.0, "b": 30.0}))
        assert result.final_conformance == pytest.approx(0.0, abs=1e-12)


class TestUncorrelated:
    def test_zero_correlation_two_feature_box_is_the_product_of_one_feature_boxes(self):
        stage = correlated_stage(("a", "b"), ("upper", "upper"), 0.0)
        result = evaluate_stage(stage, MeanSettings.per_feature(stage, {"a": 10.6, "b": 15.4}))
        a = MultivariateNormal([1.0]).box_probability([10.6], [8.0], [12.0]).value
        b = MultivariateNormal([1.25]).box_probability([15.4], [13.0], [17.0]).value
        assert result.transitions[I].conform == pytest.approx(a * b, abs=1e-15)


class TestFourFeatures:
    """Four correlated Features need quasi-Monte Carlo for the Initial State's draw."""

    CORR = [[1.0, 0.3, -0.2, 0.5], [0.3, 1.0, 0.4, 0.1], [-0.2, 0.4, 1.0, -0.3], [0.5, 0.1, -0.3, 1.0]]
    MU = {"a": 10.5, "b": 14.6, "c": 20.6, "d": 24.5}

    @pytest.fixture
    def stage(self):
        return correlated_stage(("a", "b", "c", "d"), ("upper", "lower", "upper", "lower"), self.CORR, sigmas=[1.0] * 4)

    def evaluate(self, stage, seed):
        return evaluate_stage(stage, MeanSettings.per_feature(stage, self.MU), rng_seed=seed)

    def test_reports_monte_carlo_with_its_error(self, stage):
        result = self.evaluate(stage, 0)
        assert result.methods == {"analytic", "numerical", "monte_carlo"}
        assert 0.0 < result.abs_error < 1e-3

    def test_is_reproducible_from_its_seed(self, stage):
        assert self.evaluate(stage, 4).final_conformance == self.evaluate(stage, 4).final_conformance
        assert self.evaluate(stage, 4).final_conformance != self.evaluate(stage, 5).final_conformance

    def test_seeds_agree_within_the_reported_error(self, stage):
        first, second = self.evaluate(stage, 1), self.evaluate(stage, 2)
        tolerance = 3 * (first.abs_error + second.abs_error)
        assert first.final_conformance == pytest.approx(second.final_conformance, abs=tolerance)

    def test_every_part_eventually_conforms_or_is_scrapped(self, stage):
        result = self.evaluate(stage, 0)
        assert result.final_conformance + result.scrap_probability == pytest.approx(1.0, abs=3 * result.abs_error)
