# Gaussian box probabilities: Genz BVNU in 2D, conditional quadrature in 3D, seeded QMC from 4D

Resolves U1 (spec §8), 2026-10-21.

`MultivariateNormal.box_probability` standardises the box, then makes two exact reductions before it integrates anything:
- A Feature correlated ±1 with an earlier one is folded into that Feature's limits.
- The correlation matrix is split into independent blocks (connected components of non-zero correlations), and the probability is the product of the block probabilities.

Each block then uses the cheapest method that meets the spec §6 tolerances:

| Block size | Method (`Probability.method`) | Reported `abs_error` | Cost per box |
|---|---|---|---|
| 1 | `ndtr`, in the tail nearer the box (`analytic`) | 0 | µs |
| 2 | Our vectorised port of Genz's BVNU (Drezner & Wesolowsky 1990, revised by Genz 2004: 6/12/20-point Gauss–Legendre, asymptotic expansion for \|ρ\| ≥ 0.925), by inclusion–exclusion over 4 corners (`numerical`) | 4e-15 (Genz reports about 5e-16 per corner) | about 0.07 ms |
| 3 | Condition on the variable least correlated with the other two; integrate φ(z) × the conditional bivariate box over it with `scipy.integrate.quad` (absolute tolerance 1e-13, truncated at ±12) (`numerical`) | quad's own error estimate + 4e-15 | about 0.8 ms |
| ≥ 4 | Genz's separation of variables with Gibson–Glasbey–Elston variable ordering, on 8 independently scrambled Sobol sets of 4096 points, seeded by `rng_seed` (`monte_carlo`) | standard error of the 8 estimates | about 10 ms |

Independent Features, which include every thesis case except R7 and R9, are therefore exact (`analytic`) whatever their number, and R8's four-Feature Stages need no Monte Carlo.

**Verification** (`test_multivariate_normal_box_probability.py`):
- 2D matches Sheppard's orthant formula 1/4 + asin ρ / 2π to 1e-14 for ρ ∈ [−1, 1], and an independent adaptive-quadrature oracle to 1e-13 on random boxes across all three Gauss–Legendre bands and the asymptotic band.
- 3D matches the trivariate orthant formula 1/8 + Σ asin ρ_ij / 4π within its reported error (≤ 1e-8), and a nested `dblquad` oracle to 1e-9. On a singular matrix (equicorrelation −½) it matches the exact reduced integral to 1e-12.
- ≥ 4D matches 1/(n+1), the orthant probability for equicorrelation ½, and SciPy's `multivariate_normal.cdf`, both within 3× the reported error. Non-singular errors are around 1e-7 to 1e-6.

**Considered and rejected:**
- *SciPy `multivariate_normal.cdf` for 2–3D.* Since SciPy 1.10 it uses randomised QMC in every dimension, so its value depends on `rng` and it doesn't return an error estimate. With `abseps=1e-10` it took seconds per box, and on the singular trivariate above it was 4e-6 off the exact value.
- *SciPy's private `_bivariate_normal_cdf` ufunc.* It is the same BVNU, but private API can change without notice. Our port is about 60 lines and is checked against public-API oracles.
- *Genz's TVTL trivariate algorithm.* It is faster, but much longer to port. Conditional quadrature already meets 1e-8 by several orders of magnitude, and N = 3 Stages occur only in R8, whose Features are independent anyway.

**Consequences:**
- `JointDistribution.box_probability` and `evaluate_stage` take a keyword `rng_seed` (default 0). Every box in one evaluation uses the same seed (common random numbers), so the objective is a deterministic function of the means for a fixed seed.
- A singular correlated block of 4 or more Features turns the QMC integrand into an indicator. The reported error grows to about 1e-4 and stays honest (checked against 4×10⁷ plain Monte Carlo draws).
- Rows of [Q R] sum to 1 only within the summed reported errors when QMC is used.
- Blocks are split on exact zeros only. A correlation of 1e-17 still links two Features, which is correct but loses the analytic shortcut.
- When every randomisation gives the same value (e.g. a box covering essentially all the mass), the reported QMC error is 0.
