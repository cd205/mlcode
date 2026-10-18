# OMS Python Reconstruction: Analysis & Implementation Spec

Status: **draft for review**. Nothing gets implemented until this is approved.

This spec builds on:
- [GLOSSARY.md](../GLOSSARY.md): the canonical terms. This document uses them exactly as defined there.
- [ADR 0001](adr/0001-exact-absorbing-chain-scrap-cost.md): exact absorbing-chain scrap cost.
- [ADR 0002](adr/0002-matlab-ports-are-test-oracles-only.md): MATLAB ports exist only as test oracles.
- [traceability.md](traceability.md) and [discrepancies.md](discrepancies.md).
- Thesis: [CDodd_Thesis.pdf](CDodd_Thesis.pdf). The core material is Ch. 3 (printed pp. 47–118). PDF page = printed page + 20.

---

## 1. Scope

**In scope (this milestone):**
- Single-Stage, multi-Feature Markov rework/scrap model.
- Expected Profit over a serial chain of Stages.
- Optimisation of Mean Settings.
- Sequence search over Inspection positions.
- Gaussian distributions first, then copula + marginals.

**Out of scope:**
- Cooling-hole CFD, Kriging/surrogates, and engineering-specific datasets.
- Inspection measurement error.
- Rework draws that depend on earlier values.
- Coupling between Stages.
- Free manufacturing order.
- Stages with more than 10 Features.

Section 9 lists these as future extensions.

## 2. Model specification

### 2.1 One Stage

A Stage makes the Features F₁…F_N (N ≤ 10). Each Feature has:
- Specification Limits [L, U];
- a Rework Side: `upper`, `lower` or `none`.

Let R ⊆ {1..N} be the Features whose Rework Side is not `none`.

**States**
- The Initial State I.
- One Rework State for each non-empty subset S ⊆ R.
- The absorbing states Conforming (C) and Scrapped (X).

Transient states number 2^|R|. They are ordered as I first, then subsets by size, then lexicographically. This matches the thesis's Υ ordering, Eq 3.50.

**Draws.** From a transient state s, the Features being processed are:
- D(I) = {1..N};
- D(S) = S for a Rework State.

They are drawn from the *marginal* joint distribution of D(s), with the Mean Setting μ_s.
- Features outside D(s) are already conforming and stay that way (assumption A3).
- The draw is fresh and independent of earlier values (A4).

**Classifying one draw x:**
- If any Feature in D(s) lies on its Scrap Side, the part goes to **X**.
- Otherwise, if T = {i ∈ D(s) : x_i on its Rework Side} is non-empty, the part goes to the Rework State **T**.
- Otherwise the part goes to **C**.

So p_{s,T}, p_{s,C} and p_{s,X} are box probabilities of the distribution of D(s). There are 2^|D(s)| boxes. The transition from a Rework State S to the Rework State S itself is allowed (rework failed again). A transition into the Rework State {1..N} reached from I is allowed and is *not* identified with I. It is the same state only when its Mean Setting equals I's, which is the default.

**Absorbing-chain algebra** (thesis Eq 3.28–3.30):

```
Q = transient→transient,  M = (I − Q)⁻¹,  m_{I,j} = M[I, j]

Final Conformance Probability   f_C  = Σ_j m_{I,j} p_{j,C}
Expected scrap cost             Sr   = Σ_j m_{I,j} p_{j,X} SC_j     (ADR 0001)
Expected rework cost            Rw   = Σ_{S≠I} m_{I,S} RC_S
Inspection cost (flat)          In   = IC_stage + IC_feature·N                  (U3, resolved)
```

**Sanity checks.** f_C + Σ_j m_{I,j} p_{j,X} = 1, and every m_{I,j} ≥ 0.

### 2.2 A Sequence of Stages (thesis Eq 3.78)

Stages I…W run in series and are independent of each other (A5). Let r_i = Π_{l<i} f_{C,l} be the probability of reaching Stage i.

```
E(PR)     = SP · Π_i f_{C,i} − Σ_i (PC_i + Sr_i + Rw_i) · r_i
E(PR) − I,  where I = Σ_i In_i
```

The result is per part started. Following the thesis (Table 3.9, pp. 109–110), I is a flat charge per part started. It is not weighted by r_i or by the expected number of inspections, so re-inspection after rework is free. Because I does not depend on the means, the optimal means are the same for E(PR) and E(PR) − I. Scrap Costs are entered by the user and already include the value added upstream (A6).

