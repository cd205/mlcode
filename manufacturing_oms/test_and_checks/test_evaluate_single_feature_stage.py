"""Evaluating a one-Feature Stage (spec §2.1, §5.3): reference case R1 and the §6 properties."""

import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage, evaluate_stage

I = frozenset()
X = frozenset({"x"})


def one_feature_stage(lower, upper, side, sigma=1.0, pc=25.0, rc=10.0, sc=15.0):
    reworkable = side is not ReworkSide.NONE
    return Stage(
        features=(Feature("x", lower=lower, upper=upper, rework_side=side),),
        variation=MultivariateNormal([sigma]),
        costs=CostTable(
            processing=pc,
            rework={X: rc} if reworkable else {},
            scrap={I: sc, X: sc} if reworkable else {I: sc},
        ),
    )


def evaluate_at(stage, mu):
    return evaluate_stage(stage, MeanSettings.per_feature(stage, {"x": mu}))


class TestR1:
    """Thesis Fig 3.12/3.14: μ = 5, σ = 1, [3, 7], Rework Side above U."""

    @pytest.fixture
    def result(self):
        return evaluate_at(one_feature_stage(3.0, 7.0, ReworkSide.UPPER), 5.0)

    def test_first_pass_conformance(self, result):
        assert round(result.transitions[I].conform, 4) == 0.9545

    def test_expected_number_of_operations(self, result):
        # The thesis's one-Feature chain merges I with its Rework State (equal means), so its
        # m_{I,I} = 1.0233 counts every operation: the initial one plus the rework visits.
        assert round(sum(result.visits.values()), 4) == 1.0233
        assert result.visits[X] == pytest.approx(0.02328, abs=5e-6)  # pre-check value

    def test_final_conformance_probability(self, result):
        assert round(result.final_conformance, 4) == 0.9767
        assert result.final_conformance == pytest.approx(0.97672, abs=5e-6)  # pre-check value

    def test_analytic_method_is_reported(self, result):
        assert result.methods == frozenset({"analytic"})
        assert result.abs_error == 0.0


class TestCosts:
    def test_costs_are_reported_separately(self):
        # Hand-worked with μ at the centre of [8, 12]: p_X = p_R = 1 − Φ(2) per draw.
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), 10.0)
        tail = 0.022750131948179195
        assert result.processing_cost == 25.0
        assert result.expected_rework_cost == pytest.approx(10.0 * tail / (1 - tail), rel=1e-12)
        assert result.expected_scrap_cost == pytest.approx(15.0 * tail / (1 - tail), rel=1e-12)

    def test_scrap_cost_differs_by_state(self):
        stage = Stage(
            features=(Feature("x", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),),
            variation=MultivariateNormal([1.0]),
            costs=CostTable(processing=0.0, rework={X: 0.0}, scrap={I: 1.0, X: 0.0}),
        )
        result = evaluate_at(stage, 10.0)
        # Only scrap from the Initial State is charged, so Sr is just p_{I,X}.
        assert result.expected_scrap_cost == pytest.approx(0.022750131948179195, rel=1e-12)


class TestSanity:
    @pytest.mark.parametrize("mu", [6.0, 9.0, 10.0, 10.6, 12.5, 15.0])
    def test_every_part_eventually_conforms_or_is_scrapped(self, mu):
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), mu)
        assert result.final_conformance + result.scrap_probability == pytest.approx(1.0, abs=1e-12)

    @pytest.mark.parametrize("mu", [6.0, 10.0, 15.0])
    def test_visits_are_non_negative(self, mu):
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), mu)
        assert all(m >= 0 for m in result.visits.values())

    @pytest.mark.parametrize("mu", [6.0, 10.0, 15.0])
    def test_each_state_has_conform_rework_scrap_summing_to_one(self, mu):
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), mu)
        for t in result.transitions.values():
            assert t.conform + t.scrap + sum(t.rework.values()) == pytest.approx(1.0, abs=1e-12)

    def test_far_towards_the_rework_side_always_conforms_eventually(self):
        # μ − U = 5.5σ: each rework draw lands back on the Rework Side with probability 1 − 1.9e-8.
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), 17.5)
        assert result.final_conformance == pytest.approx(1.0, abs=1e-9)
        assert result.visits[X] > 1e6

    def test_far_towards_the_scrap_side_never_conforms(self):
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), -10.0)
        assert result.final_conformance == pytest.approx(0.0, abs=1e-12)


class TestMirror:
    """Flipping the Rework Side and reflecting the limits and the mean leaves every result unchanged."""

    @pytest.mark.parametrize("mu", [9.0, 10.0, 10.61, 11.5])
    def test_mirrored_feature_gives_identical_results(self, mu):
        upper = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.UPPER), mu)
        lower = evaluate_at(one_feature_stage(-12.0, -8.0, ReworkSide.LOWER), -mu)
        assert lower.final_conformance == pytest.approx(upper.final_conformance, abs=1e-14)
        assert lower.scrap_probability == pytest.approx(upper.scrap_probability, abs=1e-14)
        assert lower.visits == pytest.approx(upper.visits, abs=1e-14)
        assert lower.expected_scrap_cost == pytest.approx(upper.expected_scrap_cost, abs=1e-12)
        assert lower.expected_rework_cost == pytest.approx(upper.expected_rework_cost, abs=1e-12)
        for state in upper.states:
            assert lower.transitions[state].conform == pytest.approx(upper.transitions[state].conform, abs=1e-14)
            assert lower.transitions[state].scrap == pytest.approx(upper.transitions[state].scrap, abs=1e-14)
            assert lower.transitions[state].rework == pytest.approx(upper.transitions[state].rework, abs=1e-14)


class TestNoReworkSide:
    def test_rework_side_none_yields_no_rework_state(self):
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.NONE), 10.0)
        assert result.states == (I,)
        assert result.visits == {I: 1.0}
        assert result.expected_rework_cost == 0.0

    def test_rework_side_none_conforms_only_on_the_first_pass(self):
        result = evaluate_at(one_feature_stage(8.0, 12.0, ReworkSide.NONE), 10.0)
        assert result.final_conformance == pytest.approx(0.9544997361036416, abs=1e-14)
        assert result.expected_scrap_cost == pytest.approx(15.0 * (1 - 0.9544997361036416), abs=1e-12)


def test_mean_settings_must_match_the_stage():
    stage = one_feature_stage(8.0, 12.0, ReworkSide.UPPER)
    with pytest.raises(ValueError):
        evaluate_stage(stage, MeanSettings({I: {"x": 10.0}}))
