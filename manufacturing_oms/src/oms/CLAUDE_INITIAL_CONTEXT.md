# Claude Code — Initial Project Context

## Project objective

Reconstruct the MATLAB research code underlying Christopher S. Dodd's 2015 EngD thesis, *A Paradigm to Maximise Performance and Profitability of Engineering Products in the Presence of Manufacturing Uncertainty*, as a maintainable, scientifically validated Python package.

**Primary scope:** modelling manufacturing operation sequences and their economic performance under manufacturing variation, inspection, scrap and rework. The eventual software should let a user define manufacturing features, operations/stages, process means, uncertainties/correlations, specification limits, inspection/rework/scrap rules and cost/revenue assumptions; evaluate the outcomes; and optimise controllable settings. Distinguish capabilities actually demonstrated in the MATLAB sources from desired extensions (especially arbitrary serial/parallel sequence definition and sequence optimisation).

**Explicitly out of scope for the initial phase:** reproducing cooling-hole CFD, Kriging/surrogate fitting, or engineering-specific datasets. Preserve only general-purpose probabilistic methods genuinely required by the operation-sequence model. Other case studies may be consulted for validation but are not the initial deliverable.

## Source of truth

GitHub repository: `cd205/mlcode`

Curated migration folder: `manufacturing_oms/`

- `manufacturing_oms/legacy_matlab/core/`: stage-level Markov models, probability calculations, state construction.
- `manufacturing_oms/legacy_matlab/production/`: multi-stage manufacturing cost code.
- `manufacturing_oms/legacy_matlab/validation/`: reference examples for eventual regression checks.
- `manufacturing_oms/legacy_matlab/optimisation/`: original optimisation utilities, including third-party code.
- `manufacturing_oms/legacy_matlab/historical/`: earlier/alternative versions; preserve for comparison, not automatically authoritative.
- `manufacturing_oms/src/oms/`: proposed Python package locations (currently placeholders).
- `manufacturing_oms/examples/`: proposed runnable examples (currently placeholders).
- `manufacturing_oms/test_and_checks/`: tests and numerical validation (name intentionally differs from `tests`).

The thesis itself is the mathematical and conceptual reference. Obtain a local copy of the thesis PDF if it is not already in the Claude Code workspace; do not infer missing thesis equations from script names alone.

The curated folder contains 45 copied MATLAB files. **It is not certified dependency-complete.** The original MATLAB files at repository root remain available for dependency discovery. Do not assume that everything in the curated folder is required or that everything required is already copied.

## Key identified MATLAB dependency paths

```text
StageCostFun
  -> Probs_nVars -> combinator, kSMatrix
  -> combinator, kSMatrix, kDMatrix, kJMatrix

StageCostFun_MultiMu
  -> Probs_nVars_MultiMu -> combinator, kSMatrix
  -> combinator, kSMatrix, kDMatrix, kJMatrix

Costs_MultiStage_MultiFeature
  -> StageCostFun and/or earlier StageCostFun_old

ProdCostFun
  -> Probs_1Var / Probs_2Var / Probs_3Var
  -> shared state/matrix utilities
```

These are indicative paths, **not a complete audited call graph**. Inspect source and handle dynamic calls, function handles, scripts, case sensitivity, shared names, built-in/toolbox functions and implicit state.

MATLAB statistical operations include `mvncdf` and `corr2cov`. Map their mathematical behaviour carefully onto tested Python equivalents (likely NumPy/SciPy); explicitly account for distribution conventions, numerical integration precision, random seeds, and MATLAB/Python indexing and array-shape differences.

## Desired functional capabilities

1. Represent manufacturing features and specification limits.
2. Represent individual operations/stages with controllable mean settings and variability, including correlations.
3. Construct manufacturing/rework states and their transition probabilities.
4. Evaluate Markov absorption/conformance, rework frequency and scrap probabilities.
5. Aggregate expected processing, rework and scrap costs across production stages, and calculate expected yield and profit/revenue.
6. Optimise process mean settings, with bounds and reproducible stopping criteria.
7. Ultimately define and evaluate configurable serial/parallel operation sequences; treat any capability beyond what is evidenced by the MATLAB sources as a **new feature requiring design and acceptance criteria**, not a literal port.

