"""Reference case R8 (thesis Tables 3.8, 3.9 and Fig 3.27): ranking every Inspection placement for four Features.

The Features are made in the order f1, f2, f3, f4, and each of the 2^3 = 8 Sequences is optimised under the
per_feature scheme. A Stage's Processing and Rework Costs add up over its Features, and its Scrap Cost is
cumulative, the Scrap Costs of every Feature made so far (thesis p. 109, A6). Inspection Cost is 0.5 per
Stage plus 0.5 per Feature inspected.

The thesis column is Table 3.9, with I and E(PR) − I corrected for Seqs 6–8 (D10). Seqs 6–8 come out up to
2 units lower in the 4th decimal: each has a Stage of 3 or 4 Features, where the thesis's Eq 3.59
undercounts scrap (ADR 0001).

Run from manufacturing_oms/ with:  uv run python examples/sequence_search_tables_3_8_3_9.py
"""

from oms import CostTable, Feature, InspectionCost, MultivariateNormal, ReworkSide, Stage, search_sequences

TABLE_3_8 = {  # Feature: (PC, RC, SC, L, U), σ = 1
    "f1": (25.0, 15.0, 10.0, 8.0, 12.0),
    "f2": (20.0, 12.0, 17.0, 13.0, 17.0),
    "f3": (12.0, 8.0, 5.0, 10.0, 14.0),
    "f4": (15.0, 10.0, 12.0, 7.0, 11.0),
}
FEATURES = tuple(Feature(n, lower=L, upper=U, rework_side=ReworkSide.UPPER) for n, (*_, L, U) in TABLE_3_8.items())


def table_3_8_stage(features, upstream):
    names = [f.name for f in features]
    stage_costs = CostTable.additive(
        processing=sum(TABLE_3_8[n][0] for n in names),
        rework_per_feature={n: TABLE_3_8[n][1] for n in names},
        scrap_per_feature={n: TABLE_3_8[n][2] for n in names},
    )
    upstream_scrap = sum(TABLE_3_8[f.name][2] for f in upstream)
    return Stage(
        features=features,
        variation=MultivariateNormal([1.0] * len(features)),
        costs=CostTable(
            processing=stage_costs.processing,
            rework=stage_costs.rework,
            scrap={state: cost + upstream_scrap for state, cost in stage_costs.scrap.items()},
        ),
        inspection=InspectionCost(per_stage=0.5, per_feature=0.5),
    )


# Fig 3.27's numbering, and Table 3.9's E(PR) and (corrected) E(PR) − I.
THESIS = {
    (("f1",), ("f2",), ("f3",), ("f4",)): (1, 41.7523, 37.7523),
    (("f1", "f2"), ("f3",), ("f4",)): (2, 41.4665, 37.9665),
    (("f1",), ("f2", "f3"), ("f4",)): (3, 41.6588, 38.1588),
    (("f1",), ("f2",), ("f3", "f4")): (4, 41.6501, 38.1501),
    (("f1", "f2"), ("f3", "f4")): (5, 41.3642, 38.3642),
    (("f1",), ("f2", "f3", "f4")): (6, 41.4215, 38.4215),
    (("f1", "f2", "f3"), ("f4",)): (7, 41.2628, 38.2628),
    (("f1", "f2", "f3", "f4"),): (8, 40.8657, 38.3657),
}

results = search_sequences(FEATURES, table_3_8_stage, selling_price=120.0, scheme="per_feature")
print(f"{'Seq':>3}  {'Stages':<24} {'Optimal means':<34} {'E(PR)':>8} {'I':>4} {'E(PR)-I':>8}  Rank 1  Rank 2   thesis E(PR), E(PR)-I")
for r in results:
    number, printed, printed_after = THESIS[r.stage_features]
    stages = " ".join("{" + ",".join(n[1:] for n in g) + "}" for g in r.stage_features)
    means = [mu for m in r.optimisation.means for mu in m.by_state[frozenset()].values()]
    print(f"{number:>3}  {stages:<24} [{', '.join(f'{mu:.3f}' for mu in means)}] {r.expected_profit:8.4f} "
          f"{r.inspection_cost:4.1f} {r.expected_profit_after_inspection:8.4f}  {r.rank:>6}  {r.rank_after_inspection:>6}"
          f"   {printed:.4f}, {printed_after:.4f}")
