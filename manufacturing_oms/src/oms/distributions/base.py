"""The joint-distribution protocol and tagged probabilities (spec §5.2)."""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import Literal, Protocol

from numpy.typing import ArrayLike

Method = Literal["analytic", "numerical", "monte_carlo"]


@dataclass(frozen=True)
class Probability:
    """A probability with the method that produced it and its absolute error bound (0 for analytic)."""

    value: float
    method: Method
    abs_error: float = 0.0


class JointDistribution(Protocol):
    """Process Variation of a Stage's Features. Means are supplied per call, so one shape serves every state."""

    @property
    def dimension(self) -> int: ...

    @property
    def standard_deviations(self) -> tuple[float, ...]:
        """Marginal spread of each Feature; sets the default optimisation bounds [L − 3σ, U + 3σ]."""
        ...

    def box_probability(
        self, means: ArrayLike, lower: ArrayLike, upper: ArrayLike, *, rng_seed: int = 0
    ) -> Probability:
        """P(lower < X < upper) with X centred on `means`. `rng_seed` seeds any Monte Carlo method used."""
        ...

    def marginal(self, indices: Sequence[int]) -> JointDistribution: ...
