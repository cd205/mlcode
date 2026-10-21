"""Gaussian Process Variation (spec §5.2, ADR 0003)."""

from __future__ import annotations

import math
from collections.abc import Sequence
from dataclasses import dataclass

import numpy as np
from numpy.typing import ArrayLike
from scipy.special import ndtr

from oms.distributions.base import Method, Probability
from oms.distributions.integrals import bivariate_box, qmc_box, trivariate_box

Correlation = tuple[tuple[float, ...], ...]

_METHOD_RANK: list[Method] = ["analytic", "numerical", "monte_carlo"]
_ROUNDING_TOL = 1e-12  # asymmetry and negative eigenvalues this small are rounding, not a defect
_PERFECT_CORRELATION = 1.0 - 1e-14  # |ρ| this close to 1 is treated as an exact ±1


@dataclass(frozen=True)
class MultivariateNormal:
    """Normal Process Variation: one standard deviation per Feature and a correlation matrix.

    `corr` is a full correlation matrix, or a scalar ρ for equicorrelation (the default 0 is independence).
    """

    sigmas: tuple[float, ...]
    corr: Correlation

    def __init__(self, sigmas: ArrayLike, corr: ArrayLike = 0.0) -> None:
        values = tuple(float(s) for s in np.atleast_1d(np.asarray(sigmas, dtype=float)))
        if not values:
            raise ValueError("MultivariateNormal needs at least one standard deviation")
        if not all(np.isfinite(s) and s > 0 for s in values):
            raise ValueError(f"standard deviations must be positive and finite, got {values}")
        matrix = _correlation_matrix(corr, len(values))
        object.__setattr__(self, "sigmas", values)
        object.__setattr__(self, "corr", tuple(tuple(float(v) for v in row) for row in matrix))

    @property
    def dimension(self) -> int:
        return len(self.sigmas)

    @property
    def standard_deviations(self) -> tuple[float, ...]:
        return self.sigmas

    def marginal(self, indices: Sequence[int]) -> MultivariateNormal:
        idx = list(indices)
        return MultivariateNormal([self.sigmas[i] for i in idx], np.asarray(self.corr)[np.ix_(idx, idx)])

    def box_probability(
        self, means: ArrayLike, lower: ArrayLike, upper: ArrayLike, *, rng_seed: int = 0
    ) -> Probability:
        mu, lo, hi = (np.atleast_1d(np.asarray(a, dtype=float)) for a in (means, lower, upper))
        if not (mu.shape == lo.shape == hi.shape == (self.dimension,)):
            raise ValueError(f"means and limits must each have length {self.dimension}")
        sigma = np.asarray(self.sigmas)
        a, b = (lo - mu) / sigma, (hi - mu) / sigma
        if np.any(b <= a):
            return Probability(0.0, "analytic", 0.0)
        a, b, corr = _merge_perfectly_correlated(a, b, np.asarray(self.corr))
        if np.any(b <= a):
            return Probability(0.0, "analytic", 0.0)
        parts = [
            _block_box(a[block], b[block], corr[np.ix_(block, block)], rng_seed) for block in _independent_blocks(corr)
        ]
        # Every factor is at most 1, so the product's error is bounded by the sum of the factors' errors.
        return Probability(
            value=math.prod(p.value for p in parts),
            method=max((p.method for p in parts), key=_METHOD_RANK.index),
            abs_error=sum(p.abs_error for p in parts),
        )


def _correlation_matrix(corr: ArrayLike, n: int) -> np.ndarray:
    given = np.asarray(corr, dtype=float)
    if given.ndim == 0:
        matrix = np.full((n, n), float(given))
        np.fill_diagonal(matrix, 1.0)
    else:
        matrix = given.copy()
    if matrix.shape != (n, n):
        raise ValueError(f"correlation matrix must be {n}×{n}, got shape {matrix.shape}")
    if not np.all(np.isfinite(matrix)):
        raise ValueError("correlation matrix must be finite")
    if np.max(np.abs(matrix - matrix.T)) > _ROUNDING_TOL:
        raise ValueError("correlation matrix must be symmetric")
    matrix = np.asarray((matrix + matrix.T) / 2, dtype=float)
    if not np.all(np.diag(matrix) == 1.0):
        raise ValueError("correlation matrix must have a unit diagonal")
    if np.any(np.abs(matrix) > 1.0):
        raise ValueError("correlations must lie in [−1, 1]")
    if np.linalg.eigvalsh(matrix)[0] < -_ROUNDING_TOL:
        raise ValueError("correlation matrix must be positive semi-definite")
    return matrix


def _merge_perfectly_correlated(
    a: np.ndarray, b: np.ndarray, corr: np.ndarray
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Fold each Feature with correlation ±1 to an earlier one into that Feature's limits.

    If Z_j = ±Z_i, the condition a_j < Z_j < b_j is an interval on Z_i, so Z_j can be dropped.
    """
    a, b = a.copy(), b.copy()
    keep: list[int] = []
    for j in range(len(a)):
        twin = next((i for i in keep if abs(corr[i, j]) >= _PERFECT_CORRELATION), None)
        if twin is None:
            keep.append(j)
        elif corr[twin, j] > 0:
            a[twin], b[twin] = max(a[twin], a[j]), min(b[twin], b[j])
        else:
            a[twin], b[twin] = max(a[twin], -b[j]), min(b[twin], -a[j])
    return a[keep], b[keep], corr[np.ix_(keep, keep)]


def _independent_blocks(corr: np.ndarray) -> list[list[int]]:
    """Groups of Features linked by non-zero correlation; the box probability factorises over them."""
    n = len(corr)
    unvisited = set(range(n))
    blocks = []
    while unvisited:
        stack = [min(unvisited)]
        unvisited.discard(stack[0])
        block = []
        while stack:
            i = stack.pop()
            block.append(i)
            linked = {j for j in unvisited if corr[i, j] != 0.0}
            unvisited -= linked
            stack.extend(linked)
        blocks.append(sorted(block))
    return blocks


def _block_box(a: np.ndarray, b: np.ndarray, corr: np.ndarray, rng_seed: int) -> Probability:
    """Box probability of one block of mutually correlated standardised Features."""
    if len(a) == 1:
        return Probability(_standard_interval(a[0], b[0]), "analytic", 0.0)
    if len(a) == 2:
        return bivariate_box(a, b, float(corr[0, 1]))
    if len(a) == 3:
        return trivariate_box(a, b, corr)
    return qmc_box(a, b, corr, rng_seed)


def _standard_interval(a: float, b: float) -> float:
    """P(a < Z < b) for a standard Normal Z, evaluated in whichever tail keeps relative precision.

    Using the tail nearer the box makes the result exactly symmetric under reflection (z → −z).
    """
    if b <= a:
        return 0.0
    if a > 0:
        return float(ndtr(-a) - ndtr(-b))
    if b < 0:
        return float(ndtr(b) - ndtr(a))
    return float(1.0 - ndtr(a) - ndtr(-b))