### 2.3 Mean Settings and tying schemes

The model stores one Mean Setting for each transient state: a vector over that state's D(s). The optimiser works on free parameters θ and expands them through a **tying scheme**:

| Scheme | Free parameters | Thesis name |
|---|---|---|
| `per_feature` | one μ per Feature, used for every state | Case I (Sec. 3.5) |
| `per_group_size` | one μ per Feature per Rework Group Size k. The Rework State {1..N} shares I's means. | Case II (Eq 3.26–3.27) |
| `per_state` | one μ per Feature per state, N·2^(N−1) + N | new |

⚠ The thesis uses "Case I/II" for two different things: mean schemes in Sec. 3.5, and *cost formulas* in Table 3.1. See D7 in [discrepancies.md](discrepancies.md). The code never uses the words "Case I/II".

### 2.4 Model assumptions (to be stated in user docs)

- **A1.** Inspection is 100% and error-free (thesis Assumption 6, p. 50).
- **A2.** Scrapping any one Feature scraps the whole part (p. 56).
- **A3.** Features that are not reworked stay conforming.
- **A4.** A rework draw is fresh and comes from the marginal joint distribution of the reworked subset. It does not depend on earlier values or on the kept Features.
- **A5.** Stages are independent: no correlation across Stages, and no carry-over of the post-rework distribution.
- **A6.** Costs are deterministic inputs. Scrap Cost is cumulative and entered by the user.
- **A7.** Process Variation is stationary: the same distribution shape and spread for the initial operation and for rework (thesis Assumption 3). Only the Mean Setting may differ between states.

## 3. MATLAB dependency audit

This is a static scan of all 45 curated files. Identifiers that match any `.m` file at the repo root or in `legacy_matlab/` were followed transitively. Comments and strings were excluded.

### 3.1 Classification

