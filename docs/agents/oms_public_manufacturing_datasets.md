# Public Manufacturing Datasets for OMS Experiments

## Purpose

This document is a starting brief for an agent applying **Optimal Mean Setting (OMS)** to real manufacturing measurements. Start with the existing OMS implementation in `https://github.com/cd205/mlcode` (`manufacturing_oms/`). The aim is to build **reproducible case studies**, not to claim real economic savings from datasets that do not contain verified scrap, rework, or cost records.

**Scope:** The seven datasets below only. Exclude the industrial batch-dryer example. Prioritise observed **continuous quality-output distributions** over datasets containing only machine telemetry or defect labels. Do not introduce injection-moulding-specific functionality.

## Dataset shortlist

| Priority | Dataset | Approximate size | Observed quality characteristics | Recorded process settings? | OMS suitability | Source |
|---|---|---|---|---|---|---|
| 1 | **Industrial piston-ring grinding** | 1,200 observations | Three dimensional outputs (`T1`, `T2`, `T3`) | **Yes:** four input factors plus two noise factors | **Excellent:** multivariate distribution and control-response modelling | [GitHub repository](https://github.com/Matheuscp98/Grinding) · [CSV](https://raw.githubusercontent.com/Matheuscp98/Grinding/main/grinding.csv) |
| 2 | **Six-point sawmill board thickness** | 5,000 boards | Thickness at six points per board | No | **Excellent:** high-sample multivariate correlation study | [OpenMV](https://www.openmv.net/info/six-point-board-thickness) |
| 3 | **Piston-ring diameter** | 200 measurements | One measured diameter | No | **Very good:** simple univariate baseline | [R `qcc` documentation](https://search.r-project.org/CRAN/refmans/qcc/html/pistonrings.html) |
| 4 | **Silicon wafer thickness** | 184 wafers | Thickness at nine locations on each wafer | No | **Very good:** higher-dimensional joint conformance | [OpenMV](https://www.openmv.net/info/silicon-wafer-thickness) |
| 5 | **NIST lathe machining** | 50 observations in a five-machine/two-coolant example | Turned-pin diameter | **Partial:** categorical machine and coolant factors | **Good:** compare conditional distributions across operating configurations | [NIST datasets directory](https://www.itl.nist.gov/div898/handbook/datasets.htm) |
| 6 | **Battery electrode calendering** | Experimental samples; confirm count after download | Electrode thickness and related measured properties | **Yes:** reported calendering/processing conditions | **Good:** process-input-to-quality modelling, subject to verifying sufficient repeats | [Mendeley Data](https://data.mendeley.com/datasets/c62yn37d9h/4) |
| 7 | **Plastic film thickness** | 160 films | Thickness measured at four corners | No | **Good:** compact multivariate thickness case | [OpenMV](https://www.openmv.net/info/film-thickness) |

**Interpret the ranking as compatibility with OMS, not commercial value.** Sample counts and variable definitions must be checked against the downloaded files before analysis.

## Dataset-specific starting experiments

### 1. Industrial piston-ring grinding — first priority
- **Data:** Repeated observations of `T1`, `T2`, `T3` under recorded process inputs (`x1`–`x4`) and noise factors (`z1`, `z2`). Check the dataset README and experimental design before interpreting physical units and factor identities.
- **Initial OMS experiment:** Fit a joint quality distribution within a well-replicated operating condition. Assign *explicitly hypothetical* tolerances and asymmetric scrap/rework costs; optimise the dimensional mean vector. Compare independent-normal, correlated-normal, and (where warranted) copula models.
- **Next extension:** Fit a validated mapping from machine settings to the conditional mean, covariance and possibly distribution shape; optimise **feasible physical controls** rather than freely selectable output means.
- **Caveat:** Replication per exact machine-setting/noise configuration can be small. Do not pool distinct noise settings without modelling their effects. No verified economic or repeated-rework observations are supplied.

### 2. Six-point sawmill board thickness — best multivariate demonstration
- **Data:** Six simultaneous laser-based board-thickness measurements for each of approximately 5,000 boards.
- **Initial OMS experiment:** Fit the joint six-dimensional thickness distribution. Compare the economically optimal target and joint conformance estimate under independent and correlated models.
- **Illustrative economics:** Too-thin boards may be downgraded or rejected; excessive thickness may represent material giveaway. Define these rules as **scenarios**, not facts about the dataset.
- **Caveat:** No actual saw-setting controls, specification limits, or cost/rework records. A common shift of all six measurement means may be more physically credible than six independently controllable means.

### 3. Piston-ring diameter — simplest regression test
- **Data:** Diameter observations arranged in subgroups. A separately published piston-ring capability example uses nominal 74 mm and specification limits 73.95–74.05 mm; verify that these limits apply to the selected data before use.
- **Initial OMS experiment:** Fit a univariate distribution and optimise its mean for different asymmetric costs: oversize potentially removable by machining; undersize potentially irrecoverable.
- **Caveat:** Rework feasibility and economic costs are hypothetical unless independently documented. No multivariate distributions or physical machine-setting information.

### 4. Silicon wafer thickness — correlated nine-feature test
- **Data:** Nine thickness readings per wafer across approximately 184 wafers; published values are scaled/anonymised.
- **Initial OMS experiment:** Evaluate joint probability that **all nine** sites satisfy assumed limits. Test multivariate normal against simpler dependence assumptions; explore the sensitivity of optimal targets to correlation.
- **Caveat:** Limited samples for nine-dimensional tail estimation. Use bootstrap uncertainty and avoid overconfident estimates; no original engineering limits, control actions, or economics.

### 5. NIST lathe machining — operating-condition comparison
- **Data:** Turned-pin diameter measurements with five machine categories and two coolant categories. Locate and confirm the specific machine/coolant file and experimental structure in the NIST directory.
- **Initial OMS experiment:** Compare fitted diameter distributions and expected economic loss by machine/coolant condition; compute optimal target shifts under assumed asymmetric scrap/rework consequences.
- **Caveat:** Categorical machine/coolant choices are not direct mean-setting actuators, and there are few replicates within each combination. Avoid strong distributional or economic claims.

### 6. Battery electrode calendering — controls and multiple responses
- **Data:** Measured electrode properties and processing conditions associated with calendering; inspect available files and metadata to identify the true independent experimental unit.
- **Initial OMS experiment:** Model thickness/related continuous responses conditional on processing settings. Introduce *hypothetical* economic costs for excess material, out-of-specification electrode properties, and unusable output.
- **Next extension:** Optimise feasible calendering controls subject to any documented physical or performance constraints.
- **Caveat:** Distinguish replicated quality measurements from predictive sensor channels; some outputs may not be directly comparable across recipes. Do not infer cell safety or electrochemical suitability solely from thickness.

### 7. Plastic film thickness — small multivariate example
- **Data:** Four corner-thickness measurements for approximately 160 films.
- **Initial OMS experiment:** Evaluate the probability that all four corners meet assumed thickness limits; optimise a common thickness offset under asymmetric under-thickness and material-use costs.
- **Caveat:** Small sample size, no available control parameters, and no documented scrap/rework economics. Compare with the larger board-thickness dataset before choosing it for a flagship demonstration.

## Required workflow for each case study

1. **Download and document:** Save the source URL, citation/licence if available, original data file, data dictionary, acquisition date, and checksum. Do not assume a dataset is suitable until its actual contents have been inspected.
2. **Check measurements:** Identify independent units, number of replicates, missingness, units, continuous quality outputs, process-setting inputs and possible subgroups. Avoid treating time-series points or repeated measurements from one product as independent products.
3. **Estimate uncertainty:** Fit the simplest justified marginal/joint distribution, inspect tails and dependence, and quantify parameter uncertainty with appropriate resampling.
4. **Define OMS mapping:** Identify actual specifications and controllable inputs. Where these are absent, state all hypothetical limits, costs, recovery rules and bounds clearly. Do **not** present inferred control-to-mean mappings as observed facts.
5. **Run baseline and optimisation:** Calculate baseline conformance, rework/scrap probabilities and expected economic outcomes, then run OMS under transparent constraints. Compare against nominal-centre targeting and independent-feature optimisation.
6. **Validate:** Use held-out settings or units where possible; perform sensitivity analyses on costs, distribution assumptions, dependence, and parameter estimation. Validate optimiser outputs with Monte Carlo simulation when feasible.
7. **Report:** Include plots of empirical/fitted distributions, correlation matrices, current versus recommended targets, expected costs by outcome, sensitivity ranges and a clear limitations section.

## Critical modelling constraints

- The existing OMS code can adjust output-distribution **means** without necessarily changing variance or dependence. This is a useful counterfactual but does **not** prove that a real machine can achieve the recommended settings.
- The existing repeated-rework Markov model assumes fresh, independent redraws for reworked characteristics. Actual repair operations often depend on the previous measurement; only use that model when defensible, or label it as a hypothetical scenario.
- If several characteristics are measured on one item, calculate **joint item-level conformance**, not the product of marginal probabilities unless independence is supported.
- Respect any verified engineering/customer constraints. Never treat safety, product performance, or regulatory compliance as a penalty that can simply be traded off against profit.
- Distinguish **expected cost per part started**, **cost per conforming part**, and **annualised savings**. They are different measures and require different production-volume assumptions.

## Recommended execution order

1. **Piston-ring diameter:** Establish a minimal, auditable univariate OMS baseline.
2. **Six-point board thickness:** Demonstrate correlated multivariate OMS and compare against independence assumptions.
3. **Industrial grinding:** Connect statistical outputs to observed physical machine inputs; evaluate whether control-constrained OMS is feasible.
4. **Wafer and film thickness:** Stress-test multivariate dependence and uncertainty estimation at smaller sample sizes.
5. **NIST lathe and battery calendering:** Test conditional modelling by process setting and identify gaps in experimental design.

**Definition of success:** A reproducible result showing *when and why* an OMS recommendation differs from nominal centring or simpler alternatives, how sensitive it is to uncertain assumptions, and whether the change can be implemented using available process controls. Do not claim verified manufacturing savings without real economic data and prospective operational validation.
