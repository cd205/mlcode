"""Tying schemes compared on thesis Tables 3.10, 3.11 and 3.13 (R6, R7): per_feature, per_group_size, per_state."""

import pytest

from oms import CostTable, Feature, MultivariateNormal, ReworkSide, Sequence, Stage, optimise_means
from oms.optimisation.tying import Tying

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


def stage_of(n_features, none_side=(), prefix="x"):
    """N Features, those named in `none_side` never reworked; costs are irrelevant to the layout."""
    names = [f"{prefix}{i}" for i in range(1, n_features + 1)]
    features = tuple(
        Feature(n, lower=4.0, upper=6.0, rework_side=ReworkSide.NONE if n in none_side else ReworkSide.UPPER)
        for n in names
    )
    reworkable = [f.name for f in features if f.reworkable]
    return Stage(
        features=features,
        variation=MultivariateNormal([2.0] * n_features),
        costs=CostTable.additive(
            processing=1.0,
            rework_per_feature={n: 1.0 for n in reworkable},
            scrap_per_feature={n: 1.0 for n in names},
        ),
    )


@pytest.mark.parametrize("n_features, count", [(1, 2), (2, 6), (3, 15), (4, 36)])
def test_per_state_has_n_times_2_to_the_n_minus_1_plus_n_parameters(n_features, count):
    sequence = Sequence(stages=(stage_of(n_features),), selling_price=400.0)
    assert len(Tying(sequence, "per_state").parameter_features) == count


def test_per_state_parameters_with_a_feature_never_reworked():
    # x3 is never reworked: I has 3 means, then {x1}, {x2} one each and {x1, x2} two.
    sequence = Sequence(stages=(stage_of(3, none_side=("x3",)),), selling_price=400.0)
    assert Tying(sequence, "per_state").parameter_features == ("x1", "x2", "x3", "x1", "x2", "x1", "x2")


def test_per_state_expands_one_mean_per_feature_per_state_stage_by_stage():
    sequence = Sequence(stages=(table_3_10(0.0).stages[0], stage_of(1, prefix="y")), selling_price=400.0)
    first, second = Tying(sequence, "per_state").expand([1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0])
    assert first.by_state == {I: {"x1": 1.0, "x2": 2.0}, X1: {"x1": 3.0}, X2: {"x2": 4.0}, X12: {"x1": 5.0, "x2": 6.0}}
    assert second.by_state == {I: {"y1": 7.0}, frozenset({"y1"}): {"y1": 8.0}}
    first.check_against(sequence.stages[0])
    second.check_against(sequence.stages[1])


def test_per_state_nests_the_other_schemes_on_r6():
    per_feature = optimise_means(table_3_10(0.0), "per_feature")
    per_group_size = optimise_means(table_3_10(0.0), "per_group_size")
    per_state = optimise_means(table_3_10(0.0), "per_state")
    assert per_state.scheme == "per_state"
    # Each scheme's means are a special case of the next, so a finer scheme can only do as well or better.
    # On R6 I and {x1, x2} process the same Features with the same Scrap Cost and successors (RC_{x1,x2} is
    # paid on entering), so per_state's optimum is per_group_size's and the two agree only to rounding.
    assert per_state.objective_value >= per_group_size.objective_value - 1e-9
    assert per_group_size.objective_value >= per_feature.objective_value
    means = per_state.means[0]
    assert dict(means.by_state[X12]) == pytest.approx(dict(means.by_state[I]), abs=1e-4)
