"""Model construction (spec §5.1): immutable and validated on construction."""

import dataclasses

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
X = frozenset({"x"})


def x_feature(side=ReworkSide.UPPER):
    return Feature("x", lower=8.0, upper=12.0, rework_side=side)


def costs(rework=None, scrap=None):
    return CostTable(
        processing=25.0,
        rework={X: 10.0} if rework is None else rework,
        scrap={I: 15.0, X: 15.0} if scrap is None else scrap,
    )


def stage(feature=None, cost_table=None):
    return Stage(
        features=(feature or x_feature(),),
        variation=MultivariateNormal([1.0]),
        costs=cost_table or costs(),
    )


class TestFeature:
    def test_rework_side_is_required(self):
        with pytest.raises(TypeError):
            Feature("x", lower=0.0, upper=1.0)  # type: ignore[call-arg]

    def test_limits_must_be_ordered(self):
        with pytest.raises(ValueError):
            Feature("x", lower=2.0, upper=1.0, rework_side=ReworkSide.UPPER)

    def test_rework_side_must_be_the_enum(self):
        with pytest.raises(TypeError):
            Feature("x", lower=0.0, upper=1.0, rework_side="upper")  # type: ignore[arg-type]

    def test_is_immutable(self):
        with pytest.raises(dataclasses.FrozenInstanceError):
            x_feature().lower = 0.0  # type: ignore[misc]


class TestStage:
    def test_valid_single_feature_stage(self):
        s = stage()
        assert s.feature_names == ("x",)

    def test_needs_at_least_one_feature(self):
        with pytest.raises(ValueError):
            Stage(features=(), variation=MultivariateNormal([1.0]), costs=costs())

    def test_feature_names_must_be_unique(self):
        with pytest.raises(ValueError):
            Stage(
                features=(x_feature(), x_feature()),
                variation=MultivariateNormal([1.0, 1.0]),
                costs=costs(),
            )

    def test_variation_dimension_must_match_features(self):
        with pytest.raises(ValueError):
            Stage(features=(x_feature(),), variation=MultivariateNormal([1.0, 1.0]), costs=costs())

    def test_rework_costs_must_cover_exactly_the_rework_states(self):
        with pytest.raises(ValueError, match="rework"):
            stage(cost_table=costs(rework={}))

    def test_scrap_costs_must_cover_every_transient_state(self):
        with pytest.raises(ValueError, match="scrap"):
            stage(cost_table=costs(scrap={I: 15.0}))

    def test_rework_side_none_stage_has_no_rework_cost(self):
        s = stage(x_feature(ReworkSide.NONE), costs(rework={}, scrap={I: 15.0}))
        assert s.states == (I,)

    def test_rework_side_none_rejects_a_rework_cost(self):
        with pytest.raises(ValueError, match="rework"):
            stage(x_feature(ReworkSide.NONE), costs(scrap={I: 15.0}))


class TestCostTable:
    def test_costs_must_be_non_negative(self):
        with pytest.raises(ValueError):
            costs(rework={X: -1.0})

    def test_keeps_its_own_copy_of_the_mappings(self):
        rework = {X: 10.0}
        table = costs(rework=rework)
        rework[X] = 99.0
        assert table.rework[X] == 10.0

    def test_mappings_are_read_only(self):
        with pytest.raises(TypeError):
            costs().scrap[I] = 0.0  # type: ignore[index]

    def test_additive_sums_rework_over_the_group_and_scrap_over_the_stage(self):
        features = (
            Feature("a", lower=0.0, upper=1.0, rework_side=ReworkSide.UPPER),
            Feature("b", lower=0.0, upper=1.0, rework_side=ReworkSide.NONE),
            Feature("c", lower=0.0, upper=1.0, rework_side=ReworkSide.LOWER),
        )
        table = CostTable.additive(
            5.0, rework_per_feature={"a": 1.0, "c": 2.0}, scrap_per_feature={"a": 1.0, "b": 2.0, "c": 4.0}
        )
        a, c, ac = frozenset({"a"}), frozenset({"c"}), frozenset({"a", "c"})
        assert table.processing == 5.0
        assert table.rework == {a: 1.0, c: 2.0, ac: 3.0}
        assert table.scrap == {I: 7.0, a: 7.0, c: 7.0, ac: 7.0}
        Stage(features=features, variation=MultivariateNormal([1.0, 1.0, 1.0]), costs=table)  # keys fit the Stage

    def test_additive_rework_needs_a_scrap_cost_for_the_same_feature(self):
        with pytest.raises(ValueError, match="scrap"):
            CostTable.additive(5.0, rework_per_feature={"a": 1.0}, scrap_per_feature={"b": 1.0})


