"""Reference case R5 (thesis Table 3.5): two one-Feature Stages in series, Rework Side above U.

Evaluates the Sequence at the printed Mean Settings, with and without an Inspection Cost of 0.5 per
Inspection plus 0.5 per Feature inspected (the thesis Table 3.8 convention), then optimises both Mean Settings.
Run from manufacturing_oms/ with:  uv run python examples/serial_two_stages_table_3_5.py
"""

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
    optimise_means,
)

INITIAL = frozenset()


def one_feature_stage(name, lower, upper, processing, rework, scrap, inspection):
    x = frozenset({name})
    return Stage(
        features=(Feature(name, lower=lower, upper=upper, rework_side=ReworkSide.UPPER),),
        variation=MultivariateNormal([1.0]),
        costs=CostTable(processing=processing, rework={x: rework}, scrap={INITIAL: scrap, x: scrap}),
        inspection=inspection,
    )


def table_3_5(inspection):
    # Scrap Costs are cumulative: 27 = 10 + 17 for a part scrapped at the second Stage (D4).
    return Sequence(
        stages=(
            one_feature_stage("a", 8.0, 12.0, processing=25.0, rework=15.0, scrap=10.0, inspection=inspection),
            one_feature_stage("b", 13.0, 17.0, processing=20.0, rework=12.0, scrap=27.0, inspection=inspection),
        ),
        selling_price=120.0,
    )


def report(title, sequence, mu):
    means = [MeanSettings.per_feature(stage, {stage.feature_names[0]: m}) for stage, m in zip(sequence.stages, mu)]
    r = evaluate_sequence(sequence, means)
    print(f"{title} at mu = {list(mu)}")
    print(f"  Expected Profit            {r.expected_profit:.4f}   (thesis: 71.41)")
    print(f"  Expected Profit - I        {r.expected_profit_after_inspection:.4f}")
    print(f"  Revenue                    {r.revenue:.4f}")
    print(f"  Final Conformance          {r.final_conformance:.4f}")
    print("  Stage   reach   f_C     Processing  Scrap    Rework   Inspection   (per part started)")
    for i, (stage, reach) in enumerate(zip(r.stages, r.reach_probabilities)):
        print(
            f"  {i + 1:<7} {reach:.4f}  {stage.final_conformance:.4f}  {r.processing_costs[i]:<11.4f} "
            f"{r.scrap_costs[i]:<8.4f} {r.rework_costs[i]:<8.4f} {r.inspection_costs[i]:.4f}"
        )
    print()


report("R5, Table 3.5, no Inspection Cost", table_3_5(InspectionCost()), (10.466, 15.591))
report("R5 with Inspection Cost 0.5 + 0.5/Feature", table_3_5(InspectionCost(0.5, 0.5)), (10.466, 15.591))

inspected = table_3_5(InspectionCost(0.5, 0.5))
result = optimise_means(inspected)
optimum = tuple(m.by_state[INITIAL][s.feature_names[0]] for m, s in zip(result.means, inspected.stages))
print(f"Optimised per_feature Mean Settings [{optimum[0]:.4f}, {optimum[1]:.4f}]  (thesis: [10.466, 15.591])")
print(f"  [{result.method}, {result.n_starts} starts, seed {result.seed}, {result.n_evaluations} evaluations]")
print()
report("R5 at the optimum", inspected, tuple(round(m, 4) for m in optimum))
