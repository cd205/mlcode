"""MATLAB `mvncdf` for the oracle ports: `mvncdf(X, mu, SIGMA)` and `mvncdf(XL, XU, mu, SIGMA)`.

A diagonal SIGMA is a product of univariate CDFs, exact to rounding. A correlated 3D box is Genz's
separation of variables integrated by nested adaptive quadrature over univariate Φ: SciPy's QMC
only reaches about 3e-8 there at 1e7 points. Otherwise SciPy's randomised QMC is used with a tight
tolerance and a fixed seed, so the oracle is deterministic. Neither is the engine's algorithm
(ADR 0003), which keeps the two independent.
"""

from __future__ import annotations

import numpy as np
from scipy import integrate
from scipy.special import ndtr, ndtri
from scipy.stats import multivariate_normal, norm


def mvncdf(*args):
    if len(args) == 3:
        upper, mu, sigma = args
        lower = np.full(np.size(upper), -np.inf)
    elif len(args) == 4:
        lower, upper, mu, sigma = args
    else:
        raise TypeError("mvncdf takes (X, mu, SIGMA) or (XL, XU, mu, SIGMA)")
    lower, upper, mu = (np.atleast_1d(np.asarray(a, dtype=float)) for a in (lower, upper, mu))
    sigma = np.atleast_2d(np.asarray(sigma, dtype=float))
    if np.count_nonzero(sigma - np.diag(np.diag(sigma))) == 0:
        sd = np.sqrt(np.diag(sigma))
        return float(np.prod(norm.cdf(upper, mu, sd) - norm.cdf(lower, mu, sd)))
    if len(mu) == 3:
        return _separation_of_variables_3d(lower - mu, upper - mu, sigma)
    return float(
        multivariate_normal.cdf(
            upper, mean=mu, cov=sigma, lower_limit=lower, abseps=1e-12, releps=1e-12, maxpts=10_000_000, rng=0
        )
    )


def _separation_of_variables_3d(a, b, sigma):
    """P(a ≤ C z ≤ b), z standard normal and C the Cholesky factor, with u_i = Φ(z_i) integrated over [0, 1]²."""
    (c11, _, _), (c21, c22, _), (c31, c32, c33) = np.linalg.cholesky(sigma).tolist()
    a1, a2, a3 = a.tolist()
    b1, b2, b3 = b.tolist()

    def innermost(u2, u1):
        shift = c31 * ndtri(u1) + c32 * ndtri(u2)
        return ndtr((b3 - shift) / c33) - ndtr((a3 - shift) / c33)

    value, _ = integrate.dblquad(
        innermost,
        ndtr(a1 / c11),
        ndtr(b1 / c11),
        lambda u1: ndtr((a2 - c21 * ndtri(u1)) / c22),
        lambda u1: ndtr((b2 - c21 * ndtri(u1)) / c22),
        epsabs=1e-12,
        epsrel=1e-12,
    )
    return float(value)
