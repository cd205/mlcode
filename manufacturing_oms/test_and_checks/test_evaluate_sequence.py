"""Evaluating a Sequence of Stages in series (spec §2.2, §5.3, thesis Eq 3.78): R5 and Inspection Cost."""

import pytest

from oms import (
    CostTable,
    Feature,
    InspectionCost,
    MeanSettings,
    MultivariateNormal,
    ReworkSide,
    Sequence,
    Stage,
    evaluate_sequence,
)

I = frozenset()


def one_feature_stage(name, lower, upper, processing, rework, scrap, inspection=InspectionCost()):
    x = frozenset({name})
    return Stage(
        features=(Feature(name, lower=lower, upper=upper, rework_side=ReworkSide.UPPER),),
        variation=MultivariateNormal([1.0]),
        costs=CostTable(processing=processing, rework={x: rework}, scrap={I: scrap, x: scrap}),
        inspection=inspection,
    )


def table_3_5(inspection=InspectionCost()):
    """Thesis Table 3.5: two Serial Stages, PC = [25, 20], RC = [15, 12], cumulative SC = [10, 27] (D4)."""
    return Sequence(
        stages=(
            one_feature_stage("a", 8.0, 12.0, processing=25.0, rework=15.0, scrap=10.0, inspection=inspection),
            one_feature_stage("b", 13.0, 17.0, processing=20.0, rework=12.0, scrap=27.0, inspection=inspection),
        ),
        selling_price=120.0,
    )


def evaluate_at(sequence, *mu):
    means = [MeanSettings.per_feature(stage, {stage.feature_names[0]: m}) for stage, m in zip(sequence.stages, mu)]
    return evaluate_sequence(sequence, means)


class TestR5:
    def test_expected_profit_at_the_printed_means(self):
        result = evaluate_at(table_3_5(), 10.466, 15.591)
        assert round(result.expected_profit, 2) == 71.41


class TestInspectionCost:
    """A flat per_stage + per_feature · N per Stage, charged per part started and not weighted by r_i (U3).
    Thesis Table 3.8 charges 0.5 per Inspection plus 0.5 per Feature inspected."""

    TABLE_3_8 = InspectionCost(per_stage=0.5, per_feature=0.5)

    def test_r5_with_an_inspection_after_each_stage(self):
        result = evaluate_at(table_3_5(self.TABLE_3_8), 10.466, 15.591)
        assert result.inspection_costs == (1.0, 1.0)  # not weighted by r_2 < 1
        assert result.inspection_cost == 2.0
        assert round(result.expected_profit, 2) == 71.41  # E(PR) itself excludes Inspection Cost
        assert round(result.expected_profit_after_inspection, 2) == 69.41

    def test_one_parallel_stage_charges_for_each_feature(self):
        # R4 (Table 3.7) as a one-Stage Sequence: 0.5 + 2 × 0.5 for its single Inspection.
        stage = Stage(
            features=(
                Feature("a", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),
                Feature("b", lower=13.0, upper=17.0, rework_side=ReworkSide.UPPER),
            ),
            variation=MultivariateNormal([1.0, 1.0]),
            costs=CostTable.additive(
                processing=45.0, rework_per_feature={"a": 15.0, "b": 12.0}, scrap_per_feature={"a": 10.0, "b": 17.0}
            ),
            inspection=self.TABLE_3_8,
        )
        result = evaluate_sequence(Sequence((stage,), 120.0), [MeanSettings.per_feature(stage, {"a": 10.537, "b": 15.590})])
        assert result.inspection_cost == 1.5
        assert round(result.expected_profit, 2) == 71.17
        assert round(result.expected_profit_after_inspection, 2) == 69.67

    def test_defaults_to_no_inspection_cost(self):
        result = evaluate_at(table_3_5(), 10.466, 15.591)
        assert result.inspection_cost == 0.0
        assert result.expected_profit_after_inspection == result.expected_profit


