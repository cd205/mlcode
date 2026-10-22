"""Correlated Normal box probabilities (spec §5.2, ADR 0003): checked against closed forms and SciPy."""

import math

import numpy as np
import pytest
from scipy.integrate import dblquad, quad
from scipy.stats import multivariate_normal, norm

from oms import MultivariateNormal

INF = math.inf


@pytest.mark.parametrize("rho", [-1.0, -0.99, -0.8, -0.5, -0.2, 0.1, 0.4, 0.8, 0.93, 0.999, 1.0])
def test_bivariate_orthant_has_the_sheppard_closed_form(rho):
    # P(Z₁ > 0, Z₂ > 0) = 1/4 + asin(ρ) / 2π
    p = MultivariateNormal([1.0, 1.0], rho).box_probability([0.0, 0.0], [0.0, 0.0], [INF, INF])
    assert p.value == pytest.approx(0.25 + math.asin(rho) / (2 * math.pi), abs=1e-14)
    assert p.abs_error <= 1e-8
    # A perfectly correlated pair is one Feature in disguise, so its box is the analytic 1D one.
    assert p.method == ("analytic" if abs(rho) == 1.0 else "numerical")


def conditional_quadrature_box(a, b, rho):
    """Independent oracle: ∫ φ(z₁) P(a₂ < Z₂ < b₂ | z₁) dz₁ by adaptive quadrature (|ρ| < 1)."""
    s = math.sqrt(1 - rho * rho)

    def integrand(z):
        return norm.pdf(z) * (norm.cdf((b[1] - rho * z) / s) - norm.cdf((a[1] - rho * z) / s))

    return quad(integrand, max(a[0], -12.0), min(b[0], 12.0), epsabs=1e-15, epsrel=1e-13, limit=500)[0]


def random_boxes(seed, count, dimension):
    rng = np.random.default_rng(seed)
    for _ in range(count):
        lower = rng.uniform(-3.0, 2.0, dimension)
        upper = lower + rng.uniform(0.2, 4.0, dimension)
        lower[rng.random(dimension) < 0.2] = -INF
        upper[rng.random(dimension) < 0.2] = INF
        yield lower, upper


@pytest.mark.parametrize("rho", [-0.97, -0.9, -0.6, -0.25, 0.05, 0.29, 0.5, 0.74, 0.8, 0.926, 0.99])
def test_bivariate_box_matches_conditional_quadrature(rho):
    mvn = MultivariateNormal([1.0, 1.0], rho)
    for lower, upper in random_boxes(seed=round(1000 * rho) + 1000, count=25, dimension=2):
        expected = conditional_quadrature_box(lower, upper, rho)
        assert mvn.box_probability([0.0, 0.0], lower, upper).value == pytest.approx(expected, abs=1e-13)


def test_bivariate_box_scales_by_the_standard_deviations():
    p = MultivariateNormal([2.0, 0.5], 0.6).box_probability([10.0, 3.0], [9.0, 2.8], [13.0, 4.0])
    assert p.value == pytest.approx(conditional_quadrature_box([-0.5, -0.4], [1.5, 2.0], 0.6), abs=1e-13)


def test_uncorrelated_bivariate_box_is_the_product_of_one_dimensional_boxes():
    mvn = MultivariateNormal([1.0, 2.0], 0.0)
    p = mvn.box_probability([0.3, -1.0], [-1.0, -2.0], [1.5, 4.0])
    first = MultivariateNormal([1.0]).box_probability([0.3], [-1.0], [1.5]).value
    second = MultivariateNormal([2.0]).box_probability([-1.0], [-2.0], [4.0]).value
    assert p.value == pytest.approx(first * second, abs=1e-15)


TRIVARIATE_CORRELATIONS = [
    [[1.0, 0.5, 0.5], [0.5, 1.0, 0.5], [0.5, 0.5, 1.0]],
    [[1.0, -0.4, 0.3], [-0.4, 1.0, 0.6], [0.3, 0.6, 1.0]],
    [[1.0, 0.95, 0.9], [0.95, 1.0, 0.92], [0.9, 0.92, 1.0]],
    [[1.0, -0.5, -0.5], [-0.5, 1.0, -0.5], [-0.5, -0.5, 1.0]],  # singular
    [[1.0, 0.0, 0.7], [0.0, 1.0, -0.2], [0.7, -0.2, 1.0]],
]


