"""Gaussian Process Variation (spec §5.2). Stage 1 provides the analytic 1D box; 2D and above arrive in Stage 2."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass

import numpy as np
from numpy.typing import ArrayLike
from scipy.special import ndtr

from oms.distributions.base import Probability


@dataclass(frozen=True)
class MultivariateNormal:
    """Independent-for-now Normal Process Variation with one standard deviation per Feature."""

    sigmas: tuple[float, ...]

    def __init__(self, sigmas: ArrayLike) -> None:
        values = tuple(float(s) for s in np.atleast_1d(np.asarray(sigmas, dtype=float)))
        if not values:
            raise ValueError("MultivariateNormal needs at least one standard deviation")
        if not all(np.isfinite(s) and s > 0 for s in values):
            raise ValueError(f"standard deviations must be positive and finite, got {values}")
        object.__setattr__(self, "sigmas", values)

    @property
    def dimension(self) -> int:
        return len(self.sigmas)

    @property
    def standard_deviations(self) -> tuple[float, ...]:
        return self.sigmas

    def marginal(self, indices: Sequence[int]) -> MultivariateNormal:
        return MultivariateNormal([self.sigmas[i] for i in indices])

    def box_probability(self, means: ArrayLike, lower: ArrayLike, upper: ArrayLike) -> Probability:
        mu, lo, hi = (np.atleast_1d(np.asarray(a, dtype=float)) for a in (means, lower, upper))
        if not (mu.shape == lo.shape == hi.shape == (self.dimension,)):
            raise ValueError(f"means and limits must each have length {self.dimension}")
        if self.dimension != 1:
            raise NotImplementedError("box probabilities above 1D arrive in Stage 2 (U1)")
        return Probability(_normal_interval(mu[0], self.sigmas[0], lo[0], hi[0]), "analytic", 0.0)


def _normal_interval(mean: float, sigma: float, lower: float, upper: float) -> float:
    """P(lower < X < upper) for X ~ N(mean, sigma²), evaluated in whichever tail keeps relative precision.

    Using the tail nearer the box makes the result exactly symmetric under reflection (x → −x).
    """
    if upper <= lower:
        return 0.0
    a = (lower - mean) / sigma
    b = (upper - mean) / sigma
    if a > 0:
        return float(ndtr(-a) - ndtr(-b))
    if b < 0:
        return float(ndtr(b) - ndtr(a))
    return float(1.0 - ndtr(a) - ndtr(-b))
