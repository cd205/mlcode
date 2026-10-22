"""Box probabilities of a standard (zero-mean, unit-variance) correlated Normal (ADR 0003).

- 2 dimensions: Genz's BVNU (Drezner & Wesolowsky 1990, as revised by Genz 2004), deterministic Gauss–Legendre.
- 3 dimensions: adaptive quadrature over one variable of the conditional bivariate box.
- 4 or more: randomised quasi-Monte Carlo (Genz's separation of variables on scrambled Sobol points).
"""

from __future__ import annotations

import math

import numpy as np
from scipy.integrate import quad
from scipy.special import ndtr, ndtri
from scipy.stats import qmc

from oms.distributions.base import Probability

# Genz (2004, Table 1) measures BVNU's error at about 5e-16; four corners are combined per box.
BIVARIATE_ABS_ERROR = 4e-15

# Gauss–Legendre half-rules (points in (0, 1), weights) with 6, 12 and 20 points (Genz's BVNU).
_GL_WEIGHTS = (
    (0.1713244923791705, 0.3607615730481384, 0.4679139345726904),
    (0.04717533638651177, 0.1069393259953183, 0.1600783285433464,
     0.2031674267230659, 0.2334925365383547, 0.2491470458134029),
    (0.01761400713915212, 0.04060142980038694, 0.06267204833410906, 0.08327674157670475,
     0.1019301198172404, 0.1181945319615184, 0.1316886384491766, 0.1420961093183821,
     0.1491729864726037, 0.1527533871307259),
)
_GL_POINTS = (
    (0.9324695142031522, 0.6612093864662647, 0.2386191860831970),
    (0.9815606342467191, 0.9041172563704750, 0.7699026741943050,
     0.5873179542866171, 0.3678314989981802, 0.1252334085114692),
    (0.9931285991850949, 0.9639719272779138, 0.9122344282513259, 0.8391169718222188,
     0.7463319064601508, 0.6360536807265150, 0.5108670019508271, 0.3737060887154196,
     0.2277858511416451, 0.07652652113349733),
)


def bivariate_box(a: np.ndarray, b: np.ndarray, rho: float) -> Probability:
    """P(a < Z < b) for a standard bivariate Normal with correlation rho."""
    h = np.array([a[0], b[0], a[0], b[0]])
    k = np.array([a[1], a[1], b[1], b[1]])
    upper_tails = _bvnu(h, k, rho)
    value = upper_tails[0] - upper_tails[1] - upper_tails[2] + upper_tails[3]
    return Probability(float(min(1.0, max(0.0, value))), "numerical", BIVARIATE_ABS_ERROR)


def _bvnu(dh: np.ndarray, dk: np.ndarray, r: float) -> np.ndarray:
    """P(Z₁ > dh, Z₂ > dk) elementwise, for a standard bivariate Normal with correlation r (Genz's BVNU)."""
    dh, dk = np.broadcast_arrays(np.asarray(dh, dtype=float), np.asarray(dk, dtype=float))
    out = np.empty(dh.shape)
    # Infinite limits reduce to one dimension.
    top = (dh == math.inf) | (dk == math.inf)
    h_free, k_free = dh == -math.inf, dk == -math.inf
    out[top] = 0.0
    out[~top & h_free] = ndtr(-dk[~top & h_free])
    out[~top & ~h_free & k_free] = ndtr(-dh[~top & ~h_free & k_free])
    finite = ~top & ~h_free & ~k_free
    if np.any(finite):
        out[finite] = _bvnu_finite(dh[finite], dk[finite], r)
    return out


