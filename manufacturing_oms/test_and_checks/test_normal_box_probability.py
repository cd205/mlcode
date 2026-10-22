"""1D Normal box probability (spec §5.2): analytic, tagged with its method and error."""

import math

import pytest

from oms import MultivariateNormal, Probability


def test_two_sigma_box_is_first_pass_conformance_of_fig_3_12():
    p = MultivariateNormal(sigmas=[1.0]).box_probability([5.0], [3.0], [7.0])
    assert p.value == pytest.approx(0.9544997361036416, abs=1e-14)


def test_analytic_result_is_tagged_with_zero_error():
    p = MultivariateNormal(sigmas=[1.0]).box_probability([0.0], [-1.0], [1.0])
    assert isinstance(p, Probability)
    assert p.method == "analytic"
    assert p.abs_error == 0.0


def test_spread_scales_the_box():
    # P(|X - 10| < 2) with σ = 2 is the 1σ coverage.
    p = MultivariateNormal(sigmas=[2.0]).box_probability([10.0], [8.0], [12.0])
    assert p.value == pytest.approx(0.6826894921370859, abs=1e-14)


def test_far_upper_tail_keeps_relative_precision():
    # 1 − Φ(10) = 7.6198530241605e-24; computing it as 1 − Φ would round to 0.
    p = MultivariateNormal(sigmas=[1.0]).box_probability([0.0], [10.0], [math.inf])
    assert p.value == pytest.approx(7.6198530241605e-24, rel=1e-12)


def test_half_infinite_lower_box():
    p = MultivariateNormal(sigmas=[1.0]).box_probability([0.0], [-math.inf], [0.0])
    assert p.value == 0.5


@pytest.mark.parametrize("sigmas", [[0.0], [-1.0], [math.nan]])
def test_spread_must_be_positive_and_finite(sigmas):
    with pytest.raises(ValueError):
        MultivariateNormal(sigmas=sigmas)
