"""Optimising one Feature's Mean Setting (spec §5.4): reference case R2, thesis Table 3.3 / Fig 3.24."""

import pytest

from oms import CostTable, Feature, MultivariateNormal, ReworkSide, Stage, optimise_means

I = frozenset()
X = frozenset({"x"})
SELLING_PRICE = 120.0


def table_3_3(side=ReworkSide.UPPER, lower=8.0, upper=12.0):
    return Stage(
        features=(Feature("x", lower=lower, upper=upper, rework_side=side),),
        variation=MultivariateNormal([1.0]),
        costs=CostTable(processing=25.0, rework={X: 10.0}, scrap={I: 15.0, X: 15.0}),
    )


def optimum(result):
    return result.means.by_state[I]["x"]


def test_r2_expected_profit_optimum():
    result = optimise_means(table_3_3(), SELLING_PRICE)
    assert abs(optimum(result) - 10.61) <= 0.005  # printed precision
    assert optimum(result) == pytest.approx(10.6144, abs=1e-3)  # pre-check value
    assert result.objective_value == pytest.approx(result.stage_result.expected_profit(SELLING_PRICE))


def test_r2_minimum_production_cost():
    # U2: production cost is Processing + Scrap + Rework Cost per part started.
    result = optimise_means(table_3_3(), SELLING_PRICE, objective="production_cost")
    assert abs(optimum(result) - 10.09) <= 0.005  # printed precision
    assert optimum(result) == pytest.approx(10.0875, abs=1e-3)  # pre-check value
    assert result.objective_value == pytest.approx(result.stage_result.production_cost)


def test_optimum_uses_the_mean_in_every_state():
    result = optimise_means(table_3_3(), SELLING_PRICE)
    assert result.means.by_state[X]["x"] == optimum(result)


def test_mirrored_stage_has_the_mirrored_optimum():
    upper = optimise_means(table_3_3(), SELLING_PRICE)
    lower = optimise_means(table_3_3(ReworkSide.LOWER, -12.0, -8.0), SELLING_PRICE)
    assert optimum(lower) == pytest.approx(-optimum(upper), abs=1e-5)
    assert lower.objective_value == pytest.approx(upper.objective_value, abs=1e-9)


def test_result_records_how_it_was_found():
    result = optimise_means(table_3_3(), SELLING_PRICE, seed=3, n_starts=4)
    assert result.method == "L-BFGS-B"
    assert result.scheme == "per_feature"
    assert result.seed == 3
    assert result.n_starts == 4
    assert result.n_evaluations > 0
    assert result.bounds == {"x": (5.0, 15.0)}  # default [L − 3σ, U + 3σ]


def test_same_seed_gives_identical_results():
    first = optimise_means(table_3_3(), SELLING_PRICE, seed=7)
    second = optimise_means(table_3_3(), SELLING_PRICE, seed=7)
    assert optimum(first) == optimum(second)
    assert first.objective_value == second.objective_value


def test_bounds_can_be_given():
    result = optimise_means(table_3_3(), SELLING_PRICE, bounds={"x": (9.0, 10.0)})
    assert optimum(result) == pytest.approx(10.0, abs=1e-6)


def test_unknown_scheme_is_rejected():
    with pytest.raises(ValueError):
        optimise_means(table_3_3(), SELLING_PRICE, scheme="per_state")  # type: ignore[arg-type]
