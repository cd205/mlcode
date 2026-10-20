"""State enumeration (thesis Eq 3.47-3.50, spec §2.1): Initial State first, then Rework States by size, then lexicographic."""

from oms import Feature, ReworkSide
from oms.markov import INITIAL_STATE, enumerate_states


def feature(name, side=ReworkSide.UPPER):
    return Feature(name, lower=0.0, upper=1.0, rework_side=side)


def test_one_feature_has_initial_state_then_its_rework_state():
    assert enumerate_states([feature("a")]) == (frozenset(), frozenset({"a"}))


def test_initial_state_is_the_empty_set():
    assert INITIAL_STATE == frozenset()


def test_three_features_follow_the_upsilon_ordering():
    states = enumerate_states([feature("x"), feature("y"), feature("z")])
    assert states == (
        frozenset(),
        frozenset({"x"}),
        frozenset({"y"}),
        frozenset({"z"}),
        frozenset({"x", "y"}),
        frozenset({"x", "z"}),
        frozenset({"y", "z"}),
        frozenset({"x", "y", "z"}),
    )


def test_ordering_follows_feature_order_not_names():
    states = enumerate_states([feature("b"), feature("a")])
    assert states[1:3] == (frozenset({"b"}), frozenset({"a"}))


def test_rework_side_none_yields_no_rework_state():
    assert enumerate_states([feature("a", ReworkSide.NONE)]) == (frozenset(),)


def test_only_reworkable_features_form_rework_states():
    states = enumerate_states(
        [feature("a"), feature("b", ReworkSide.NONE), feature("c", ReworkSide.LOWER)]
    )
    assert states == (frozenset(), frozenset({"a"}), frozenset({"c"}), frozenset({"a", "c"}))