| Class | Files | Notes |
|---|---|---|
| **Core engine** | `StageCostFun`, `StageCostFun_MultiMu`, `Probs_nVars`, `Probs_nVars_MultiMu`, `kSMatrix`, `kDMatrix` | Canonical N-Feature path. Its scrap formula is Eq 3.59 (ADR 0001). |
| Core, dead | `kJMatrix` | Fills a matrix with the placeholder `99`. Its only call is commented out. Not ported. |
| Third-party utility | `combinator` (Matt Fig, FEX) | Replaced by `itertools.combinations`. Its `cumsumall` MEX path is reached only for integer classes, so it is unreachable here. |
| Application orchestration | `Costs_MultiStage_MultiFeature` (script), `ProdCostFun` | Multi-Stage Eq 3.78 driver. `ProdCostFun` is an earlier N≤3 cost function built on `Probs_1/2/3Var`. |
| **Validation oracles** | `Probs_1Var`, `Probs_2Var`, `Probs_3Var`, `MarkovProcess_1_Var`, `MarkovProcess_2_Var`, `Markov_TriChars`, `KandBMarkov_DualChars`, `K_and_B_2008_Example`, `Fun_Norm_Markov_DualChars`, `Fun_CMC_Markov` | Hand-written chains for N = 1, 2, 3, plus the Khasawneh & Bowling 2008 literature formula (Table 3.1, "Case I" cost formula). |
| Validation, incomplete | `K_and_B_DualQualitySimulation` | Monte Carlo simulation. Needs the root files `KandBSimulate.m` and `KandBSimulate_1Var.m`, which are **not curated**. A useful independent oracle. |
| Related, deferred (non-Gaussian / CMC) | `CostModel_Example1`, `CostModel_Norm_Example1`, `CostModel_CMC_Example1`, `Opt_CMC_3d_Example1`, `Opt_NORM_3d_Example1` | Three-Feature cost examples. `Opt_CMC_3d_Example1` uses `copulacdf` and needs the root file `Fun_Cut_Measure_Cut_pdf.m` (**not curated**). Revisit in Stage 7 of the plan. |
| **Unrelated** | `validation/Example1` | A Kriging/Branin/GA demo (reaches about 80 surrogate/sqplab files). Wrongly filed; leave it in place. |
| Third-party optimisers | `fminsearchcon`, `ga`, `gaoptimset` (John D'Errico) | Not ported. SciPy replaces them. |
| Historical | everything in `historical/` | `StageCostFun_old` (full-Σ input, N≤3 via `Probs_1/2/3Var`) is a useful oracle for correlated N≤3. The `_RP_*` copies are not authoritative. |

### 3.2 External/runtime dependencies

- **`mvncdf`:** box probabilities. Python replacement: [§5.2](#52-distributions).
- **`corr2cov`:** builds Σ from σ and a correlation matrix. Trivial.
- **`nchoosek`, `factorial`:** combinatorics, standard library.
- **`normcdf`:** **shadowed** by the root `normcdf.m` (Minka lightspeed, erf-based). It is numerically equivalent for `normcdf(x, m, s)`, so it does no harm, but it is recorded here.
- **`copulacdf`, `quad`:** only in the deferred CMC examples.
- **Missing from the curated folder:** `KandBSimulate.m`, `KandBSimulate_1Var.m` and `Fun_Cut_Measure_Cut_pdf.m`. They are at the repo root. Copy them into `legacy_matlab/validation/` when they become needed; never edit the originals.

## 4. Existing vs new capability

| Capability | Evidence | Status |
|---|---|---|
| N-Feature single-Stage chain, Gaussian, scalar ρ | `StageCostFun`, thesis 3.2.2 | Existing (port) |
| Full correlation matrix | Thesis Eq 3.19 (code uses only a scalar) | Existing in thesis, generalised |
| Mean Settings `per_group_size` (Case II) | `*_MultiMu`, Eq 3.26 | Existing (port; row order converted) |
| Mean Settings `per_state` | none | **New** |
| Rework Side per Feature, including `none` | Thesis App. F reverses the direction; code is fixed to upper | **New** (generalisation) |
| Exact scrap cost for N ≥ 3 | none (Eq 3.59 is too low) | **New** (correction, ADR 0001) |
| Serial multi-Stage Expected Profit | `Costs_MultiStage_MultiFeature`, Eq 3.78 | Existing (port) |
| Inspection Cost | Thesis Table 3.9 only | **New** in code |
| Sequence search over Inspection positions | Thesis Tables 3.8/3.9 (no MATLAB driver found) | **New** in code |
| Copula + marginal distributions in the chain | Thesis Ch. 4 (separate scripts) | **New** integration |
| Optimisation of Mean Settings | `fminsearchcon`/GA scripts | Re-implemented with SciPy |

## 5. Proposed Python API

The layout is `manufacturing_oms/src/oms/`:

```
model/          Feature, ReworkSide, Stage, Sequence, MeanSettings, CostTable, InspectionCost
distributions/  JointDistribution protocol, MultivariateNormal, GaussianCopula(+marginals), MonteCarlo fallback
markov/         state enumeration, transition matrix, absorbing-chain solve → StageResult
economics/      stage costs, sequence Expected Profit → ProfitBreakdown
optimisation/   tying schemes, optimise_means(), search_sequences()
```

### 5.1 Model (immutable dataclasses, validated on construction)

```python
class ReworkSide(Enum): UPPER; LOWER; NONE

@dataclass(frozen=True)
class Feature:
    name: str
    lower: float
    upper: float
    rework_side: ReworkSide          # required, no default

@dataclass(frozen=True)
class CostTable:                      # per state, keyed by frozenset of Feature names; I = frozenset()
    processing: float
    rework: Mapping[frozenset[str], float]
    scrap: Mapping[frozenset[str], float]
    @classmethod
    def additive(cls, processing, rework_per_feature, scrap_per_feature) -> "CostTable": ...

@dataclass(frozen=True)
class InspectionCost:
    per_stage: float = 0.0
    per_feature: float = 0.0

@dataclass(frozen=True)
class Stage:
    features: tuple[Feature, ...]     # 1..10 features
    variation: JointDistributionSpec  # shape/spread/correlation; means supplied separately
    costs: CostTable
    inspection: InspectionCost = InspectionCost()

@dataclass(frozen=True)
class MeanSettings:                   # full per-state form
    by_state: Mapping[frozenset[str], Mapping[str, float]]
    @classmethod
    def per_feature(cls, stage, mu: Mapping[str, float]) -> "MeanSettings": ...
    @classmethod
    def per_group_size(cls, stage, mu: Mapping[int, Mapping[str, float]]) -> "MeanSettings": ...

@dataclass(frozen=True)
class Sequence:
    stages: tuple[Stage, ...]
    selling_price: float
```

### 5.2 Distributions

```python
class JointDistribution(Protocol):
    def box_probability(self, means: ArrayLike, lower: ArrayLike, upper: ArrayLike) -> Probability: ...
    def marginal(self, indices: Sequence[int]) -> "JointDistribution": ...

@dataclass(frozen=True)
class Probability:
    value: float
    method: Literal["analytic", "numerical", "monte_carlo"]
    abs_error: float                  # 0 for analytic
```

The `MultivariateNormal(sigmas, corr)` implementation:
- **1 dimension:** `scipy.special.ndtr` (analytic).
- **2–3 dimensions:** deterministic. Either Owen's T / Drezner-type routines, or SciPy `multivariate_normal.cdf` with fixed `rng` and a tight `abseps`, *verified* against analytic independent cases. ⚠ This choice is resolved in Stage 2 (U1).
- **4 or more dimensions:** seeded QMC with the tolerance reported.
- The constructor checks that the correlation matrix is positive semi-definite. `corr=float` builds an equicorrelation matrix.

`GaussianCopula(marginals: Sequence[scipy.stats frozen dist], corr)` computes a box probability through the copula CDF, using inclusion–exclusion over 2^d corners.

### 5.3 Evaluation

```python
evaluate_stage(stage, means: MeanSettings, *, rng_seed=0) -> StageResult
    # f_C, M row, per-state p_C/p_X/p_T, expected costs, method/tolerance tags
evaluate_sequence(seq, means: Sequence[MeanSettings], *, rng_seed=0) -> ProfitBreakdown
    # E(PR), revenue, and processing/rework/scrap/inspection per Stage, reach probabilities
```

### 5.4 Optimisation

```python
optimise_means(seq, scheme: Literal["per_feature","per_group_size","per_state"],
               *, bounds=None, n_starts=8, seed=0, method="L-BFGS-B", tol=1e-9) -> OptimisationResult
search_sequences(features_in_order, stage_builder, selling_price, scheme, **opt_kwargs) -> list[SequenceResult]
    # enumerates all 2^(N−1) Inspection placements, optimises each, ranks by E(PR)
```

- Default bounds are [L − 3σ, U + 3σ] for each Feature.
- Multi-start points are seeded.
- The method, tolerances, number of evaluations and seed are recorded in the result.
- Bounded Nelder–Mead is used when the objective contains Monte Carlo terms.

## 6. Reference cases & acceptance criteria

**Pass rule:**
- *Evaluation* at the printed means must equal the printed E(PR) when rounded to the printed precision.
- *Optimisation* must recover the printed means to the printed precision.

**Pre-checked:** a throwaway pure-Python implementation of §2.1 was run during the 2026-10-15 grilling session. It is not part of the repo.

| # | Case | Inputs | Printed result | Pre-check |
|---|---|---|---|---|
| R1 | Fig 3.12/3.14, 1 Feature | μ=5, σ=1, [3,7] | first-pass conform 0.9545; m_{I,I}=1.0233; f_C≈0.9767 | f_C = 0.97672, rework visits 0.02328 ✓ |
| R2 | Table 3.3, 1 Feature | U=12, L=8, σ=1, SP=120, PC=25, RC=10, SC=15 | μ\*=10.61 (profit), 10.09 (min cost) | μ\* = 10.614 ✓; min PC+Sr+Rw μ = 10.0875 ✓ |
| R3 | Table 3.1, 2 Features, Eq 3.44 | L=[8,13], U=[12,17], σ=1, SP=120, PC=45, RC={1}:15, {2}:12, {1,2}:20; SC=I:8, {1}:9, {2}:11, {1,2}:14 | 71.4287 @ [10.5115, 15.5651] | 71.42872 ✓ |
| R3-oracle | Table 3.1, Khasawneh & Bowling (KB) 2008 formula (port of `K_and_B_2008_Example`) | same as R3 | 71.1592 @ [10.5514, 15.6080] | oracle only (D7) |
| R4 | Table 3.7, 2 Features parallel (inputs visually confirmed 2026-10-17) | L=[8,13], U=[12,17], σ=1, SP=120, PC=45, RC={1}:15, {2}:12, {1,2}:27; SC=27 for every state | 71.17 @ [10.537, 15.590]; min production cost 46.753 @ [10.128, 15.181] | 71.1723 @ [10.537, 15.590]; 46.7530 @ [10.128, 15.181] ✓ |
| R5 | Table 3.5, 2 Stages serial | PC=[25,20], RC=[15,12], SC=[10,27] | 71.41 @ [10.466, 15.591] | 71.4120 ✓ |
| R6 | Tables 3.10/3.11 `per_feature` vs `per_group_size` (visually confirmed 2026-10-17) | U=6, L=4, **σ=2** (not σ²=2), **SP=400** (not the printed 500, D11), PC=50, RC={1}:25, {2}:25, {1,2}:50, SC=150, Rework Side above U. Case II order: (μ₁,₁, μ₁,₂) = dual-feature means (I and {1,2}); (μ₂,₁, μ₂,₂) = single-feature rework means | 40.87 @ [6.85, 6.85]; 41.66 @ [6.75, 6.75, 7.02, 7.02]; f_C 0.5933/0.5935; production cost (Sr+Rw) 146.44/145.75 | 40.8747 @ 6.851; 41.6581 @ [6.748, 7.022]; Sr+Rw 146.44/145.75 ✓ |
| R7 | Table 3.13 correlated (visually confirmed 2026-10-17) | as R6 with ρ = ±0.8 | ρ=0.8: 56.4038 @ 6.65 / 58.3309 @ [6.52, 7.02]; Sr+Rw 140.24/138.93; f_C 0.6166/0.6181. ρ=−0.8: 45.11 @ 6.80 / 47.10 @ [6.57, 7.02]; Sr+Rw 139.65/136.60; f_C 0.5869/0.5842 | all ✓ (56.4038, 58.3309, 45.1141, 47.0993) |
| R8 | Tables 3.8/3.9 and Fig 3.27 Sequences, 4 Features (inputs visually confirmed 2026-10-17) | SP=120, PC=[25,20,12,15], RC=[15,12,8,10], SC=[10,17,5,12], L=[8,13,10,7], U=[12,17,14,11], σ=1, IC=0.5+0.5/Feature | e.g. Seq 1 41.7523; Seq 8 40.8657 | – (expect small N≥3 gap, ADR 0001) |
| R9 | Tables 4.1/4.3 connecting rod, copula (Stage 7; D6) | Units cm: L=[6.9, 3.925], U=[7.1, 4.075]; x₁ Normal σ=0.1362; x₂ tLocation-Scale scale 0.0527, ν=2.2522; Gaussian copula ρ=0.7052; Rework Side below L; SP=100, PC=20, RC={1}:5, {2}:5, {1,2}:10, SC=50; `per_group_size` | 44.47 @ [6.8737, 3.9514, 6.8441, 3.9486] | 44.4708 @ printed means ✓ |

**Oracle tests** (ports of MATLAB, `test_and_checks/oracles/`):
- Eq 3.59 S∘D scrap must equal the engine exactly for N ≤ 2. For N = 3 and 4 the gap is recorded and shown to be negative.
- `Probs_1/2/3Var`, `MarkovProcess_*`, `Markov_TriChars` and `KandBMarkov_DualChars` must match the engine's transition probabilities and m/f values to 1e-10 at the same inputs.
- Monte Carlo simulation of the chain (a fresh Python implementation of A1–A7) must agree with f_C, m and E(PR) within 4 standard errors at a fixed seed.

**Property tests:**
- Probabilities lie in [0, 1].
- Each row of [Q R] sums to 1.
- f_C plus total scrap probability equals 1.
- Results don't change when Features are permuted.
- With ρ=0, the 2D box probability equals the product of the 1D ones.
- Moving the mean far towards the Rework Side gives f_C → 1 and rework visits → ∞. Far towards the Scrap Side gives f_C → 0.
- Mirroring a Feature (flipping its Rework Side and reflecting its limits and mean) leaves every result unchanged.

**Tolerances:**
- 1e-10 when both sides are analytic.
- 1e-8 for deterministic 2–3D.
- The reported QMC error × 3 for 4D and above.
- Printed-precision rounding for thesis tables.

## 7. Staged implementation plan

Every stage ends with green `pytest` on `test_and_checks/` and one runnable script in `examples/`.

**Stage 0: Environment (prerequisite, blocking).**
- The user installs standalone `uv` (not Langflow's bundled copy).
- Add `manufacturing_oms/pyproject.toml`: src layout, `requires-python >=3.11`, deps `numpy` and `scipy`, dev `pytest`, `testpaths=["test_and_checks"]`.
- `uv sync && uv run pytest` passes a smoke test.
- *Exit:* a CI-style command documented in the README.

**Stage 1: Single-Feature vertical slice.**
- `Feature`, `ReworkSide`, a 1D Normal, the general state enumeration and absorbing solve (N=1 only exercised), stage economics.
- *Exit:* R1 and R2 (evaluation + optimum); `Probs_1Var` / `MarkovProcess_1_Var` / `Fun_CMC_Markov` oracles; mirror property.
- *Example:* `examples/single_feature_table_3_3.py`.

**Stage 2: Multi-Feature single Stage, Gaussian.**
- `MultivariateNormal` with the full correlation matrix, decision U1 (§8), `CostTable`.
- *Exit:* R3 and R4; the R3 KB oracle; Eq 3.59 oracle (exact for N≤2, gap for N=3/4 logged); `Probs_2Var/3Var`, `Markov_TriChars` and `StageCostFun_old` oracles; property tests.

**Stage 3: Serial Sequences + Inspection Cost.**
- `Sequence`, `evaluate_sequence`, `ProfitBreakdown`.
- *Exit:* R5; a port of the `Costs_MultiStage_MultiFeature` oracle.

**Stage 4: Optimisation and tying schemes.**
- `optimise_means` with all three schemes.
- *Exit:* the optima for R2–R5; R6; R7; a `per_state` result ≥ the `per_group_size` result ≥ the `per_feature` result on R6 (nested schemes).

**Stage 5: Sequence search.**
- `search_sequences`.
- *Exit:* R8, all 8 Sequences. Any difference beyond the printed precision for Stages with 3 or more Features must be explained by the ADR 0001 gap. Show this by also running the Eq 3.59 oracle.

**Stage 6: Monte Carlo validation harness.**
- An independent chain simulator for cross-checking every R-case. Optionally port `K_and_B_DualQualitySimulation` once its missing files are curated.

**Stage 7: Non-Gaussian distributions.**
- `GaussianCopula` + SciPy marginals. Clayton and Frank when the connecting-rod case (Sec. 4.3) is taken on.
- *Exit:* a Gaussian copula with normal marginals equals `MultivariateNormal` to 1e-8; one Ch. 4 example reproduced. That example is chosen at the start of this stage, and Table 4.3 is suspect (see D6).

## 8. Open unknowns (to resolve inside the named stage)

- **U1 (Stage 2):** which deterministic algorithm is used for 2D/3D box probabilities, and the accuracy it can prove. The candidates are SciPy with a tight `abseps`, or a dedicated bivariate/trivariate routine.
- **U2 (Stage 1), resolved 2026-10-18:** production cost = PC + Sr + Rw per part started (p. 101: "Production cost is E(PR) − SP f_{I,C}", printed without the sign flip). It is not per conforming part, which would give μ = 10.33. Minimising it reproduces R2 (10.0875) and R4 (46.7530 @ [10.128, 15.181]). Tables 3.11/3.13 report Sr + Rw without PC (D12), so the engine reports PC, Sr and Rw separately and tests compare the matching sum.
- **U3 (Stage 3), resolved 2026-10-17:** Inspection Cost is a flat IC_stage + IC_feature·N per Stage, summed over the Sequence and subtracted from E(PR) per part started (thesis pp. 108–110: "an inspection process is implicit after each stage… a cost of 0.5 units with a further 0.5 units for each feature inspected"). Table 3.9's I column matches this for Seqs 1–7. Seq 8 is a misprint (D10).
- **U4 (Stage 4), resolved 2026-10-17:** R6/R7 confirmed visually and reproduced by a throwaway calculation once σ=2 and SP=400 are used (D11).
- **U5 (Stage 2), resolved 2026-10-17:** R4 and R8 inputs confirmed visually (Tables 3.7, 3.8).

## 9. Future extensions (each needs its own spec)

- Rework draws that depend on earlier values (e.g. re-cutting from the current dimension).
- Coupling between Stages (correlation, carry-over of the post-rework distribution).
- Free manufacturing order (ordered partitions) with precedence constraints.
- Stages with more than 10 Features.
- Inspection measurement error.
- Parallel machines or branching flows.
