"""Reference case R9 (thesis Tables 4.1 and 4.3): the connecting rod, Gaussian copula with a t marginal.

Units are cm (D6). x₁ is Normal (σ = 0.1362); x₂ is t location-scale (scale 0.0527, ν = 2.2522), so its
tails are much heavier than a Normal's. A Gaussian copula with ρ = 0.7052 joins them. Both Features rework
below L and scrap above U. Mean Settings are per Rework Group Size.

Run from manufacturing_oms/ with:  uv run python examples/connecting_rod_copula_table_4_3.py
"""

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
X1, X2, X12 = frozenset({"x1"}), frozenset({"x2"}), frozenset({"x1", "x2"})

stage = Stage(
    features=(
        Feature("x1", lower=6.9, upper=7.1, rework_side=ReworkSide.LOWER),
        Feature("x2", lower=3.925, upper=4.075, rework_side=ReworkSide.LOWER),
    ),
    variation=GaussianCopula([norm(0.0, 0.1362), t(2.2522, 0.0, 0.0527)], 0.7052),
    costs=CostTable(processing=20.0, rework={X1: 5.0, X2: 5.0, X12: 10.0}, scrap={s: 50.0 for s in (I, X1, X2, X12)}),
)
sequence = Sequence(stages=(stage,), selling_price=100.0)


def thesis_order(means):
    """Table 4.3's order: both Features reworked together (and I), then each reworked alone."""
    return [means.by_state[I]["x1"], means.by_state[I]["x2"], means.by_state[X1]["x1"], means.by_state[X2]["x2"]]


printed = MeanSettings.per_group_size(stage, {2: {"x1": 6.8737, "x2": 3.9514}, 1: {"x1": 6.8441, "x2": 3.9486}})
at_printed = evaluate_sequence(sequence, [printed])
print(f"At Table 4.3's means:  E(PR) {at_printed.expected_profit:.4f}   (thesis: 44.47)")

result = optimise_means(sequence, "per_group_size")
mu = thesis_order(result.means[0])
stage_result = result.breakdown.stages[0]
print(f"per_group_size optimum: E(PR) {result.objective_value:.4f} @ [{', '.join(f'{m:.4f}' for m in mu)}]")
print(f"  f_C {stage_result.final_conformance:.4f}, Scrap Cost {stage_result.expected_scrap_cost:.4f}, "
      f"Rework Cost {stage_result.expected_rework_cost:.4f}")
print(f"  distance from Table 4.3: [{', '.join(f'{m - p:+.5f}' for m, p in zip(mu, thesis_order(printed)))}]")