def _bvnu_finite(h: np.ndarray, k: np.ndarray, r: float) -> np.ndarray:
    rule = 0 if abs(r) < 0.3 else 1 if abs(r) < 0.75 else 2
    half_x = np.array(_GL_POINTS[rule])
    w = np.concatenate([_GL_WEIGHTS[rule], _GL_WEIGHTS[rule]])
    x = np.concatenate([1.0 - half_x, 1.0 + half_x])
    hk = h * k
    if abs(r) < 0.925:
        hs = (h * h + k * k) / 2
        asr = math.asin(r) / 2
        sn = np.sin(asr * x)  # shape (points,)
        terms = np.exp((sn[None, :] * hk[:, None] - hs[:, None]) / (1 - sn * sn)[None, :])
        bvn = terms @ w * asr / (2 * math.pi) + ndtr(-h) * ndtr(-k)
        return np.asarray(np.clip(bvn, 0.0, 1.0))

    if r < 0:
        k, hk = -k, -hk
    bvn = np.zeros_like(h)
    if abs(r) < 1:
        a_s = (1 - r) * (1 + r)
        a = math.sqrt(a_s)
        bs = (h - k) ** 2
        c = (4 - hk) / 8
        d = (12 - hk) / 80
        asr = -(bs / a_s + hk) / 2
        series = 1 - c * (bs - a_s) * (1 - d * bs) / 3 + c * d * a_s**2
        bvn = np.where(asr > -100, a * np.exp(np.maximum(asr, -100)) * series, 0.0)
        b = np.sqrt(bs)
        sp = math.sqrt(2 * math.pi) * ndtr(-b / a)
        tail = np.exp(-np.maximum(hk, -100) / 2) * sp * b * (1 - c * bs * (1 - d * bs) / 3)
        bvn = bvn - np.where(hk > -100, tail, 0.0)
        a /= 2
        xs = (a * x) ** 2  # shape (points,)
        asr2 = -(bs[:, None] / xs[None, :] + hk[:, None]) / 2
        sp2 = 1 + c[:, None] * xs[None, :] * (1 + 5 * d[:, None] * xs[None, :])
        rs = np.sqrt(1 - xs)
        ep = np.exp(-(hk[:, None] / 2) * xs[None, :] / ((1 + rs) ** 2)[None, :]) / rs[None, :]
        terms = np.where(asr2 > -100, np.exp(np.maximum(asr2, -100)) * (sp2 - ep), 0.0)
        bvn = (a * (terms @ w) - bvn) / (2 * math.pi)
    if r > 0:
        bvn = bvn + ndtr(-np.maximum(h, k))
    else:
        between = np.where(h < 0, ndtr(k) - ndtr(h), ndtr(-h) - ndtr(-k))
        bvn = np.where(h >= k, -bvn, between - bvn)
    return np.asarray(np.clip(bvn, 0.0, 1.0))


# Beyond ±TRUNCATION the outer variable carries less than 2Φ(−12) ≈ 3.6e-33 of probability.
_TRUNCATION = 12.0
_QUAD_ABS_TOL = 1e-13


def trivariate_box(a: np.ndarray, b: np.ndarray, corr: np.ndarray) -> Probability:
    """P(a < Z < b) for a standard trivariate Normal whose correlations are all strictly inside (−1, 1).

    Conditions on the variable least correlated with the other two, so that the conditional bivariate
    is as well spread as possible, then integrates over it with adaptive Gauss–Kronrod quadrature.
    The reported error is quadrature's own estimate plus the bivariate error it integrates.
    """
    outer = int(np.argmin([max(abs(corr[i, j]) for j in range(3) if j != i) for i in range(3)]))
    inner = [j for j in range(3) if j != outer]
    r_outer = corr[outer, inner]
    spread = np.sqrt((1 - r_outer) * (1 + r_outer))
    r_inner = (corr[inner[0], inner[1]] - r_outer[0] * r_outer[1]) / (spread[0] * spread[1])
    r_inner = float(min(1.0, max(-1.0, r_inner)))
    lo, hi = max(a[outer], -_TRUNCATION), min(b[outer], _TRUNCATION)
    if lo >= hi:
        return Probability(0.0, "numerical", BIVARIATE_ABS_ERROR)

    def integrand(z: float) -> float:
        shift = r_outer * z
        box = bivariate_box((a[inner] - shift) / spread, (b[inner] - shift) / spread, r_inner).value
        return _pdf(z) * box

    value, quad_error = quad(integrand, lo, hi, epsabs=_QUAD_ABS_TOL, epsrel=0.0, limit=200)
    return Probability(float(min(1.0, max(0.0, value))), "numerical", float(quad_error) + BIVARIATE_ABS_ERROR)


QMC_POINTS_LOG2 = 12  # 4096 scrambled Sobol points per randomisation
QMC_RANDOMISATIONS = 8
_PIVOT_TOL = 1e-12
_NDTRI_CLIP = (1e-300, 1 - 1e-16)  # keep Φ⁻¹ finite at the ends of the unit interval


