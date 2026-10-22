"""Optimising one Feature's Mean Setting in a one-Stage Sequence (spec §5.4): R2, thesis Table 3.3 / Fig 3.24."""

import pytest

from oms import CostTable, Feature, MultivariateNormal, ReworkSide, Sequence, Stage, optimise_means

I = frozenset()
X = frozenset({"x"})
SELLING_PRICE = 120.0


def table_3_3(side=ReworkSide.UPPER, lower=8.0, upper=12.0):
    stage = Stage(
        features=(Feature("x", lower=lower, upper=upper, rework_side=side),),
        variation=MultivariateNormal([1.0]),
        costs=CostTable(processing=25.0, rework={X: 10.0}, scrap={I: 15.0, X: 15.0}),
    )
    return Sequence(stages=(stage,), selling_price=SELLING_PRICE)


def optimum(result):
    return result.means[0].by_state[I]["x"]


def test_r2_expected_profit_optimum():
    result = optimise_means(table_3_3())
    assert abs(optimum(result) - 10.61) <= 0.005  # printed precision
    assert optimum(result) == pytest.approx(10.6144, abs=1e-3)  # pre-check value
    assert result.objective_value == pytest.approx(result.breakdown.expected_profit)


def test_r2_minimum_production_cost():
    # U2: production cost is Processing + Scrap + Rework Cost per part started.
    result = optimise_means(table_3_3(), objective="production_cost")
    assert abs(optimum(result) - 10.09) <= 0.005  # printed precision
    assert optimum(result) == pytest.approx(10.0875, abs=1e-3)  # pre-check value
    assert result.objective_value == pytest.approx(result.breakdown.production_cost)


def test_optimum_uses_the_mean_in_every_state():
    result = optimise_means(table_3_3())
    assert result.means[0].by_state[X]["x"] == optimum(result)


def test_mirrored_stage_has_the_mirrored_optimum():
    upper = optimise_means(table_3_3())
    lower = optimise_means(table_3_3(ReworkSide.LOWER, -12.0, -8.0))
    assert optimum(lower) == pytest.approx(-optimum(upper), abs=1e-5)
    assert lower.objective_value == pytest.approx(upper.objective_value, abs=1e-9)


def test_bounds_can_be_given():
    result = optimise_means(table_3_3(), bounds={"x": (9.0, 10.0)})
    assert optimum(result) == pytest.approx(10.0, abs=1e-6)
