"""Reference cases R6 and R7 (thesis Tables 3.10, 3.11 and 3.13): per_feature vs per_group_size vs per_state.

Two Features, Rework Side above U, σ = 2 and SP = 400 as the thesis code ran them (D11). The thesis's
"production cost" here is Scrap + Rework Cost, without the Processing Cost (D12). per_state ties with
per_group_size: I and {x1, x2} process the same Features with the same Scrap Cost and successors, so their
optimal means coincide.

Run from manufacturing_oms/ with:  uv run python examples/tying_schemes_tables_3_11_3_13.py
"""

from oms import CostTable, Feature, MultivariateNormal, ReworkSide, Sequence, Stage, optimise_means

I = frozenset()
X1, X2, X12 = frozenset({"x1"}), frozenset({"x2"}), frozenset({"x1", "x2"})


def table_3_10(rho):
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


PRINTED = {
    0.0: ("40.87 @ 6.85", "41.66 @ [6.75, 6.75, 7.02, 7.02]"),
    0.8: ("56.4038 @ 6.65", "58.3309 @ [6.52, 6.52, 7.02, 7.02]"),
    -0.8: ("45.11 @ 6.80", "47.10 @ [6.57, 6.57, 7.02, 7.02]"),
}

for rho, printed in PRINTED.items():
    print(f"rho = {rho:+.1f}")
    for scheme, thesis in zip(("per_feature", "per_group_size", "per_state"), (*printed, "none, new scheme")):
        result = optimise_means(table_3_10(rho), scheme)
        means, stage = result.means[0], result.breakdown.stages[0]
        # Thesis order (μ₁,₁, μ₁,₂, μ₂,₁, μ₂,₂): the means in I (and {x1, x2}, equal on R6), then in {x1} and {x2}.
        mu = [means.by_state[I]["x1"], means.by_state[I]["x2"], means.by_state[X1]["x1"], means.by_state[X2]["x2"]]
        print(f"  {scheme:<15} E(PR) {result.objective_value:.4f} @ [{', '.join(f'{m:.3f}' for m in mu)}]")
        print(f"  {'':<15} f_C {stage.final_conformance:.4f}, Scrap + Rework Cost "
              f"{stage.expected_scrap_cost + stage.expected_rework_cost:.2f}   (thesis: {thesis})")
    print()
