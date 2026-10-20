"""Model construction (spec §5.1): immutable and validated on construction."""

import dataclasses

import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage

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
