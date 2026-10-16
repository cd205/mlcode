# Traceability

Each row links a thesis section or equation to the MATLAB that implements it, the Python that will implement it, its tests, and its validation status.

Statuses:
- `planned`: specified, not implemented.
- `implemented`: code exists.
- `verified`: tests pass against a reference.
- `deviates`: verified, with a deliberate discrepancy recorded in [discrepancies.md](discrepancies.md).

| Thesis | Concept | MATLAB entry point | MATLAB deps | Python | Tests | Status |
|---|---|---|---|---|---|---|
| Eq 3.4, 3.36 (pp. 51, 74) | One-Feature rework/conform/scrap probabilities | `Probs_1Var`, `MarkovProcess_1_Var` | `normcdf` | `distributions.MultivariateNormal` (1D), `markov` | R1, R2; `Probs_1Var` oracle | planned |
| Eq 3.19–3.21 (pp. 59–60) | Box probability by inclusion–exclusion | `Probs_nVars` | `mvncdf`, `corr2cov` | `distributions.JointDistribution.box_probability` | property tests; U1 | planned |
| Eq 3.47–3.50 (pp. 85–86) | State enumeration (η, Υ ordering) | `StageCostFun`, `Probs_nVars` | `combinator` | `markov.states` | state-count and ordering tests | planned |
| Eq 3.51–3.57, 3.60–3.63 (pp. 86–91) | S-, D- and J-matrices; transition matrix | `kSMatrix`, `kDMatrix`, `Probs_nVars` | `combinator` | `markov.transition_matrix` (built directly from subset inclusion; S/D/J not reproduced) | `Probs_2Var/3Var`, `Markov_TriChars` oracles | planned |
| Eq 3.28–3.30 (pp. 67–68) | Absorbing chain: M, F | `StageCostFun` | none | `markov.solve` | row-sum and absorption properties | planned |
| Eq 3.59 (p. 89) | Expected scrap cost | `StageCostFun` | `kDMatrix`, `kSMatrix` | `economics.stage_costs` (exact form) | Eq 3.59 oracle | deviates (D1, planned) |
| Eq 3.59 (p. 89) | Expected rework cost | `StageCostFun` | none | `economics.stage_costs` | R3 | planned |
| Eq 3.44, 3.58 (pp. 79, 89) | Single-Stage Expected Profit | `StageCostFun` + caller | none | `economics.evaluate_stage` | R3, R4 | planned |
| Khasawneh & Bowling 2008 Eq 5 (via Table 3.1) | Literature 2-Feature profit (cost-formula "Case I") | `K_and_B_2008_Example` | `KandBMarkov_DualChars`, `mvncdf` | oracle only | R3-oracle | planned |
| Eq 3.26–3.27 (p. 64), Sec. 3.5 | Mean Settings per Rework Group Size | `StageCostFun_MultiMu`, `Probs_nVars_MultiMu` | as above | `model.MeanSettings`, `optimisation.tying` | R6, R7 | planned |
| Eq 3.77–3.78 (pp. 95–96) | Serial multi-Stage Expected Profit | `Costs_MultiStage_MultiFeature` | `StageCostFun` | `economics.evaluate_sequence` | R5; script oracle | planned |
| Table 3.9 (p. 109) | Inspection Cost and Sequence comparison | none found | none | `model.InspectionCost`, `optimisation.search_sequences` | R8 | planned |
| Sec. 4.2 | Copula joint distributions | root copula scripts (deferred) | `copulacdf` | `distributions.GaussianCopula` | Stage 7 | planned |
