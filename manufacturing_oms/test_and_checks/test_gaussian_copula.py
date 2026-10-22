"""Gaussian copula Process Variation with SciPy marginals (spec §5.2, Stage 7)."""

import math

import numpy as np
import pytest
from scipy.integrate import quad
from scipy.stats import cauchy, logistic, norm, t

from oms import GaussianCopula, MultivariateNormal

INF = math.inf

CORRELATIONS = {
    1: [[1.0]],
    2: [[1.0, 0.7052], [0.7052, 1.0]],
    3: [[1.0, 0.4, -0.24], [0.4, 1.0, 0.29], [-0.24, 0.29, 1.0]],
    4: [[1.0, 0.5, 0.3, 0.1], [0.5, 1.0, 0.4, 0.2], [0.3, 0.4, 1.0, 0.6], [0.1, 0.2, 0.6, 1.0]],
}


def boxes(seed, count, dimension):
    rng = np.random.default_rng(seed)
    for _ in range(count):
        means = rng.uniform(-1.0, 1.0, dimension)
        lower = rng.uniform(-4.0, 2.0, dimension)
        upper = lower + rng.uniform(0.2, 4.0, dimension)
        lower[rng.random(dimension) < 0.2] = -INF
        upper[rng.random(dimension) < 0.2] = INF
        yield means, lower, upper


@pytest.mark.parametrize("dimension", [1, 2, 3, 4])
def test_normal_marginals_equal_the_multivariate_normal(dimension):
    sigmas = [0.5, 1.0, 2.0, 0.1362][:dimension]
    corr = CORRELATIONS[dimension]
    copula = GaussianCopula([norm(0.0, s) for s in sigmas], corr)
    mvn = MultivariateNormal(sigmas, corr)
    for means, lower, upper in boxes(seed=dimension, count=20, dimension=dimension):
        means, lower, upper = means * sigmas, lower * sigmas, upper * sigmas
        got = copula.box_probability(means, lower, upper, rng_seed=3)
        expected = mvn.box_probability(means, lower, upper, rng_seed=3)
        assert got.value == pytest.approx(expected.value, abs=1e-8)
        assert got.method == expected.method


def conditional_quadrature_box(marginals, rho, means, lower, upper):
    """Independent oracle: ∫ f₁(x₁) P(l₂ < X₂ < u₂ | X₁ = x₁) dx₁ over the data scale of Feature 1.

    Given X₁ = x₁, Feature 2's normal score is N(ρ z₁, 1 − ρ²) with z₁ = Φ⁻¹(F₁(x₁ − μ₁)).
    """
    f1, f2 = marginals
    s = math.sqrt(1 - rho * rho)
    z2_lo, z2_hi = (norm.ppf(f2.cdf(x - means[1])) for x in (lower[1], upper[1]))

    def integrand(x1):
        z1 = norm.ppf(f1.cdf(x1 - means[0]))
        return f1.pdf(x1 - means[0]) * (norm.cdf((z2_hi - rho * z1) / s) - norm.cdf((z2_lo - rho * z1) / s))

    lo, hi = max(lower[0], means[0] + f1.ppf(1e-13)), min(upper[0], means[0] + f1.ppf(1 - 1e-13))
    points = [means[0]] if lo < means[0] < hi else None
    return quad(integrand, lo, hi, epsabs=1e-14, epsrel=1e-12, limit=500, points=points)[0]


@pytest.mark.parametrize("rho", [-0.8, -0.3, 0.2, 0.7052, 0.95])
def test_t_marginal_matches_conditional_quadrature(rho):
    marginals = (norm(0.0, 0.1362), t(2.2522, 0.0, 0.0527))
    copula = GaussianCopula(marginals, rho)
    for means, lower, upper in boxes(seed=round(100 * rho) + 100, count=15, dimension=2):
        means, lower, upper = means * 0.1, lower * 0.1, upper * 0.1
        expected = conditional_quadrature_box(marginals, rho, means, lower, upper)
        got = copula.box_probability(means, lower, upper)
        assert got.value == pytest.approx(expected, abs=1e-9)
        assert got.abs_error <= 1e-8


def test_marginal_drops_features_from_the_box():
    marginals = [norm(0.0, 1.0), t(3.0, 0.0, 0.5), logistic(0.0, 0.3)]
    copula = GaussianCopula(marginals, CORRELATIONS[3])
    pair = copula.marginal([2, 0])
    assert pair.dimension == 2
    assert pair.marginals == (marginals[2], marginals[0])
    full = copula.box_probability([0.1, 0.2, -0.1], [-0.5, -INF, -0.4], [1.0, INF, 0.3]).value
    assert pair.box_probability([-0.1, 0.1], [-0.4, -0.5], [0.3, 1.0]).value == pytest.approx(full, abs=1e-12)


def test_standard_deviations_fall_back_to_the_normal_equivalent_iqr():
    nu, scale = 2.2522, 0.0527
    copula = GaussianCopula([norm(0.0, 0.1362), t(nu, 0.0, scale), cauchy(0.0, 0.2)])
    # Cauchy has no standard deviation; its IQR is 2γ, and a Normal's IQR is 2Φ⁻¹(0.75)σ.
    expected = (0.1362, scale * math.sqrt(nu / (nu - 2)), 0.2 / norm.ppf(0.75))
    assert copula.standard_deviations == pytest.approx(expected, rel=1e-10)


@pytest.mark.parametrize("marginal", [norm(0.1, 1.0), t(3.0, -0.2, 1.0), cauchy(0.05, 1.0)])
def test_marginals_must_be_centred_on_zero(marginal):
    with pytest.raises(ValueError, match="centred on 0"):
        GaussianCopula([norm(0.0, 1.0), marginal], 0.5)


def test_correlation_is_validated():
    with pytest.raises(ValueError, match="positive semi-definite"):
        GaussianCopula([norm(), norm(), norm()], [[1, 0.9, -0.9], [0.9, 1, 0.9], [-0.9, 0.9, 1]])
    with pytest.raises(ValueError, match="2×2"):
        GaussianCopula([norm(), norm()], CORRELATIONS[3])
