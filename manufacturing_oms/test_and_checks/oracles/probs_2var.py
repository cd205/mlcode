"""Faithful port of `legacy_matlab/validation/Probs_2Var.m` (test oracle only, ADR 0002).

The Rework Side is hard-coded above U. The joint box is taken on reflected axes (MU_R = L + U − MU),
so "below L" on the reflected axis is "above U" on the real one. SIGMA is a covariance matrix. The
Rework States reuse the Initial State's means (D14).
"""

from __future__ import annotations

import math

import numpy as np
from scipy.stats import norm

from oracles.mvncdf import mvncdf


def probs_2var(SMat_Cell, U, L, MU, SIGMA):
    """[PIs, PCs, PSs, PRR, ptsCell] = Probs_2Var(SMat_Cell, U, L, MU, SIGMA)."""
    U, L, MU = (np.asarray(a, dtype=float) for a in (U, L, MU))
    SIGMA = np.asarray(SIGMA, dtype=float)

    MU_R = L + (U - MU)  # reverse the axes
    sig11 = math.sqrt(SIGMA[0, 0])
    sig22 = math.sqrt(SIGMA[1, 1])

    Fb1b2 = mvncdf([U[0], U[1]], MU_R, SIGMA)
    Fa1b2 = mvncdf([L[0], U[1]], MU_R, SIGMA)
    Fb1a2 = mvncdf([U[0], L[1]], MU_R, SIGMA)
    Fa1a2 = mvncdf([L[0], L[1]], MU_R, SIGMA)

    pI2 = Fa1b2 - Fa1a2
    pI3 = Fb1a2 - Fa1a2
    pI4 = Fa1a2
    pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2
    pIS = 1 - Fb1b2

    p22 = 1 - norm.cdf(U[0], MU[0], sig11)
    p2C = norm.cdf(U[0], MU[0], sig11) - norm.cdf(L[0], MU[0], sig11)  # "not used" in the MATLAB, but it is
    p2S = norm.cdf(L[0], MU[0], sig11)
    p33 = 1 - norm.cdf(U[1], MU[1], sig22)
    p3C = norm.cdf(U[1], MU[1], sig22) - norm.cdf(L[1], MU[1], sig22)
    p3S = norm.cdf(L[1], MU[1], sig22)

    p42 = pI2
    p43 = pI3
    p44 = pI4
    p4C = pIC
    p4S = pIS

    PIs = _floats([pI2, pI3, pI4, pIC, pIS])
    PCs = _floats([pIC, p2C, p3C, p4C])
    PSs = _floats([pIS, p2S, p3S, p4S])
    PRR = _floats([p22, p33, p44])

    # the 'probability to' vectors, one per S-matrix column: e.g. p42 is from state 4 to state 2
    ptCell = [[p22, p42], [p33, p43], [p44]]
    return PIs, PCs, PSs, PRR, fill_pts_cell(SMat_Cell, ptCell)


def fill_pts_cell(SMat_Cell, ptCell):
    """The GAMMA matrices: each S-matrix with its ones replaced, column by column, by the next 'probability to' entries."""
    ptsCell = []
    c = 0
    for SMatLog in SMat_Cell:
        pts = np.zeros(SMatLog.shape)
        for i in range(SMatLog.shape[1]):
            r = 0
            for j in range(SMatLog.shape[0]):
                if SMatLog[j, i] == 1:
                    pts[j, i] = ptCell[c][r]
                    r = r + 1
            c = c + 1
        ptsCell.append(pts)
    return ptsCell


def _floats(values):
    return [float(v) for v in values]
