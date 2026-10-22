"""Transient-state enumeration for one Stage (thesis Eq 3.47-3.50, spec §2.1)."""

from __future__ import annotations

from collections.abc import Iterable
from itertools import combinations
from typing import TYPE_CHECKING

if TYPE_CHECKING:  # model imports this module, so only the type is needed here
    from oms.model.feature import Feature

State = frozenset[str]

INITIAL_STATE: State = frozenset()


def enumerate_states(features: Iterable[Feature]) -> tuple[State, ...]:
    """The Initial State, then one Rework State per non-empty subset of reworkable Features.

    Rework States are ordered by size, then lexicographically in Feature order (the thesis's Υ ordering).
    """
    reworkable = [f.name for f in features if f.reworkable]
    states: list[State] = [INITIAL_STATE]
    for size in range(1, len(reworkable) + 1):
        states.extend(frozenset(group) for group in combinations(reworkable, size))
    return tuple(states)


def processed_features(state: State, features: Iterable[Feature]) -> tuple[str, ...]:
    """D(s): every Feature from the Initial State, otherwise the reworked subset, in Feature order."""
    names = [f.name for f in features]
    if state == INITIAL_STATE:
        return tuple(names)
    return tuple(n for n in names if n in state)
