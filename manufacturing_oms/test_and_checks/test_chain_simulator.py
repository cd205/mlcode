"""The engine against an independent Monte Carlo simulation of parts flowing through Stages (spec §6, issue #12).

`chain_simulator` draws every part's values and follows it through Inspection, rework and scrap using only the
assumptions A1–A7. It never touches the engine's Markov code, so agreement checks the absorbing-chain algebra.
Each check allows 4 standard errors at a fixed seed.
"""

from itertools import combinations

import pytest

from chain_simulator import simulate_sequence
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
from oracles import stage_cost_fun
from test_connecting_rod_copula import PRINTED_MEANS, connecting_rod

I = frozenset()
N_PARTS = 200_000
SEED = 20261022


def assert_agrees(estimate, exact, se=None):
    """|estimate − exact| ≤ 4 standard errors, the sample standard error unless `se` is given."""
    se = estimate.standard_error if se is None else se
    assert abs(estimate.mean - exact) <= 4 * se, f"{estimate.mean} vs {exact} (se {se:.3g})"


def assert_visits_agree(estimate, exact, n):
    """As `assert_agrees`, for the expected visits m_{I,j} to a state.

    A rarely visited state may see no visits at all, which gives a sample standard error of 0. The floor
    √(m / n) is the standard error of a Poisson visit count with the engine's mean, under the hypothesis
    being tested. The Initial State is visited exactly once, so both sides are exactly 1 there.
    """
    assert_agrees(estimate, exact, se=max(estimate.standard_error, (exact / n) ** 0.5))


def assert_sequence_agrees(sequence, means, n_parts=N_PARTS):
    exact = evaluate_sequence(sequence, means)
    simulated = simulate_sequence(sequence, means, n_parts=n_parts, seed=SEED)
    assert_agrees(simulated.expected_profit, exact.expected_profit)
    assert_agrees(simulated.final_conformance, exact.final_conformance)
    for stage, sim_stage in zip(exact.stages, simulated.stages):
        assert_agrees(sim_stage.final_conformance, stage.final_conformance)
        assert set(sim_stage.visits) == set(stage.visits)  # the simulator enumerates its own states
        for state, m in stage.visits.items():
            assert_visits_agree(sim_stage.visits[state], m, sim_stage.n_entering)
    return simulated


def one_feature_stage(name, lower, upper, processing, rework, scrap):
    x = frozenset({name})
    return Stage(
        features=(Feature(name, lower=lower, upper=upper, rework_side=ReworkSide.UPPER),),
        variation=MultivariateNormal([1.0]),
        costs=CostTable(processing=processing, rework={x: rework}, scrap={I: scrap, x: scrap}),
    )


def per_feature(sequence, *mu):
    """Mean Settings in Feature order across the Sequence's Stages."""
    values = iter(mu)
    return [MeanSettings.per_feature(s, {n: next(values) for n in s.feature_names}) for s in sequence.stages]


def test_r1_one_feature():
    """Thesis Fig 3.12/3.14: μ = 5, σ = 1, [3, 7]. No costs are printed, so R2's are used for E(PR)."""
    sequence = Sequence((one_feature_stage("x", 3.0, 7.0, 25.0, 10.0, 15.0),), selling_price=120.0)
    assert_sequence_agrees(sequence, per_feature(sequence, 5.0))


def test_detects_the_eq_3_59_scrap_gap_at_three_features():
    """The harness has the power to see a 4e-3 error: ADR 0001's N = 3 case, unit costs, so Scrap Cost = P(scrap).

    The simulation agrees with the engine's exact Σ m_{I,j} p_{j,X} SC_j and rejects Eq 3.59's value (D1).
    """
    MU, sigs, L, U = [6.0, 5.5, 5.0], [2.0, 2.5, 3.0], [3.0] * 3, [7.0] * 3
    names = ["x1", "x2", "x3"]
    upsilon = [frozenset(g) for k in (1, 2, 3) for g in combinations(names, k)]
    stage = Stage(
        features=tuple(Feature(n, lower=lo, upper=hi, rework_side=ReworkSide.UPPER) for n, lo, hi in zip(names, L, U)),
        variation=MultivariateNormal(sigs),
        costs=CostTable(processing=0.0, rework=dict.fromkeys(upsilon, 1.0), scrap=dict.fromkeys([I, *upsilon], 1.0)),
    )
    sequence = Sequence((stage,), selling_price=0.0)
    means = per_feature(sequence, *MU)
    n_parts = 1_000_000

    simulated = assert_sequence_agrees(sequence, means, n_parts=n_parts).stages[0]
    exact = evaluate_sequence(sequence, means).stages[0]
    _, _, Rwi, Sri = stage_cost_fun(MU, sigs, 0.0, U, L, [1.0] * 7, [1.0] * 8)

    assert_agrees(simulated.expected_scrap_cost, exact.expected_scrap_cost)
    assert_agrees(simulated.expected_rework_cost, exact.expected_rework_cost)
    assert abs(simulated.expected_scrap_cost.mean - Sri) > 4 * simulated.expected_scrap_cost.standard_error


