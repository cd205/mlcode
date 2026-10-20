# Traceability

Each row links a thesis section or equation to the MATLAB that implements it, the Python that will implement it, its tests, and its validation status.

Statuses:
- `planned`: specified, not implemented.
- `implemented`: code exists.
- `verified`: tests pass against a reference.
- `deviates`: verified, with a deliberate discrepancy recorded in [discrepancies.md](discrepancies.md).

| Thesis | Concept | MATLAB entry point | MATLAB deps | Python | Tests | Status |
|---|---|---|---|---|---|---|
| Eq 3.4, 3.36 (pp. 51, 74) | One-Feature rework/conform/scrap probabilities | `Probs_1Var`, `MarkovProcess_1_Var`, `Fun_CMC_Markov` | `normcdf` | `distributions.MultivariateNormal` (1D), `markov.stage_transitions` | R1, R2, mirror property (`test_evaluate_single_feature_stage.py`, `test_normal_box_probability.py`); `Probs_1Var` oracle, LOWER Rework Side checked by reflection (D14) (`test_single_feature_oracles.py`) | verified |
| Eq 3.19–3.21 (pp. 59–60) | Box probability by inclusion–exclusion | `Probs_nVars` | `mvncdf`, `corr2cov` | `distributions.JointDistribution.box_probability` | property tests; U1 | planned |
| Eq 3.47–3.50 (pp. 85–86) | State enumeration (η, Υ ordering) | `StageCostFun`, `Probs_nVars` | `combinator` | `markov.enumerate_states` | state-count and ordering tests (`test_states.py`) | verified |
| Eq 3.51–3.57, 3.60–3.63 (pp. 86–91) | S-, D- and J-matrices; transition matrix | `kSMatrix`, `kDMatrix`, `Probs_nVars` | `combinator` | `markov.stage_transitions` (built directly from subset inclusion; S/D/J not reproduced) | `Probs_2Var/3Var`, `Markov_TriChars` oracles | implemented (exercised at N=1; box probabilities above 1D arrive in Stage 2) |
| Eq 3.28–3.30 (pp. 67–68) | Absorbing chain: M, F | `StageCostFun` | none | `markov.expected_visits`, `economics.evaluate_stage` | R1; f_C + scrap = 1, m ≥ 0, per-state rows sum to 1, limiting cases; `MarkovProcess_1_Var` and `Fun_CMC_Markov` oracles for m and f_C (`test_single_feature_oracles.py`) | verified (N=1) |
| Eq 3.59 (p. 89) | Expected scrap cost | `StageCostFun` | `kDMatrix`, `kSMatrix` | `economics.evaluate_stage` (exact form) | R2; hand-worked N=1 cases; Eq 3.59 oracle (Stage 2) | implemented (N=1 verified); deviates (D1, oracle planned) |
| Eq 3.59 (p. 89) | Expected rework cost | `StageCostFun` | none | `economics.evaluate_stage` | R2; R3 | verified (N=1) |
| Eq 3.44, 3.58 (pp. 79, 89) | Single-Stage Expected Profit | `StageCostFun` + caller; `MarkovProcess_1_Var`, `Fun_CMC_Markov` (N=1) | none | `economics.StageResult.expected_profit` | R2; one-Feature oracles (`test_single_feature_oracles.py`); R3, R4 | verified (N=1) |
| Table 3.3, Fig 3.24 | Optimal Mean Setting, `per_feature`, one Stage | `fminsearchcon` scripts | none | `optimisation.optimise_means` | R2 (`test_optimise_single_feature_stage.py`) | verified (N=1) |
| Khasawneh & Bowling 2008 Eq 5 (via Table 3.1) | Literature 2-Feature profit (cost-formula "Case I") | `K_and_B_2008_Example` | `KandBMarkov_DualChars`, `mvncdf` | oracle only | R3-oracle | planned |
| Eq 3.26–3.27 (p. 64), Sec. 3.5 | Mean Settings per Rework Group Size | `StageCostFun_MultiMu`, `Probs_nVars_MultiMu` | as above | `model.MeanSettings`, `optimisation.tying` | R6, R7 | planned |
| Eq 3.77–3.78 (pp. 95–96) | Serial multi-Stage Expected Profit | `Costs_MultiStage_MultiFeature` | `StageCostFun` | `economics.evaluate_sequence` | R5; script oracle | planned |
| Tables 3.8–3.9, Fig 3.27 (pp. 108–110) | Inspection Cost and Sequence comparison | none found | none | `model.InspectionCost`, `optimisation.search_sequences` | R8 | planned |
| Sec. 4.2 | Copula joint distributions | root copula scripts (deferred) | `copulacdf` | `distributions.GaussianCopula` | Stage 7 | planned |