@pytest.mark.parametrize("corr", TRIVARIATE_CORRELATIONS)
def test_trivariate_orthant_has_the_closed_form(corr):
    # P(Z > 0) = 1/8 + (asin ρ₁₂ + asin ρ₁₃ + asin ρ₂₃) / 4π
    p = MultivariateNormal([1.0, 1.0, 1.0], corr).box_probability(np.zeros(3), np.zeros(3), np.full(3, INF))
    expected = 0.125 + sum(math.asin(corr[i][j]) for i, j in [(0, 1), (0, 2), (1, 2)]) / (4 * math.pi)
    assert p.value == pytest.approx(expected, abs=1e-8)
    assert p.method == "numerical"
    assert abs(p.value - expected) <= p.abs_error <= 1e-8


def nested_quadrature_box(a, b, corr):
    """Independent oracle for a non-singular trivariate: ∫∫ φ₂(z₁, z₂) P(a₃ < Z₃ < b₃ | z₁, z₂) dz₂ dz₁."""
    corr = np.asarray(corr)
    r12 = corr[0, 1]
    beta = np.linalg.solve(corr[:2, :2], corr[:2, 2])
    s = math.sqrt(1 - corr[:2, 2] @ beta)
    pair = multivariate_normal(mean=[0.0, 0.0], cov=[[1.0, r12], [r12, 1.0]])

    def integrand(z2, z1):
        m = beta[0] * z1 + beta[1] * z2
        return pair.pdf([z1, z2]) * (norm.cdf((b[2] - m) / s) - norm.cdf((a[2] - m) / s))

    clip = lambda v: min(max(v, -9.0), 9.0)  # noqa: E731
    return dblquad(integrand, clip(a[0]), clip(b[0]), clip(a[1]), clip(b[1]), epsabs=1e-12, epsrel=1e-11)[0]


@pytest.mark.parametrize("corr", [c for i, c in enumerate(TRIVARIATE_CORRELATIONS) if i != 3])
def test_trivariate_box_matches_nested_quadrature(corr):
    mvn = MultivariateNormal([1.0, 1.0, 1.0], corr)
    for lower, upper in random_boxes(seed=7, count=6, dimension=3):
        expected = nested_quadrature_box(lower, upper, corr)
        assert mvn.box_probability(np.zeros(3), lower, upper).value == pytest.approx(expected, abs=1e-9)


def test_singular_trivariate_box_matches_its_exact_reduction():
    # With equicorrelation −1/2, Z₃ = −Z₁ − Z₂ exactly: integrate over Z₁ a 1D box on Z₂.
    mvn = MultivariateNormal([1.0, 1.0, 1.0], -0.5)
    s = math.sqrt(0.75)
    for lower, upper in random_boxes(seed=7, count=8, dimension=3):

        def integrand(z1, lower=lower, upper=upper):
            lo, hi = max(lower[1], -upper[2] - z1), min(upper[1], -lower[2] - z1)
            return norm.pdf(z1) * max(0.0, norm.cdf((hi + z1 / 2) / s) - norm.cdf((lo + z1 / 2) / s))

        expected = quad(integrand, max(lower[0], -12.0), min(upper[0], 12.0), epsabs=1e-15, epsrel=1e-13, limit=1000)[0]
        assert mvn.box_probability(np.zeros(3), lower, upper).value == pytest.approx(expected, abs=1e-12)


def test_perfectly_correlated_pair_reduces_to_a_bivariate_box():
    # Z₃ = Z₁, so the box on Z₃ intersects the box on Z₁.
    corr = [[1.0, 0.3, 1.0], [0.3, 1.0, 0.3], [1.0, 0.3, 1.0]]
    p = MultivariateNormal([1.0, 1.0, 1.0], corr).box_probability(np.zeros(3), [-1.0, -0.5, -2.0], [1.0, 2.0, 0.5])
    expected = MultivariateNormal([1.0, 1.0], 0.3).box_probability([0.0, 0.0], [-1.0, -0.5], [0.5, 2.0]).value
    assert p.value == pytest.approx(expected, abs=1e-12)


@pytest.mark.parametrize("dimension", [4, 5, 7])
def test_equicorrelated_half_orthant_is_one_over_n_plus_one(dimension):
    # With ρ = 1/2, Z_i = (Y_i − Y₀)/√2 for iid Y, so P(Z > 0) = P(Y₀ is the smallest) = 1/(n + 1).
    p = MultivariateNormal(np.ones(dimension), 0.5).box_probability(
        np.zeros(dimension), np.zeros(dimension), np.full(dimension, INF)
    )
    assert p.method == "monte_carlo"
    assert 0.0 < p.abs_error < 1e-4
    assert p.value == pytest.approx(1 / (dimension + 1), abs=3 * p.abs_error)


