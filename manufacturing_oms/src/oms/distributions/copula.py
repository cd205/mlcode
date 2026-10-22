"""Gaussian copula Process Variation with arbitrary continuous marginals (spec §5.2, Stage 7)."""

from __future__ import annotations

import math
from collections.abc import Sequence
from dataclasses import dataclass, field
from typing import Protocol

import numpy as np
from numpy.typing import ArrayLike
from scipy.special import ndtri

from oms.distributions.base import Probability
from oms.distributions.normal import Correlation, MultivariateNormal

_CENTRING_TOL = 1e-9  # a marginal's centre may differ from 0 by this fraction of its spread
_NORMAL_IQR = 2 * float(ndtri(0.75))  # interquartile range of a standard Normal


class Marginal(Protocol):
    """A continuous one-dimensional distribution, such as a frozen `scipy.stats` distribution."""

    def cdf(self, x: float) -> float: ...
    def sf(self, x: float) -> float: ...
    def ppf(self, q: float) -> float: ...
    def mean(self) -> float: ...
    def median(self) -> float: ...
    def std(self) -> float: ...


@dataclass(frozen=True, eq=False)
class GaussianCopula:
    """Process Variation whose Features have the given marginals, joined by a Gaussian copula with `corr`.

    A Feature made at Mean Setting μ takes the value μ + Y, where Y is drawn from its marginal, so each
    marginal must be centred on 0: its mean is 0, or its median is 0 when it has no mean. `corr` is the
    copula's correlation matrix (of the Features' normal scores), or a scalar ρ for equicorrelation.
    """

    marginals: tuple[Marginal, ...]
    corr: Correlation
    _spreads: tuple[float, ...] = field(init=False, repr=False)
    _normal_scores: MultivariateNormal = field(init=False, repr=False)

    def __init__(self, marginals: Sequence[Marginal], corr: ArrayLike = 0.0) -> None:
        dists = tuple(marginals)
        if not dists:
            raise ValueError("GaussianCopula needs at least one marginal")
        spreads = tuple(_spread(d) for d in dists)
        for i, (d, spread) in enumerate(zip(dists, spreads)):
            centre = float(d.mean())
            if not math.isfinite(centre):
                centre = float(d.median())
            if abs(centre) > _CENTRING_TOL * spread:
                raise ValueError(f"marginal {i} must be centred on 0 (its Mean Setting is added), got {centre}")
        # The normal scores are standard Normal with the copula's correlation; this also validates `corr`.
        scores = MultivariateNormal(np.ones(len(dists)), corr)
        object.__setattr__(self, "marginals", dists)
        object.__setattr__(self, "corr", scores.corr)
        object.__setattr__(self, "_spreads", spreads)
        object.__setattr__(self, "_normal_scores", scores)

    @property
    def dimension(self) -> int:
        return len(self.marginals)

    @property
    def standard_deviations(self) -> tuple[float, ...]:
        """Each marginal's standard deviation, or its IQR / 1.349 (the Normal equivalent) when it has none."""
        return self._spreads

    def marginal(self, indices: Sequence[int]) -> GaussianCopula:
        idx = list(indices)
        return GaussianCopula([self.marginals[i] for i in idx], np.asarray(self.corr)[np.ix_(idx, idx)])

    def box_probability(
        self, means: ArrayLike, lower: ArrayLike, upper: ArrayLike, *, rng_seed: int = 0
    ) -> Probability:
        """P(lower < X < upper), as the standard Normal box between the limits' normal scores.

        Each marginal CDF is increasing, so X_i < x exactly when its normal score Z_i < Φ⁻¹(F_i(x − μ_i)).
        Inclusion–exclusion of the copula C(u) = Φ_R(Φ⁻¹(u)) over the 2^d corners is therefore the
        Gaussian box of ADR 0003, which already combines its corners without losing precision.
        """
        mu, lo, hi = (np.atleast_1d(np.asarray(a, dtype=float)) for a in (means, lower, upper))
        if not (mu.shape == lo.shape == hi.shape == (self.dimension,)):
            raise ValueError(f"means and limits must each have length {self.dimension}")
        a = [_normal_score(d, x) for d, x in zip(self.marginals, lo - mu)]
        b = [_normal_score(d, x) for d, x in zip(self.marginals, hi - mu)]
        return self._normal_scores.box_probability(np.zeros(self.dimension), a, b, rng_seed=rng_seed)


def _normal_score(dist: Marginal, x: float) -> float:
    """Φ⁻¹(F(x)), from whichever tail keeps precision."""
    if x == -math.inf:
        return -math.inf
    if x == math.inf:
        return math.inf
    below = float(dist.cdf(x))
    if below <= 0.5:
        return float(ndtri(below))
    return -float(ndtri(float(dist.sf(x))))


def _spread(dist: Marginal) -> float:
    std = float(dist.std())
    if math.isfinite(std) and std > 0:
        return std
    iqr = float(dist.ppf(0.75)) - float(dist.ppf(0.25))
    if not (math.isfinite(iqr) and iqr > 0):
        raise ValueError("a marginal must have a positive, finite spread")
    return iqr / _NORMAL_IQR
