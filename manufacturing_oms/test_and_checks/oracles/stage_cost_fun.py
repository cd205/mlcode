"""Faithful ports of `legacy_matlab/core/StageCostFun.m`, `Probs_nVars.m`, `kSMatrix.m` and `kDMatrix.m`.

Test oracles only (ADR 0002). `StageCostFun`'s scrap loop is thesis Eq 3.59, the S∘D feed-in formula
that the engine replaces with the exact absorbing-chain expectation (ADR 0001, D1).

MATLAB's 1-based indices are kept in the arithmetic (alpha, delta, a, w, v) and shifted by one only
where a Python list or array is indexed. `combinator(N, k, 'c')` is `itertools.combinations` over
1..N, which yields the same lexicographic rows. The Rework Side is hard-coded above U, `rho` is a
scalar equicorrelation and `sigs` are standard deviations. `PRR` keeps only the non-zero diagonal
entries of Q, as the MATLAB does (D5).
"""

from __future__ import annotations

from itertools import combinations
from math import comb, inf

import numpy as np

from oracles.mvncdf import mvncdf


def combinator(N, K):
    """combinator(N, K, 'c'): rows of 1-based combinations, in lexicographic order."""
    return [list(c) for c in combinations(range(1, N + 1), K)]


def _upsilon(N):
    """UP{k} for k = 1..N (as UP[k - 1]) and UPv, every combination ordered by size then lexicographically."""
    UP = [combinator(N, k) for k in range(1, N + 1)]
    UPv = [row for rows in UP for row in rows]
    return UP, UPv


def _alpha_m_delta(N, eta, k):
    beta = sum(comb(N, i) for i in range(1, k))  # Equation 2.47 Dodd [2014]
    alpha_l = sum(comb(N, i) for i in range(N, k - 1, -1))  # Equation 2.50 Dodd [2014]
    alpha = 2 + (eta - 1) - alpha_l
    m = comb(N, k)
    delta = beta + m
    return alpha, m, delta


def k_s_matrix(k, alpha, eta, m, UP, UPv):
    Ctemp = UP[k - 1]
    SMat = np.zeros((eta - alpha + 1, m))
    for i in range(1, eta - alpha + 2):
        z = alpha - 2 + i
        for j in range(1, m + 1):
            SMat[i - 1, j - 1] = all(c in UPv[z - 1] for c in Ctemp[j - 1])
    return SMat


def k_d_matrix(m, PIs, alpha, delta, eta):
    DMat = np.ones((eta - (alpha - 1), m))
    DMat[:m, :m] = np.eye(m) * np.asarray(PIs[alpha - 2 : delta])
    w = delta + 1
    for i in range(m + 1, eta - (alpha - 1) + 1):
        v = alpha - 1
        for j in range(1, m + 1):
            DMat[i - 1, j - 1] = PIs[w - 1] * PIs[v - 1] / (1 - PIs[w - 1])
            v = v + 1
        w = w + 1
    return DMat