class TestMeanSettings:
    def test_per_feature_uses_one_mean_in_every_state(self):
        means = MeanSettings.per_feature(stage(), {"x": 10.5})
        assert means.by_state == {I: {"x": 10.5}, X: {"x": 10.5}}

    def test_per_feature_needs_exactly_the_stage_features(self):
        with pytest.raises(ValueError):
            MeanSettings.per_feature(stage(), {"y": 10.5})

    def test_mean_settings_are_read_only(self):
        means = MeanSettings.per_feature(stage(), {"x": 10.5})
        with pytest.raises(TypeError):
            means.by_state[I]["x"] = 0.0  # type: ignore[index]


class TestInspectionCost:
    def test_is_per_stage_plus_per_feature_inspected(self):
        assert InspectionCost(per_stage=0.5, per_feature=0.25).for_features(3) == 1.25

    def test_defaults_to_free(self):
        assert stage().inspection_cost == 0.0

    @pytest.mark.parametrize("kwargs", [{"per_stage": -0.5}, {"per_feature": -0.5}, {"per_stage": float("nan")}])
    def test_costs_must_be_finite_and_non_negative(self, kwargs):
        with pytest.raises(ValueError):
            InspectionCost(**kwargs)


def named_stage(name):
    x = frozenset({name})
    return Stage(
        features=(Feature(name, lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),),
        variation=MultivariateNormal([1.0]),
        costs=CostTable(processing=25.0, rework={x: 10.0}, scrap={I: 15.0, x: 15.0}),
    )


class TestSequence:
    def test_keeps_its_stages_as_a_tuple(self):
        stages = [named_stage("a"), named_stage("b")]
        assert Sequence(stages, selling_price=120.0).stages == tuple(stages)  # type: ignore[arg-type]

    def test_needs_at_least_one_stage(self):
        with pytest.raises(ValueError, match="Stage"):
            Sequence((), selling_price=120.0)

    def test_feature_names_must_be_unique_across_stages(self):
        with pytest.raises(ValueError, match="unique"):
            Sequence((named_stage("a"), named_stage("a")), selling_price=120.0)

    @pytest.mark.parametrize("price", [-1.0, float("inf"), float("nan")])
    def test_selling_price_must_be_finite_and_non_negative(self, price):
        with pytest.raises(ValueError, match="Selling Price"):
            Sequence((named_stage("a"),), selling_price=price)

    def test_is_immutable(self):
        sequence = Sequence((named_stage("a"),), selling_price=120.0)
        with pytest.raises(dataclasses.FrozenInstanceError):
            sequence.selling_price = 0.0  # type: ignore[misc]

    def test_evaluation_needs_one_mean_setting_per_stage(self):
        a, b = named_stage("a"), named_stage("b")
        sequence = Sequence((a, b), selling_price=120.0)
        with pytest.raises(ValueError, match="one Mean Setting per Stage"):
            evaluate_sequence(sequence, [MeanSettings.per_feature(a, {"a": 10.0})])

    def test_evaluation_checks_each_mean_setting_against_its_stage(self):
        a, b = named_stage("a"), named_stage("b")
        sequence = Sequence((a, b), selling_price=120.0)
        swapped = [MeanSettings.per_feature(b, {"b": 10.0}), MeanSettings.per_feature(a, {"a": 10.0})]
        with pytest.raises(ValueError):
            evaluate_sequence(sequence, swapped)