class TestBreakdown:
    """Two centred one-Feature Stages with limits at ±1σ, so every tail is t = 1 − Φ(1) and each Stage has
    f_C = (1 − 2t)/(1 − t), and scrap probability = expected rework visits = t/(1 − t)."""

    t = 0.15865525393145707
    f = (1 - 2 * t) / (1 - t)
    s = r = t / (1 - t)

    @pytest.fixture
    def result(self):
        sequence = Sequence(
            stages=(
                one_feature_stage("a", 4.0, 6.0, processing=4.0, rework=1.0, scrap=5.0),
                one_feature_stage("b", 9.0, 11.0, processing=6.0, rework=2.0, scrap=3.0),
            ),
            selling_price=100.0,
        )
        return evaluate_at(sequence, 5.0, 10.0)

    def test_reach_probabilities(self, result):
        assert result.reach_probabilities == pytest.approx([1.0, self.f], abs=1e-14)

    def test_final_conformance_and_revenue(self, result):
        assert result.final_conformance == pytest.approx(self.f**2, abs=1e-14)
        assert result.revenue == pytest.approx(100 * self.f**2, abs=1e-12)

    def test_costs_per_stage_are_per_part_started(self, result):
        assert result.processing_costs == pytest.approx([4.0, 6.0 * self.f], abs=1e-12)
        assert result.scrap_costs == pytest.approx([5.0 * self.s, 3.0 * self.s * self.f], abs=1e-12)
        assert result.rework_costs == pytest.approx([1.0 * self.r, 2.0 * self.r * self.f], abs=1e-12)

    def test_expected_profit_is_revenue_less_every_cost(self, result):
        f, s, r = self.f, self.s, self.r
        expected = 100 * f * f - (4 + 5 * s + 1 * r) - (6 + 3 * s + 2 * r) * f
        assert result.expected_profit == pytest.approx(expected, abs=1e-12)

    def test_keeps_each_stage_result(self, result):
        assert [stage.final_conformance for stage in result.stages] == pytest.approx([self.f, self.f], abs=1e-14)


class TestMaterialValue:
    """C27, ADR 0006: the raw material's value, paid for every part started; a sold part recovers it through the
    Selling Price, a scrapped part loses it. Scrap Cost may be negative down to minus it (material recovered)."""

    def with_material(self, material_value, scrap=(10.0, 27.0)):
        r5 = table_3_5()
        stages = tuple(one_feature_stage(s.feature_names[0], s.features[0].lower, s.features[0].upper,
                                         processing=s.costs.processing, rework=rc, scrap=sc)
                       for s, rc, sc in zip(r5.stages, (15.0, 12.0), scrap))
        return Sequence(stages, selling_price=120.0, material_value=material_value)

    def test_defaults_to_zero(self):
        result = evaluate_at(table_3_5(), 10.466, 15.591)
        assert table_3_5().material_value == 0.0
        assert result.material_cost == 0.0

    @pytest.mark.parametrize("mu", [(10.466, 15.591), (11.0, 14.0)])
    def test_is_charged_once_per_part_started_at_any_mean_setting(self, mu):
        without = evaluate_at(table_3_5(), *mu)
        result = evaluate_at(self.with_material(5.0), *mu)
        assert result.material_cost == 5.0
        assert result.production_cost == pytest.approx(without.production_cost + 5.0, abs=1e-12)
        assert result.expected_profit == pytest.approx(without.expected_profit - 5.0, abs=1e-12)
        assert result.final_conformance == without.final_conformance

    def test_a_scrap_cost_may_recover_up_to_the_material_value(self):
        recovered = evaluate_at(self.with_material(5.0, scrap=(-5.0, 0.0)), 10.466, 15.591)
        assert recovered.scrap_costs[0] < 0

    def test_a_scrap_cost_recovering_more_than_the_material_value_is_refused(self):
        with pytest.raises(ValueError, match=r"Stage 1's Scrap Cost -5\.5 is below minus the Material Value, -5\.0"):
            self.with_material(5.0, scrap=(-5.5, 0.0))
        with pytest.raises(ValueError, match="below minus the Material Value"):
            self.with_material(0.0, scrap=(-0.1, 0.0))

    @pytest.mark.parametrize("value", [-1.0, float("inf"), float("nan")])
    def test_must_be_finite_and_non_negative(self, value):
        with pytest.raises(ValueError, match="Material Value"):
            self.with_material(value)
