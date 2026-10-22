"""Reference case R9: the connecting rod of thesis Tables 4.1 and 4.3, a Gaussian copula with a t marginal (D6)."""

import warnings

import pytest
from scipy.stats import norm, t

from oms import (
    CostTable,
    Feature,
    GaussianCopula,
    MeanSettings,
    ReworkSide,
    Sequence,
    Stage,
    evaluate_sequence,
    optimise_means,
)

I = frozenset()
X1 = frozenset({"x1"})
X2 = frozenset({"x2"})
X12 = frozenset({"x1", "x2"})

# Table 4.3's means in cm (D6), thesis order: both Features reworked together (and I), then each alone.
PRINTED_MEANS = {2: {"x1": 6.8737, "x2": 3.9514}, 1: {"x1": 6.8441, "x2": 3.9486}}
PRINTED_PROFIT = 44.47


def connecting_rod():
    """Table 4.1 limits in cm, x₁ Normal, x₂ t location-scale, Gaussian copula ρ = 0.7052, rework below L (D6)."""
    stage = Stage(
        features=(
            Feature("x1", lower=6.9, upper=7.1, rework_side=ReworkSide.LOWER),
            Feature("x2", lower=3.925, upper=4.075, rework_side=ReworkSide.LOWER),
        ),
        variation=GaussianCopula([norm(0.0, 0.1362), t(2.2522, 0.0, 0.0527)], 0.7052),
        costs=CostTable(
            processing=20.0,
            rework={X1: 5.0, X2: 5.0, X12: 10.0},
            scrap={I: 50.0, X1: 50.0, X2: 50.0, X12: 50.0},
        ),
    )
    return Sequence(stages=(stage,), selling_price=100.0)


def test_expected_profit_at_the_printed_means():
    sequence = connecting_rod()
    means = MeanSettings.per_group_size(sequence.stages[0], PRINTED_MEANS)
    breakdown = evaluate_sequence(sequence, [means])
    # 44.4708 by the independent precheck (docs/prechecks/r9_conrod_table_4_3.py).
    assert round(breakdown.expected_profit, 2) == PRINTED_PROFIT
    assert breakdown.expected_profit == pytest.approx(44.4708, abs=5e-5)


def test_per_group_size_optimum_is_logged_against_table_4_3():
    """Logged, not asserted, as Table 4.3 was suspect (D6); docs/discrepancies.md records that it is the optimum."""
    result = optimise_means(connecting_rod(), "per_group_size")
    means = result.means[0]
    optimised = {2: dict(means.by_state[I]), 1: {"x1": means.by_state[X1]["x1"], "x2": means.by_state[X2]["x2"]}}
    distances = ", ".join(
        f"{name}@{size} {optimised[size][name] - PRINTED_MEANS[size][name]:+.1e}"
        for size in (2, 1)
        for name in ("x1", "x2")
    )
    warnings.warn(f"D6: R9 per_group_size optimum E(PR) {result.objective_value:.5f}; "
                  f"distance from Table 4.3 means (cm): {distances}", stacklevel=1)
    assert result.success
    assert result.objective_value >= PRINTED_PROFIT - 5e-3  # the optimum can't be worse than the printed point
