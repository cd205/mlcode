# Manufacturing operation-sequence modelling (OMS)

This is a curated **copy** of the thesis-related MATLAB manufacturing-state, rework, scrap, expected-cost and optimal-mean-setting code. Original MATLAB files in the repository root are unchanged.

## Folders

- `legacy_matlab/core`: stage-level Markov and probability calculations, state/matrix construction.
- `legacy_matlab/production`: multi-stage cost examples and production cost functions.
- `legacy_matlab/validation`: numerical examples and comparisons retained as future Python regression tests.
- `legacy_matlab/optimisation`: original general-purpose MATLAB optimisers (third-party utilities; review licences before porting).
- `legacy_matlab/historical`: earlier and RP variants retained for comparison, **not** canonical implementations.
- `src/oms`: intended Python package layout (not translated yet).
- `examples`: future runnable Python reproduction scripts (not implemented).
- `test_and_checks`: future correctness and thesis-regression checks (not implemented).

## Core MATLAB call graph

```
StageCostFun -> Probs_nVars -> combinator, kSMatrix
             -> combinator, kSMatrix, kDMatrix, kJMatrix
StageCostFun_MultiMu -> Probs_nVars_MultiMu -> combinator, kSMatrix
                    -> combinator, kSMatrix, kDMatrix, kJMatrix
Costs_MultiStage_MultiFeature -> StageCostFun / StageCostFun_old
ProdCostFun -> Probs_1Var / Probs_2Var / Probs_3Var -> (other support code)
```

MATLAB native/statistics functions (e.g. `mvncdf`, `corr2cov`) are external runtime dependencies. A source copy **does not** imply the project runs without checking code compatibility or numerical results. The present selection covers the principal general-purpose stage/multi-stage modelling code and regression examples; it is not a certified exhaustive closure for every experiment.

## Important scope caveat

The thesis's stage-level and cost scripts are included, but a general declarative serial/parallel **operation-sequence optimisation API** is not established by these scripts alone. The intended Python `production/sequences.py` and `optimisation/sequence_search.py` are future extensions, not claims about existing MATLAB features.

Do not modify copies in `legacy_matlab/` when implementing Python: treat them as reference sources and track test baselines.
