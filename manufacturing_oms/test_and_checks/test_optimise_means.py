"""Optimising the Mean Settings of a Sequence under the per_feature scheme (spec §5.4): R3, R4 and R5 optima."""

from dataclasses import replace

import pytest

from oms import CostTable, Feature, InspectionCost, MultivariateNormal, ReworkSide, Sequence, Stage, optimise_means

I = frozenset()
A = frozenset({"a"})
B = frozenset({"b"})
AB = frozenset({"a", "b"})
SELLING_PRICE = 120.0


def feature_a():
    return Feature("a", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER)


def feature_b():
    return Feature("b", lower=13.0, upper=17.0, rework_side=ReworkSide.UPPER)


def parallel(costs):
    """Thesis Tables 3.1 and 3.7: one Stage making both Features, σ = 1, independent."""
    stage = Stage(features=(feature_a(), feature_b()), variation=MultivariateNormal([1.0, 1.0]), costs=costs)
    return Sequence(stages=(stage,), selling_price=SELLING_PRICE)


def table_3_1():
    return parallel(
        CostTable(processing=45.0, rework={A: 15.0, B: 12.0, AB: 20.0}, scrap={I: 8.0, A: 9.0, B: 11.0, AB: 14.0})
    )


def table_3_7():
    return parallel(
        CostTable.additive(
            processing=45.0, rework_per_feature={"a": 15.0, "b": 12.0}, scrap_per_feature={"a": 10.0, "b": 17.0}
        )
    )


def table_3_5():
    """Thesis Table 3.5: two Serial Stages, PC = [25, 20], RC = [15, 12], cumulative SC = [10, 27] (D4)."""

    def stage(feature, processing, rework, scrap):
        x = frozenset({feature.name})
        return Stage(
            features=(feature,),
            variation=MultivariateNormal([1.0]),
            costs=CostTable(processing=processing, rework={x: rework}, scrap={I: scrap, x: scrap}),
        )

    return Sequence(
        stages=(stage(feature_a(), 25.0, 15.0, 10.0), stage(feature_b(), 20.0, 12.0, 27.0)),
        selling_price=SELLING_PRICE,
    )


def optimum(result):
    """The per_feature Mean Settings, read from each Stage's Initial State."""
    return [mu for means in result.means for mu in means.by_state[I].values()]


def test_r5_serial_expected_profit_optimum():
    result = optimise_means(table_3_5(), "per_feature")
    assert optimum(result) == pytest.approx([10.466, 15.591], abs=5e-4)  # printed precision
    assert round(result.objective_value, 2) == 71.41
    assert result.objective_value == result.breakdown.expected_profit


def test_r3_parallel_expected_profit_optimum():
    result = optimise_means(table_3_1(), "per_feature")
    assert optimum(result) == pytest.approx([10.5115, 15.5651], abs=5e-5)  # printed precision
    assert round(result.objective_value, 4) == 71.4287


class TestR4:
    """Thesis Table 3.7: additive Rework Costs, Scrap Cost 10 + 17 = 27 from every state."""

    def test_expected_profit_optimum(self):
        result = optimise_means(table_3_7(), "per_feature")
        assert optimum(result) == pytest.approx([10.537, 15.590], abs=5e-4)  # printed precision
        assert round(result.objective_value, 2) == 71.17

    def test_minimum_production_cost(self):
        # U2: Processing + Scrap + Rework Cost per part started.
        result = optimise_means(table_3_7(), "per_feature", objective="production_cost")
        assert optimum(result) == pytest.approx([10.128, 15.181], abs=5e-4)  # printed precision
        assert round(result.objective_value, 3) == 46.753
        assert result.objective_value == result.breakdown.production_cost


def test_inspection_cost_does_not_move_the_optimum():
    plain = table_3_5()
    inspected = Sequence(
        stages=tuple(replace(s, inspection=InspectionCost(0.5, 0.5)) for s in plain.stages),
        selling_price=plain.selling_price,
    )
    with_inspection = optimise_means(inspected, "per_feature")
    assert optimum(with_inspection) == optimum(optimise_means(plain, "per_feature"))
    assert with_inspection.breakdown.expected_profit_after_inspection == pytest.approx(
        with_inspection.objective_value - 2.0
    )


def test_result_records_how_it_was_found():
    result = optimise_means(table_3_5(), "per_feature", seed=3, n_starts=4)
    assert result.method == "L-BFGS-B"
    assert result.scheme == "per_feature"
    assert result.tol == 1e-9
    assert result.seed == 3
    assert result.n_starts == 4
    assert result.n_evaluations > 0
    assert result.bounds == {"a": (5.0, 15.0), "b": (10.0, 20.0)}  # default [L − 3σ, U + 3σ]


def test_same_seed_gives_identical_results():
    first = optimise_means(table_3_1(), "per_feature", seed=7, n_starts=3)
    second = optimise_means(table_3_1(), "per_feature", seed=7, n_starts=3)
    assert optimum(first) == optimum(second)
    assert first.objective_value == second.objective_value
    assert first.n_evaluations == second.n_evaluations


def test_bounds_can_be_given_per_feature():
    result = optimise_means(table_3_5(), "per_feature", bounds={"a": (9.0, 10.0), "b": (15.0, 16.0)})
    assert optimum(result)[0] == pytest.approx(10.0, abs=1e-6)
    assert 15.0 <= optimum(result)[1] <= 16.0


def test_bounds_must_name_every_feature():
    with pytest.raises(ValueError):
        optimise_means(table_3_5(), "per_feature", bounds={"a": (9.0, 10.0)})


class TestMonteCarloObjective:
    """Four correlated Features make the Initial State's boxes seeded QMC (ADR 0003), so the objective is noisy
    in the means and bounded Nelder–Mead is chosen. Only `a` is reworkable, keeping the run short."""

    NAMES = ("a", "b", "c", "d")

    def sequence(self):
        features = tuple(
            Feature(n, lower=-2.0, upper=2.0, rework_side=ReworkSide.UPPER if n == "a" else ReworkSide.NONE)
            for n in self.NAMES
        )
        costs = CostTable.additive(
            processing=10.0, rework_per_feature={"a": 5.0}, scrap_per_feature=dict.fromkeys(self.NAMES, 5.0)
        )
        stage = Stage(features, MultivariateNormal([1.0] * 4, corr=0.3), costs)
        return Sequence(stages=(stage,), selling_price=100.0)

    def optimise(self, **kwargs):
        bounds = dict.fromkeys(self.NAMES, (-0.5, 0.5))
        return optimise_means(self.sequence(), "per_feature", bounds=bounds, n_starts=1, tol=1e-2, **kwargs)

    def test_nelder_mead_is_chosen_and_the_same_seed_reproduces_the_result(self):
        first = self.optimise(seed=5)
        assert "monte_carlo" in first.breakdown.stages[0].methods
        assert first.method == "Nelder-Mead"
        second = self.optimise(seed=5)
        assert optimum(first) == optimum(second)
        assert first.objective_value == second.objective_value


def test_method_can_be_chosen():
    result = optimise_means(table_3_5(), "per_feature", method="Nelder-Mead", n_starts=2)
    assert result.method == "Nelder-Mead"
    assert optimum(result) == pytest.approx([10.466, 15.591], abs=5e-4)


def test_unknown_scheme_is_rejected():
    with pytest.raises(ValueError):
        optimise_means(table_3_5(), "per_state")  # type: ignore[arg-type]