def test_every_rework_side_with_correlation_and_a_mean_per_state():
    """No R-case reworks below L or has a Rework Side of `none`, so this Stage covers them, with distinct means
    in every state and correlated Features, so a draw from the wrong marginal or state shows up."""
    A, B, AB = frozenset("a"), frozenset("b"), frozenset("ab")
    stage = Stage(
        features=(
            Feature("a", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),
            Feature("b", lower=13.0, upper=17.0, rework_side=ReworkSide.LOWER),
            Feature("c", lower=10.0, upper=14.0, rework_side=ReworkSide.NONE),
        ),
        variation=MultivariateNormal([1.0, 1.2, 0.8], [[1.0, 0.5, -0.3], [0.5, 1.0, 0.2], [-0.3, 0.2, 1.0]]),
        costs=CostTable.additive(
            30.0, rework_per_feature={"a": 15.0, "b": 12.0}, scrap_per_feature={"a": 10.0, "b": 17.0, "c": 5.0}
        ),
    )
    means = MeanSettings(
        {
            I: {"a": 10.6, "b": 14.4, "c": 12.0},
            A: {"a": 10.3},
            B: {"b": 14.7},
            AB: {"a": 10.5, "b": 14.5},
        }
    )
    simulated = assert_sequence_agrees(Sequence((stage,), selling_price=120.0), [means])
    assert set(simulated.stages[0].visits) == {I, A, B, AB}  # c never joins a Rework State


# ---- R2–R8 at the printed means ------------------------------------------------------------------------------


def r2():
    """Thesis Table 3.3: U = 12, L = 8, σ = 1, SP = 120, PC = 25, RC = 10, SC = 15."""
    return Sequence((one_feature_stage("x", 8.0, 12.0, 25.0, 10.0, 15.0),), selling_price=120.0)


def table_3_1_features():
    return (
        Feature("a", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),
        Feature("b", lower=13.0, upper=17.0, rework_side=ReworkSide.UPPER),
    )


def r3():
    """Thesis Table 3.1, Eq 3.44: Scrap Cost differs by state."""
    A, B, AB = frozenset("a"), frozenset("b"), frozenset("ab")
    stage = Stage(
        features=table_3_1_features(),
        variation=MultivariateNormal([1.0, 1.0]),
        costs=CostTable(
            processing=45.0, rework={A: 15.0, B: 12.0, AB: 20.0}, scrap={I: 8.0, A: 9.0, B: 11.0, AB: 14.0}
        ),
    )
    return Sequence((stage,), selling_price=120.0)


def r4():
    """Thesis Table 3.7: additive costs, Scrap Cost 27 from every state."""
    stage = Stage(
        features=table_3_1_features(),
        variation=MultivariateNormal([1.0, 1.0]),
        costs=CostTable.additive(
            45.0, rework_per_feature={"a": 15.0, "b": 12.0}, scrap_per_feature={"a": 10.0, "b": 17.0}
        ),
    )
    return Sequence((stage,), selling_price=120.0)


def r5():
    """Thesis Table 3.5: two Serial Stages, cumulative SC = [10, 27] (D4)."""
    return Sequence(
        (one_feature_stage("a", 8.0, 12.0, 25.0, 15.0, 10.0), one_feature_stage("b", 13.0, 17.0, 20.0, 12.0, 27.0)),
        selling_price=120.0,
    )


@pytest.mark.parametrize(
    "sequence, mu",
    [
        pytest.param(r2(), (10.61,), id="R2 profit"),
        pytest.param(r2(), (10.09,), id="R2 min cost"),
        pytest.param(r3(), (10.5115, 15.5651), id="R3"),
        pytest.param(r4(), (10.537, 15.590), id="R4 profit"),
        pytest.param(r4(), (10.128, 15.181), id="R4 min cost"),
        pytest.param(r5(), (10.466, 15.591), id="R5"),
    ],
)
def test_r2_to_r5_per_feature(sequence, mu):
    assert_sequence_agrees(sequence, per_feature(sequence, *mu))


def table_3_10(rho):
    """Thesis Table 3.10 as run for Tables 3.11/3.13: σ = 2, SP = 400 (D11)."""
    X1, X2, X12 = frozenset({"x1"}), frozenset({"x2"}), frozenset({"x1", "x2"})
    stage = Stage(
        features=tuple(Feature(n, lower=4.0, upper=6.0, rework_side=ReworkSide.UPPER) for n in ("x1", "x2")),
        variation=MultivariateNormal([2.0, 2.0], rho),
        costs=CostTable(
            processing=50.0, rework={X1: 25.0, X2: 25.0, X12: 50.0}, scrap=dict.fromkeys([I, X1, X2, X12], 150.0)
        ),
    )
    return Sequence((stage,), selling_price=400.0)