## Suggested Python architecture (subject to review)

```text
manufacturing_oms/
  src/oms/
    production/      # operations, stages, sequences, multi-stage aggregation
    markov/          # states, transition matrices, absorbing chains
    uncertainty/     # joint distributions, correlation, probabilities
    economics/       # processing/rework/scrap costs and expected profit
    optimisation/    # mean setting and, later, sequence search
  examples/          # runnable reproductions of MATLAB/thesis examples
  test_and_checks/   # unit, property, numerical regression and integration tests
  legacy_matlab/     # immutable reference sources
```

Prefer explicit typed data structures, small pure computational functions, and numerical test fixtures. Separate: (a) mathematical engine; (b) manufacturing model definition; (c) evaluation; (d) optimisation; (e) plotting/reproduction scripts.

## Scientific correctness and validation

- Before porting, trace the complete **reachable** MATLAB call graph for the selected operation-sequence use cases and record sources, third-party dependencies, external MATLAB toolbox calls and any missing helpers.
- Identify and document competing versions; choose an authoritative implementation only after comparison with the thesis and reference examples.
- Create small, deterministic reference cases from existing scripts. Preserve parameter values, expected probability vectors/matrices, expected yield, cost and profit where derivable.
- Check non-negativity, probability mass conservation, dimensions, absorbing-state behaviour, sensible limiting cases, and agreement across alternative implementations.
- Clearly distinguish exact analytic calculations from approximations and Monte Carlo; document tolerances and reproducibility.
- Never silently correct suspicious MATLAB behaviour. Document each defect or ambiguity and demonstrate the intended interpretation against equations or tests before changing it in Python.
- Do not claim a thesis figure/table has been reproduced without actually obtaining its inputs and checking its values.

## Working rules

1. **Do not edit or delete original MATLAB files**, either at repository root or in `legacy_matlab/`.
2. Do not copy third-party MATLAB code into Python mechanically; inspect licensing and prefer established Python libraries when they preserve the required behaviour.
3. Make changes in small, reviewable steps with working tests; explain assumptions and unresolved mathematical decisions.
4. No hard-coded results masquerading as calculations. Prefer general-purpose implementations tested on thesis examples.
5. Retain folder name **`test_and_checks`** (not `tests`).
6. Keep a traceability table: thesis section/equation -> MATLAB entry point -> MATLAB dependencies -> Python implementation -> test(s) -> validation status.
7. Initially focus on MATLAB-only research code and numeric examples. Ignore cooling-hole-specific data unless a future user request expands scope.

## First assignment — analysis/specification only

**Do not start translating all 45 files immediately.**

1. Inspect `manufacturing_oms/README.md` and the source files in `legacy_matlab/`; consult root-level MATLAB code where dependencies require it.
2. Produce a reliable reachable dependency graph and classify each file as core engine, application orchestration, validation, historical alternative, third-party utility or unrelated.
3. Identify the minimal executable vertical slice (prefer one-feature Markov model -> conformance, rework, scrap -> expected profit), then identify the path to multi-feature and multi-stage support.
4. Create a proposed Python API and domain model, explicitly highlighting what is existing functionality versus new operation-sequence capabilities.
5. Define numerical reference cases and acceptance criteria; identify unknowns that need discussion before implementation.
6. Present a staged implementation plan in which every stage ends with runnable tests and a working example.

Then use Matt Pocock's `grill-me` / `grill-with-docs` skill (if installed) to challenge the requirements, mathematical assumptions, desired operation-sequence semantics, acceptance tests, and design decisions **before** generating the detailed implementation spec.

## Definition of done

A successful reconstruction can run specified manufacturing scenarios from inputs (not hard-coded answers), reproduce verified reference calculations to documented tolerances, report yield/rework/scrap/cost/profit breakdowns, and support optimisation of mean settings. A later milestone supports arbitrary configurable operation sequences and their optimisation, once the desired semantics and mathematical model have been specified and tested.
