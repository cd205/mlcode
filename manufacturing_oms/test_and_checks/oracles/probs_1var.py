"""Faithful port of `legacy_matlab/validation/Probs_1Var.m` (test oracle only, ADR 0002).

The Rework Side is hard-coded above U. Only element (1) of each input is used, and SIGMA(1) is a variance.
"""

from __future__ import annotations

import math

import numpy as np
from scipy.stats import norm


def probs_1var(smat_cell, U, L, MU, SIGMA):
    """[PIs, PCs, PSs, PRR, ptsCell] = Probs_1Var(SMat_Cell, U, L, MU, SIGMA). SMat_Cell is unused."""
    sig11 = math.sqrt(_first(SIGMA))

    pI2 = 1 - norm.cdf(_first(U), _first(MU), sig11)
    pIS = norm.cdf(_first(L), _first(MU), sig11)
    pIC = 1 - pI2 - pIS

    PIs = [float(pI2), float(pIC), float(pIS)]  # from the Initial State to rework, conformance, scrap
    PCs = [float(pIC), float(pIC)]  # the Rework State reuses the Initial State's probabilities
    PSs = [float(pIS), float(pIS)]
    PRR = [float(pI2)]  # rework to rework
    ptsCell = [[float(pI2)]]
    return PIs, PCs, PSs, PRR, ptsCell


def _first(a):
    """MATLAB A(1): the first element in linear order, of a scalar, vector or matrix."""
    return float(np.ravel(a)[0])
