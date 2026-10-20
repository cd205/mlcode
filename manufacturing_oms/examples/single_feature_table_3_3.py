"""Reference case R2 (thesis Table 3.3 / Fig 3.24): one Feature, Rework Side above U.

Run from manufacturing_oms/ with:  uv run python examples/single_feature_table_3_3.py
"""

from oms import CostTable, Feature, MultivariateNormal, ReworkSide, Stage, optimise_means

INITIAL = frozenset()
REWORK = frozenset({"x"})
SELLING_PRICE = 120.0

stage = Stage(
    features=(Feature("x", lower=8.0, upper=12.0, rework_side=ReworkSide.UPPER),),
    variation=MultivariateNormal([1.0]),
    costs=CostTable(processing=25.0, rework={REWORK: 10.0}, scrap={INITIAL: 15.0, REWORK: 15.0}),
)


def report(title, result, printed):
    r = result.stage_result
    print(f"{title}  (thesis: mu = {printed})")
    print(f"  Mean Setting          {result.means.by_state[INITIAL]['x']:.4f}")
    print(f"  Expected Profit       {r.expected_profit(SELLING_PRICE):.4f}")
    print(f"  Final Conformance     {r.final_conformance:.4f}")
    print(f"  Processing Cost       {r.processing_cost:.4f}")
    print(f"  Scrap Cost            {r.expected_scrap_cost:.4f}")
    print(f"  Rework Cost           {r.expected_rework_cost:.4f}")
    print(f"  Production cost       {r.production_cost:.4f}   (Processing + Scrap + Rework, U2)")
    print(f"  [{result.method}, {result.n_starts} starts, seed {result.seed}, {result.n_evaluations} evaluations]")
    print()


report("Maximum Expected Profit", optimise_means(stage, SELLING_PRICE), "10.61")
report("Minimum production cost", optimise_means(stage, SELLING_PRICE, objective="production_cost"), "10.09")