# rho, per_feature μ, per_group_size (dual-Feature μ, single-Feature μ) from Tables 3.11/3.13
R6_R7 = [
    pytest.param(0.0, 6.85, (6.75, 7.02), id="R6"),
    pytest.param(0.8, 6.65, (6.52, 7.02), id="R7 rho=0.8"),
    pytest.param(-0.8, 6.80, (6.57, 7.02), id="R7 rho=-0.8"),
]


@pytest.mark.parametrize("rho, mu, group_means", R6_R7)
def test_r6_r7_per_feature(rho, mu, group_means):
    sequence = table_3_10(rho)
    assert_sequence_agrees(sequence, per_feature(sequence, mu, mu))


@pytest.mark.parametrize("rho, mu, group_means", R6_R7)
def test_r6_r7_per_group_size(rho, mu, group_means):
    """Rework States have their own means here, so this checks the simulator draws each state at its own."""
    sequence = table_3_10(rho)
    dual, single = group_means
    group_size_means = {2: {"x1": dual, "x2": dual}, 1: {"x1": single, "x2": single}}
    means = MeanSettings.per_group_size(sequence.stages[0], group_size_means)
    assert_sequence_agrees(sequence, [means])


TABLE_3_8 = {  # Feature: (PC, RC, SC, L, U), σ = 1
    "f1": (25.0, 15.0, 10.0, 8.0, 12.0),
    "f2": (20.0, 12.0, 17.0, 13.0, 17.0),
    "f3": (12.0, 8.0, 5.0, 10.0, 14.0),
    "f4": (15.0, 10.0, 12.0, 7.0, 11.0),
}


def r8(groups):
    """Thesis Table 3.8 Stages: Processing and Rework Costs add up over the Features; Scrap Cost is cumulative (A6)."""
    stages, made = [], []
    for group in groups:
        features = tuple(
            Feature(n, lower=TABLE_3_8[n][3], upper=TABLE_3_8[n][4], rework_side=ReworkSide.UPPER) for n in group
        )
        costs = CostTable.additive(
            processing=sum(TABLE_3_8[n][0] for n in group),
            rework_per_feature={n: TABLE_3_8[n][1] for n in group},
            scrap_per_feature={n: TABLE_3_8[n][2] for n in group},
        )
        upstream = sum(TABLE_3_8[n][2] for n in made)
        stages.append(
            Stage(
                features=features,
                variation=MultivariateNormal([1.0] * len(group)),
                costs=CostTable(costs.processing, costs.rework, {s: c + upstream for s, c in costs.scrap.items()}),
                inspection=InspectionCost(per_stage=0.5, per_feature=0.5),
            )
        )
        made.extend(group)
    return Sequence(tuple(stages), selling_price=120.0)


# Fig 3.27's Sequences with Table 3.9's printed means [f1, f2, f3, f4]
TABLE_3_9 = [
    pytest.param((("f1",), ("f2",), ("f3",), ("f4",)), [10.389, 15.537, 12.674, 9.660], id="Seq 1"),
    pytest.param((("f1", "f2"), ("f3",), ("f4",)), [10.482, 15.535, 12.667, 9.660], id="Seq 2"),
    pytest.param((("f1",), ("f2", "f3"), ("f4",)), [10.388, 15.570, 12.666, 9.660], id="Seq 3"),
    pytest.param((("f1",), ("f2",), ("f3", "f4")), [10.388, 15.537, 12.711, 9.659], id="Seq 4"),
    pytest.param((("f1", "f2"), ("f3", "f4")), [10.482, 15.535, 12.711, 9.659], id="Seq 5"),
    pytest.param((("f1",), ("f2", "f3", "f4")), [10.388, 15.615, 12.710, 9.657], id="Seq 6"),
    pytest.param((("f1", "f2", "f3"), ("f4",)), [10.516, 15.568, 12.664, 9.660], id="Seq 7"),
    pytest.param((("f1", "f2", "f3", "f4"),), [10.560, 15.613, 12.708, 9.656], id="Seq 8"),
]


@pytest.mark.parametrize("groups, mu", TABLE_3_9)
def test_r8_sequences(groups, mu):
    sequence = r8(groups)
    assert_sequence_agrees(sequence, per_feature(sequence, *mu))


def test_r9_connecting_rod_copula():
    """Non-Gaussian Process Variation: a Normal and a heavy-tailed t Feature joined by a Gaussian copula (D6)."""
    sequence = connecting_rod()
    assert_sequence_agrees(sequence, [MeanSettings.per_group_size(sequence.stages[0], PRINTED_MEANS)])
