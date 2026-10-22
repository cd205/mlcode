"""Faithful port of `legacy_matlab/validation/Probs_3Var.m` (test oracle only, ADR 0002).

As `Probs_2Var`: Rework Side hard-coded above U, reflected axes for the joint boxes, SIGMA a
covariance, and the Initial State's means reused for every Rework State (D14). The pair Rework
States {1,2}, {1,3}, {2,3} build a *diagonal* SIGMA from the variances, so they drop any
correlation (D15). The MATLAB's loop over all but the last S-matrix before the GAMMA fill has no
effect and is not ported.
"""

from __future__ import annotations

import math

import numpy as np
from scipy.stats import norm

from oracles.mvncdf import mvncdf
from oracles.probs_2var import _floats, fill_pts_cell


def probs_3var(SMat_Cell, U, L, MU, SIGMA):
    """[PIs, PCs, PSs, PRR, ptsCell] = Probs_3Var(SMat_Cell, U, L, MU, SIGMA)."""
    U, L, MU = (np.asarray(a, dtype=float) for a in (U, L, MU))
    SIGMA = np.asarray(SIGMA, dtype=float)

    MU_R = L + (U - MU)  # reverse the axes
    sig11 = math.sqrt(SIGMA[0, 0])
    sig22 = math.sqrt(SIGMA[1, 1])
    sig33 = math.sqrt(SIGMA[2, 2])

    MU_R5 = [MU_R[0], MU_R[1]]
    SIGMA_5 = [[sig11**2, 0], [0, sig22**2]]
    MU_R6 = [MU_R[0], MU_R[2]]
    SIGMA_6 = [[sig11**2, 0], [0, sig33**2]]
    MU_R7 = [MU_R[1], MU_R[2]]
    SIGMA_7 = [[sig22**2, 0], [0, sig33**2]]

    Fb1b2b3 = mvncdf([U[0], U[1], U[2]], MU_R, SIGMA)
    Fa1b2b3 = mvncdf([L[0], U[1], U[2]], MU_R, SIGMA)
    Fb1a2b3 = mvncdf([U[0], L[1], U[2]], MU_R, SIGMA)
    Fb1b2a3 = mvncdf([U[0], U[1], L[2]], MU_R, SIGMA)
    Fa1a2b3 = mvncdf([L[0], L[1], U[2]], MU_R, SIGMA)
    Fa1b2a3 = mvncdf([L[0], U[1], L[2]], MU_R, SIGMA)
    Fb1a2a3 = mvncdf([U[0], L[1], L[2]], MU_R, SIGMA)
    Fa1a2a3 = mvncdf([L[0], L[1], L[2]], MU_R, SIGMA)

    pI2 = Fa1b2b3 - Fa1a2b3 - Fa1b2a3 + Fa1a2a3  # RW 1st Var
    pI3 = Fb1a2b3 - Fb1a2a3 - Fa1a2b3 + Fa1a2a3  # RW 2nd Var
    pI4 = Fb1b2a3 - Fb1a2a3 - Fa1b2a3 + Fa1a2a3  # RW 3rd Var
    pI5 = Fa1a2b3 - Fa1a2a3  # RW 1st & 2nd Var
    pI6 = Fa1b2a3 - Fa1a2a3  # RW 1st & 3rd Var
    pI7 = Fb1a2a3 - Fa1a2a3  # RW 2nd & 3rd Var
    pI8 = Fa1a2a3  # RW 1st, 2nd & 3rd Var
    pIC = Fb1b2b3 - Fb1b2a3 - Fb1a2b3 - Fa1b2b3 + Fa1b2a3 + Fb1a2a3 + Fa1a2b3 - Fa1a2a3
    pIS = 1 - Fb1b2b3

    # From reworks to other reworks or Scrap
    p2S = norm.cdf(L[0], MU[0], sig11)
    p22 = 1 - norm.cdf(U[0], MU[0], sig11)
    p2C = 1 - p22 - p2S
    p3S = norm.cdf(L[1], MU[1], sig22)
    p33 = 1 - norm.cdf(U[1], MU[1], sig22)
    p3C = 1 - p33 - p3S
    p4S = norm.cdf(L[2], MU[2], sig33)
    p44 = 1 - norm.cdf(U[2], MU[2], sig33)
    p4C = 1 - p44 - p4S

    p52, p53, p55, p5C, p5S = _pair(U[[0, 1]], L[[0, 1]], MU_R5, SIGMA_5)
    p62, p64, p66, p6C, p6S = _pair(U[[0, 2]], L[[0, 2]], MU_R6, SIGMA_6)
    p73, p74, p77, p7C, p7S = _pair(U[[1, 2]], L[[1, 2]], MU_R7, SIGMA_7)

    p82 = pI2
    p83 = pI3
    p84 = pI4
    p85 = pI5
    p86 = pI6
    p87 = pI7
    p88 = pI8
    p8C = pIC
    p8S = pIS

    PIs = _floats([pI2, pI3, pI4, pI5, pI6, pI7, pI8, pIC, pIS])
    PCs = _floats([pIC, p2C, p3C, p4C, p5C, p6C, p7C, p8C])
    PSs = _floats([pIS, p2S, p3S, p4S, p5S, p6S, p7S, p8S])
    PRR = _floats([p22, p33, p44, p55, p66, p77, p88])

    # the 'probability to' vectors, one per S-matrix column: e.g. p84 is from state 8 to state 4
    ptCell = [
        [p22, p52, p62, p82],
        [p33, p53, p73, p83],
        [p44, p64, p74, p84],
        [p55, p85],
        [p66, p86],
        [p77, p87],
        [p88],
    ]
    return PIs, PCs, PSs, PRR, fill_pts_cell(SMat_Cell, ptCell)


def _pair(U, L, MU_R, SIGMA):
    """One pair Rework State's F5b1b2 … block: to its first Feature, its second, both, conformance and scrap."""
    Fb1b2 = mvncdf([U[0], U[1]], MU_R, SIGMA)
    Fa1b2 = mvncdf([L[0], U[1]], MU_R, SIGMA)
    Fb1a2 = mvncdf([U[0], L[1]], MU_R, SIGMA)
    Fa1a2 = mvncdf([L[0], L[1]], MU_R, SIGMA)
    return Fa1b2 - Fa1a2, Fb1a2 - Fa1a2, Fa1a2, Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2, 1 - Fb1b2
