"""Stage 0 smoke test: the package imports and the numerical stack works."""

import numpy as np
from scipy.stats import norm

import oms


def test_package_imports():
    assert oms.__name__ == "oms"


def test_numerical_stack():
    # Two-sided 2σ coverage of a standard Normal (thesis Fig 3.12 first-pass conformance).
    assert np.isclose(norm.cdf(2) - norm.cdf(-2), 0.9545, atol=1e-4)