QUADRIVARIATE = [[1.0, 0.3, -0.2, 0.5], [0.3, 1.0, 0.4, 0.1], [-0.2, 0.4, 1.0, -0.3], [0.5, 0.1, -0.3, 1.0]]


def test_quasi_monte_carlo_matches_scipy_within_the_reported_error():
    mvn = MultivariateNormal([1.0, 2.0, 0.5, 1.5], QUADRIVARIATE)
    sigma = np.array([1.0, 2.0, 0.5, 1.5])
    cov = np.asarray(QUADRIVARIATE) * np.outer(sigma, sigma)
    for lower, upper in random_boxes(seed=11, count=6, dimension=4):
        lower, upper = lower * sigma, upper * sigma
        expected = multivariate_normal.cdf(upper, cov=cov, lower_limit=lower, abseps=1e-7, releps=0, rng=3)
        p = mvn.box_probability(np.zeros(4), lower, upper)
        # 3× our reported error (spec §6), plus the 1e-7 SciPy's own QMC is asked for.
        assert p.value == pytest.approx(expected, abs=3 * p.abs_error + 1e-7)


def test_quasi_monte_carlo_is_reproducible_from_its_seed():
    mvn = MultivariateNormal(np.ones(4), QUADRIVARIATE)
    box = (np.zeros(4), [-1.0, -0.5, -2.0, 0.0], [1.0, 2.0, 0.5, 1.5])
    assert mvn.box_probability(*box, rng_seed=5) == mvn.box_probability(*box, rng_seed=5)
    assert mvn.box_probability(*box, rng_seed=5).value != mvn.box_probability(*box, rng_seed=6).value


def test_independent_blocks_keep_their_deterministic_methods():
    # Two correlated pairs, uncorrelated with each other: a product of two bivariate boxes.
    corr = [[1.0, 0.6, 0.0, 0.0], [0.6, 1.0, 0.0, 0.0], [0.0, 0.0, 1.0, -0.4], [0.0, 0.0, -0.4, 1.0]]
    lower, upper = [-1.0, -0.5, -2.0, 0.0], [1.0, 2.0, 0.5, 1.5]
    p = MultivariateNormal(np.ones(4), corr).box_probability(np.zeros(4), lower, upper)
    first = MultivariateNormal([1.0, 1.0], 0.6).box_probability([0.0, 0.0], lower[:2], upper[:2]).value
    second = MultivariateNormal([1.0, 1.0], -0.4).box_probability([0.0, 0.0], lower[2:], upper[2:]).value
    assert p.method == "numerical"
    assert p.value == pytest.approx(first * second, abs=1e-15)


class TestConstruction:
    def test_scalar_correlation_builds_an_equicorrelation_matrix(self):
        expected = ((1.0, 0.25, 0.25), (0.25, 1.0, 0.25), (0.25, 0.25, 1.0))
        assert MultivariateNormal([1.0, 2.0, 3.0], 0.25).corr == expected

    def test_default_is_independence(self):
        assert MultivariateNormal([1.0, 2.0]).corr == ((1.0, 0.0), (0.0, 1.0))

    @pytest.mark.parametrize(
        "corr",
        [
            -0.6,  # equicorrelation below −1/(n − 1) = −0.5
            [[1.0, 0.9, 0.0], [0.9, 1.0, 0.9], [0.0, 0.9, 1.0]],  # every |ρ| ≤ 1 but not PSD
            [[1.0, 0.3, 0.0], [0.2, 1.0, 0.0], [0.0, 0.0, 1.0]],  # not symmetric
            [[2.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]],  # not a unit diagonal
            [[1.0, 0.0], [0.0, 1.0]],  # wrong size
        ],
    )
    def test_rejects_matrices_that_are_not_correlation_matrices(self, corr):
        with pytest.raises(ValueError):
            MultivariateNormal([1.0, 1.0, 1.0], corr)

    def test_accepts_a_matrix_symmetric_only_to_rounding(self):
        corr = [[1.0, 0.3, 0.0], [0.30000000000000004, 1.0, 0.0], [0.0, 0.0, 1.0]]
        mvn = MultivariateNormal([1.0, 1.0, 1.0], corr)
        assert mvn.corr[0][1] == mvn.corr[1][0]

    def test_marginal_keeps_the_chosen_features_in_the_given_order(self):
        corr = [[1.0, 0.1, 0.2], [0.1, 1.0, 0.3], [0.2, 0.3, 1.0]]
        marginal = MultivariateNormal([1.0, 2.0, 3.0], corr).marginal([2, 0])
        assert marginal.sigmas == (3.0, 1.0)
        assert marginal.corr == ((1.0, 0.2), (0.2, 1.0))