def probs_n_vars(MU, L, U, sigs, rho):
    """[PIs, PSs, PMat] = Probs_nVars(MU, L, U, sigs, rho)."""
    MU, L, U, sigs = (np.asarray(a, dtype=float) for a in (MU, L, U, sigs))
    MU_R = L + (U - MU)  # reverse the axes

    num_vars = len(MU)
    eta = 1 + sum(comb(num_vars, i) for i in range(1, num_vars + 1))

    Rw_vars = [combinator(num_vars, num_vars)] + [combinator(num_vars, i) for i in range(1, num_vars)]
    PCs, PSs, Pps = [], [], []
    for RwIter in Rw_vars:
        for row in RwIter:
            idx = [r - 1 for r in row]
            MU_Ri = MU_R[idx]
            CorrMatrix = rho * np.ones((len(MU_Ri), len(MU_Ri)))
            np.fill_diagonal(CorrMatrix, 1)
            SIGMA = np.outer(sigs[idx], sigs[idx]) * CorrMatrix  # corr2cov
            Lvars = L[idx]
            Uvars = U[idx]
            LocalVars = len(MU_Ri)

            PCs.append(mvncdf(Lvars, Uvars, MU_Ri, SIGMA))  # state to conformance
            PSs.append(1 - mvncdf(Uvars, MU_Ri, SIGMA))  # state to scrap
            for m in range(1, LocalVars + 1):
                for combins in combinations(range(LocalVars), m):
                    Llim = Lvars.copy()
                    Llim[list(combins)] = -inf
                    Ulim = Uvars.copy()
                    Ulim[list(combins)] = Lvars[list(combins)]
                    Pps.append(mvncdf(Llim, Ulim, MU_Ri, SIGMA))

    # S-Matrix
    SMAT = np.zeros((eta - 1, eta - 1))
    UP, UPv = _upsilon(num_vars)
    for k in range(1, num_vars + 1):
        alpha, m, delta = _alpha_m_delta(num_vars, eta, k)
        SMAT[alpha - 2 : eta - 1, alpha - 2 : delta] = k_s_matrix(k, alpha, eta, m, UP, UPv)

    # Transition matrix. find() on the transpose walks SMAT row by row.
    rows, cols = np.nonzero(SMAT[: eta - 2, :])
    PMat = np.zeros((eta + 2, eta + 2))
    for i, (r, c) in enumerate(zip(rows, cols)):
        PMat[r + 1, c + 1] = Pps[eta - 1 + i]

    PMat[0, 1:eta] = Pps[: eta - 1]  # the first row
    PMat[eta - 1, 1:eta] = Pps[: eta - 1]  # the eta row
    PMat[-1, -1] = 1
    PMat[-2, -2] = 1

    PCs = PCs + [PCs[0]]
    PSs = PSs + [PSs[0]]
    PMat[:eta, eta] = PCs
    PMat[:eta, eta + 1] = PSs

    PIs = Pps[: eta - 1] + [PCs[0], PSs[0]]
    return PIs, PSs, PMat


def stage_cost_fun(MU, sigs, rho, U, L, R_Cost, S_Cost):
    """[F_stageC, pIC, Rwi, Sri] = StageCostFun(MU, sigs, rho, U, L, R_Cost, S_Cost).

    R_Cost has one entry per Rework State in UPv order; S_Cost has the Initial State first, then UPv.
    """
    N = len(MU)
    eta = 1 + sum(comb(N, k) for k in range(1, N + 1))  # Equation 2.45 Dodd [2014]
    UP, UPv = _upsilon(N)

    SMat_Cell = []
    for k in range(1, N + 1):
        alpha, m, delta = _alpha_m_delta(N, eta, k)
        SMat_Cell.append(k_s_matrix(k, alpha, eta, m, UP, UPv))

    PIs, PSs, PMat = probs_n_vars(MU, L, U, sigs, rho)
    P = PMat
    Q = P[:eta, :eta]
    R = P[:eta, eta:]
    M = np.linalg.inv(np.eye(len(Q)) - Q)
    F = M @ R
    temp = Q * np.eye(eta)
    PRR = temp.T[temp.T > 0]  # MATLAB's column-major logical indexing

    # Scrap costs (Equation 2.57 Dodd [2014], thesis Eq 3.59)
    SCP_Cost = 0.0
    for k in range(1, N + 1):
        alpha, m, delta = _alpha_m_delta(N, eta, k)
        DMat = k_d_matrix(m, PIs, alpha, delta, eta)
        SDMat = SMat_Cell[k - 1] * DMat
        for j in range(1, m + 1):
            a = alpha + j - 2
            kSCPi = S_Cost[a] * np.sum(SDMat[:, j - 1] * (PSs[a] / (1 - PRR[a - 1])))
            SCP_Cost = SCP_Cost + kSCPi

    # Rework costs
    rw = [R_Cost[i - 1] * M[0, i] for i in range(1, eta)]
    Sri = SCP_Cost + PSs[0] * S_Cost[0]
    Rwi = sum(rw)
    pIC = 1 - PSs[0]
    F_stageC = F[0, 0]
    return float(F_stageC), float(pIC), float(Rwi), float(Sri)
