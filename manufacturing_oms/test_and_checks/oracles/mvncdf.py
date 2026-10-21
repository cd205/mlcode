"""MATLAB `mvncdf` for the oracle ports: `mvncdf(X, mu, SIGMA)` and `mvncdf(XL, XU, mu, SIGMA)`.

A diagonal SIGMA is a product of univariate CDFs, exact to rounding. Otherwise SciPy's randomised
QMC is used with a tight tolerance and a fixed seed, so the oracle is deterministic. It is not the
engine's algorithm (ADR 0003), which keeps the two independent.
"""

from __future__ import annotations

import numpy as np
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
    return float(
        multivariate_normal.cdf(
            upper, mean=mu, cov=sigma, lower_limit=lower, abseps=1e-12, releps=1e-12, maxpts=10_000_000, rng=0
        )
    )