def qmc_box(a: np.ndarray, b: np.ndarray, corr: np.ndarray, rng_seed: int) -> Probability:
    """P(a < Z < b) by Genz's separation of variables on independently scrambled Sobol point sets.

    The value is the mean over the randomisations and the reported error is its standard error, so
    the same seed always gives the same result. Variables are ordered so that the most constraining
    come first (Gibson, Glasbey & Elston 1994), which cuts the variance substantially.
    """
    a, b, chol = _ordered_cholesky(a, b, corr)
    n = len(a)
    rng = np.random.default_rng(rng_seed)
    estimates = []
    for _ in range(QMC_RANDOMISATIONS):
        w = qmc.Sobol(d=max(n - 1, 1), scramble=True, rng=rng).random_base2(QMC_POINTS_LOG2)
        estimates.append(float(np.mean(_separated_integrand(a, b, chol, w))))
    value = float(np.mean(estimates))
    error = float(np.std(estimates, ddof=1) / math.sqrt(QMC_RANDOMISATIONS))
    return Probability(min(1.0, max(0.0, value)), "monte_carlo", error)


def _ordered_cholesky(a: np.ndarray, b: np.ndarray, corr: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Cholesky factor of corr with variables reordered by smallest expected conditional box probability.

    A zero pivot (a semi-definite matrix) leaves a zero column: that variable is then fixed by the earlier ones.
    """
    n = len(a)
    a, b, c = a.copy(), b.copy(), corr.copy()
    chol = np.zeros((n, n))
    expected = np.zeros(n)  # E[Y_i] of each placed variable's truncated conditional, used for ordering
    for i in range(n):
        best, best_prob = i, math.inf
        for j in range(i, n):
            shift = chol[j, :i] @ expected[:i]
            spread = math.sqrt(max(c[j, j] - chol[j, :i] @ chol[j, :i], 0.0))
            if spread > _PIVOT_TOL:
                prob = _interval(np.array([(a[j] - shift) / spread]), np.array([(b[j] - shift) / spread]))[0]
                if prob < best_prob:
                    best, best_prob = j, prob
        for arr in (a, b):
            arr[[i, best]] = arr[[best, i]]
        c[[i, best], :] = c[[best, i], :]
        c[:, [i, best]] = c[:, [best, i]]
        chol[[i, best], :] = chol[[best, i], :]
        pivot = c[i, i] - chol[i, :i] @ chol[i, :i]
        if pivot <= _PIVOT_TOL:
            continue  # zero column; the remaining variables are all determined
        chol[i, i] = math.sqrt(pivot)
        for k in range(i + 1, n):
            chol[k, i] = (c[k, i] - chol[k, :i] @ chol[i, :i]) / chol[i, i]
        lo, hi = (a[i] - chol[i, :i] @ expected[:i]) / chol[i, i], (b[i] - chol[i, :i] @ expected[:i]) / chol[i, i]
        mass = _interval(np.array([lo]), np.array([hi]))[0]
        expected[i] = (_pdf(lo) - _pdf(hi)) / mass if mass > 0 else 0.0
    return a, b, chol


def _separated_integrand(a: np.ndarray, b: np.ndarray, chol: np.ndarray, w: np.ndarray) -> np.ndarray:
    n, m = len(a), len(w)
    f = np.ones(m)
    y = np.zeros((m, n))
    for i in range(n):
        shift = y[:, :i] @ chol[i, :i]
        if chol[i, i] == 0.0:
            f *= (shift > a[i]) & (shift < b[i])
            continue
        lo, hi = (a[i] - shift) / chol[i, i], (b[i] - shift) / chol[i, i]
        f *= _interval(lo, hi)
        if i < n - 1:
            d, e = ndtr(lo), ndtr(hi)
            y[:, i] = ndtri(np.clip(d + w[:, i] * (e - d), *_NDTRI_CLIP))
    return f


def _interval(lo: np.ndarray, hi: np.ndarray) -> np.ndarray:
    """Φ(hi) − Φ(lo) elementwise, in whichever tail keeps precision."""
    upper_tail = lo > 0
    return np.where(upper_tail, ndtr(-lo) - ndtr(-hi), ndtr(hi) - ndtr(lo)).clip(0.0, 1.0)


def _pdf(z: float) -> float:
    return math.exp(-z * z / 2) / math.sqrt(2 * math.pi) if math.isfinite(z) else 0.0
