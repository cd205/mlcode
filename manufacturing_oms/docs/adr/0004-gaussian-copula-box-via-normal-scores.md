# Gaussian copula box probabilities via normal scores; marginals centred on 0

2026-10-22, issue #14 (spec §5.2, Stage 7).

`GaussianCopula(marginals, corr)` models Process Variation as X_i = μ_i + Y_i, where μ_i is the Mean Setting and Y has the given continuous marginals (any object with `cdf`, `sf`, `ppf`, `mean`, `median` and `std`, such as a frozen `scipy.stats` distribution), joined by a Gaussian copula with correlation `corr`.

**Box probability.** Spec §5.2 describes inclusion–exclusion of the copula CDF C(u) = Φ_R(Φ⁻¹(u₁), …, Φ⁻¹(u_d)) over the 2^d corners. Every marginal CDF is increasing, so a Feature lies inside its limits exactly when its normal score lies inside Φ⁻¹(F_i(limit − μ_i)). That sum over corners is therefore the standard Gaussian box between the limits' normal scores. `GaussianCopula` computes these scores, from the nearer tail (−Φ⁻¹(sf) above the median), and hands the box to `MultivariateNormal` with unit standard deviations. It inherits ADR 0003 unchanged: exact block splitting, folding of ±1 correlations, BVNU in 2D (which does the 4-corner sum itself), conditional quadrature in 3D, seeded QMC from 4D, and the same `Probability` method tags and error bounds. With Normal marginals the result equals `MultivariateNormal` to rounding.

**Mean Settings.** The Mean Setting is added to the marginal's draw, so each marginal must be centred on 0. Its mean must be 0 (to 1e-9 of its spread), or its median when it has no mean, such as a Cauchy. The constructor rejects anything else, so a Mean Setting is always the process mean when one exists (GLOSSARY: Mean Setting).

**Spreads.** `standard_deviations` sets the default optimisation bounds [L − 3σ, U + 3σ]. It returns each marginal's standard deviation, or IQR / 1.349 (the Normal-equivalent σ) when the variance is infinite. For R9's t marginal (ν = 2.2522) the standard deviation exists and is 3.0 × its scale.

**Considered and rejected:**
- *Literal 2^d-corner sum of `scipy.stats.multivariate_normal.cdf`* (as the R9 precheck does). It is randomised QMC with no error estimate (ADR 0003). Subtracting corner CDFs near 1 also loses absolute precision that the direct box keeps.
- *Marginals given at their own location, with the Mean Setting replacing `loc`.* Not every distribution has a `loc` that equals its mean, and frozen SciPy distributions can't be re-located generically. Shifting by the Mean Setting works for any marginal.

**Consequences:**
- Discrete marginals aren't supported. Their CDF steps break the equivalence with normal scores.
- The Monte Carlo chain simulator draws copula variation independently, as Z ~ N(0, R) mapped through each marginal's quantile function, and is used to cross-check R9.
