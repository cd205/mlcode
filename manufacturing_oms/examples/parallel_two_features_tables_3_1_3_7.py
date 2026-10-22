"""Reference cases R3 and R4 (thesis Tables 3.1 and 3.7): two Features in one Parallel Stage, Rework Side above U.

Evaluates each at the printed Mean Settings, then optimises the per_feature Mean Settings from scratch.
Run from manufacturing_oms/ with:  uv run python examples/parallel_two_features_tables_3_1_3_7.py
"""

from oms import (
    CostTable,
    Feature,
    MeanSettings,
    MultivariateNormal,
    ReworkSide,
    Sequence,
    Stage,
    evaluate_stage,
    optimise_means,
)

SELLING_PRICE = 120.0
I, A, B, AB = frozenset(), frozenset({"a"}), frozenset({"b"}), frozenset({"a", "b"})

features = (
    Feature("a", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),
    Feature("b", lower=13.0, upper=17.0, rework_side=ReworkSide.UPPER),
)
variation = MultivariateNormal([1.0, 1.0])  # independent, σ = 1

table_3_1 = Stage(
    features,
    variation,
    CostTable(processing=45.0, rework={A: 15.0, B: 12.0, AB: 20.0}, scrap={I: 8.0, A: 9.0, B: 11.0, AB: 14.0}),
)
table_3_7 = Stage(
    features,
    variation,
    # Scrap Cost 10 + 17 = 27 from every state: a scrapped part loses the value of both Features.
    CostTable.additive(
        processing=45.0, rework_per_feature={"a": 15.0, "b": 12.0}, scrap_per_feature={"a": 10.0, "b": 17.0}
    ),
)


def report(title, stage, mu, printed):
    r = evaluate_stage(stage, MeanSettings.per_feature(stage, mu))
    print(f"{title} at mu = [{mu['a']}, {mu['b']}]  (thesis: {printed})")
    print(f"  Expected Profit       {r.expected_profit(SELLING_PRICE):.4f}")
    print(f"  Final Conformance     {r.final_conformance:.4f}")
    print(f"  Production cost       {r.production_cost:.4f}   (Processing + Scrap + Rework, U2)")
    print("  Expected visits       " + ", ".join(f"{sorted(s) or 'I'}: {m:.4f}" for s, m in r.visits.items()))
    print(f"  [{', '.join(sorted(r.methods))}; error bound {r.abs_error:.1e}]")
    print()


report("R3, Table 3.1", table_3_1, {"a": 10.5115, "b": 15.5651}, "E(PR) = 71.4287")
report("R4, Table 3.7, profit optimum", table_3_7, {"a": 10.537, "b": 15.590}, "E(PR) = 71.17")
report("R4, Table 3.7, cost minimum", table_3_7, {"a": 10.128, "b": 15.181}, "production cost = 46.753")


def report_optimum(title, stage, printed, objective="expected_profit"):
    result = optimise_means(Sequence(stages=(stage,), selling_price=SELLING_PRICE), objective=objective)
    mu = result.means[0].by_state[I]
    b = result.breakdown
    print(f"{title}  (thesis: {printed})")
    print(f"  Mean Settings         [{mu['a']:.4f}, {mu['b']:.4f}]")
    print(f"  Expected Profit       {b.expected_profit:.4f}")
    print(f"  Production cost       {b.production_cost:.4f}")
    print(f"  [{result.method}, {result.n_starts} starts, seed {result.seed}, {result.n_evaluations} evaluations]")
    print()


report_optimum("R3, Table 3.1, optimised", table_3_1, "71.4287 @ [10.5115, 15.5651]")
report_optimum("R4, Table 3.7, optimised", table_3_7, "71.17 @ [10.537, 15.590]")
report_optimum("R4, Table 3.7, cost minimised", table_3_7, "46.753 @ [10.128, 15.181]", objective="production_cost")
