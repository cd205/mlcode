"""Tying schemes compared on thesis Tables 3.10, 3.11 and 3.13 (R6, R7): per_feature vs per_group_size."""

import pytest

from oms import CostTable, Feature, MultivariateNormal, ReworkSide, Sequence, Stage, optimise_means

I = frozenset()
X1 = frozenset({"x1"})
X2 = frozenset({"x2"})
X12 = frozenset({"x1", "x2"})


def table_3_10(rho):
    """Thesis Table 3.10 as the code that printed Tables 3.11/3.13 ran it: σ = 2 and SP = 400 (D11)."""
    stage = Stage(
        features=tuple(Feature(n, lower=4.0, upper=6.0, rework_side=ReworkSide.UPPER) for n in ("x1", "x2")),
        variation=MultivariateNormal([2.0, 2.0], rho),
        costs=CostTable(
            processing=50.0,
            rework={X1: 25.0, X2: 25.0, X12: 50.0},
            scrap={I: 150.0, X1: 150.0, X2: 150.0, X12: 150.0},
        ),
    )
    return Sequence(stages=(stage,), selling_price=400.0)


def scrap_plus_rework(result):
    """Tables 3.11/3.13's "production cost" leaves out the Processing Cost (D12)."""
    stage = result.breakdown.stages[0]
    return stage.expected_scrap_cost + stage.expected_rework_cost


# rho, (profit, digits, mu, f_C, Sr + Rw) for per_feature, then for per_group_size as (dual mean, single mean)
CASES = [
    pytest.param(0.0, (40.87, 2, 6.85, 0.5933, 146.44), (41.66, 2, (6.75, 7.02), 0.5935, 145.75), id="R6"),
    pytest.param(
        0.8, (56.4038, 4, 6.65, 0.6166, 140.24), (58.3309, 4, (6.52, 7.02), 0.6181, 138.93), id="R7 rho=0.8"
    ),
    pytest.param(
        -0.8, (45.11, 2, 6.80, 0.5869, 139.65), (47.10, 2, (6.57, 7.02), 0.5842, 136.60), id="R7 rho=-0.8"
    ),
]


@pytest.mark.parametrize("rho, per_feature, per_group_size", CASES)
def test_per_feature_optimum(rho, per_feature, per_group_size):
    profit, digits, mu, f_c, cost = per_feature
    result = optimise_means(table_3_10(rho), "per_feature")
    means = result.means[0]
    assert dict(means.by_state[I]) == pytest.approx({"x1": mu, "x2": mu}, abs=5e-3)  # printed precision
    assert round(result.objective_value, digits) == profit
    assert round(result.breakdown.final_conformance, 4) == f_c
    assert round(scrap_plus_rework(result), 2) == cost


@pytest.mark.parametrize("rho, per_feature, per_group_size", CASES)
def test_per_group_size_optimum(rho, per_feature, per_group_size):
    profit, digits, (dual, single), f_c, cost = per_group_size
    result = optimise_means(table_3_10(rho), "per_group_size")
    means = result.means[0]
    assert result.scheme == "per_group_size"
    # Thesis order (μ₁,₁, μ₁,₂, μ₂,₁, μ₂,₂): both Features in I and {x1, x2}, then in {x1} and {x2}.
    assert dict(means.by_state[I]) == pytest.approx({"x1": dual, "x2": dual}, abs=5e-3)
    assert means.by_state[X12] == means.by_state[I]
    assert dict(means.by_state[X1]) == pytest.approx({"x1": single}, abs=5e-3)
    assert dict(means.by_state[X2]) == pytest.approx({"x2": single}, abs=5e-3)
    assert round(result.objective_value, digits) == profit
    assert round(result.breakdown.final_conformance, 4) == f_c
    assert round(scrap_plus_rework(result), 2) == cost
    # The per_feature means are a special case, so per_group_size can only do as well or better.
    assert result.objective_value >= optimise_means(table_3_10(rho), "per_feature").objective_value
