"""Faithful port of `legacy_matlab/historical/StageCostFun_old.m` (test oracle only, ADR 0002).

The predecessor of `StageCostFun`: it takes a full covariance SIGMA and gets its probabilities from
`Probs_1Var`, `Probs_2Var` or `Probs_3Var`, so N ≤ 3. The scrap loop is the same thesis Eq 3.59 (D1),
but PRR comes straight from the `Probs_*Var` port, one entry per Rework State, so the D5 defect is
absent. For N = 3 the pair Rework States drop the correlation (D15). The transition matrix P and
fundamental matrix M are returned with the MATLAB's four outputs.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from oracles.probs_1var import probs_1var
from oracles.probs_2var import probs_2var
from oracles.probs_3var import probs_3var
from oracles.stage_cost_fun import _alpha_m_delta, k_d_matrix, number_of_transient_states, s_matrix_cell


@dataclass(frozen=True)
class StageCostFunOldOutput:
    F_stageC: float
    pIC: float
    Rwi: float
    Sri: float
    P: np.ndarray  # rows and columns I, Υ, Conforming, Scrapped
    M: np.ndarray


def stage_cost_fun_old(MU, SIGMA, U, L, R_Cost, S_Cost):
    """[F_stageC, pIC, Rwi, Sri] = StageCostFun_old(MU, SIGMA, U, L, R_Cost, S_Cost).

    R_Cost has one entry per Rework State in UPv order; S_Cost has the Initial State first, then UPv.
    """
    N = len(MU)
    eta = number_of_transient_states(N)
    SMat_Cell = s_matrix_cell(N)

    probs = {1: probs_1var, 2: probs_2var, 3: probs_3var}[N]
    PIs, PCs, PSs, PRR, ptsCell = probs(SMat_Cell, U, L, MU, SIGMA)

    # Scrap costs
    SCP_Cost = 0.0
    for k in range(1, N + 1):
        alpha, m, delta = _alpha_m_delta(N, eta, k)
        DMat = k_d_matrix(m, PIs, alpha, delta, eta)
        SDMat = SMat_Cell[k - 1] * DMat
        for j in range(1, m + 1):
            a = alpha + j - 2
            # Scrap cost eqn (Eqn 22 in MarkovChainPaper Dodd 2014)
            kSCPi = S_Cost[a] * np.sum(SDMat[:, j - 1] * (PSs[a] / (1 - PRR[a - 1])))
            SCP_Cost = SCP_Cost + kSCPi

    # Transition Matrix
    P = np.zeros((eta + 2, eta + 2))
    P[0, 1:] = PIs
    P[:eta, eta] = PCs
    P[:eta, eta + 1] = PSs
    P[eta, eta] = 1
    P[eta + 1, eta + 1] = 1

    c = 1  # k^GAMMA blocks, eqn 23 in MarkovChainPaper
    for pts in ptsCell:
        pts = np.atleast_2d(pts)
        P[eta - pts.shape[0] : eta, c : c + pts.shape[1]] = pts
        c = c + pts.shape[1]
    Q = P[:eta, :eta]
    R = P[:eta, eta:]
    M = np.linalg.inv(np.eye(len(Q)) - Q)
    F = M @ R

    # Rework Costs
    rw = [R_Cost[i - 1] * M[0, i] for i in range(1, eta)]
    Sri = SCP_Cost + PSs[0] * S_Cost[0]
    Rwi = sum(rw)
    pIC = PCs[0]
    F_stageC = F[0, 0]
    return StageCostFunOldOutput(float(F_stageC), float(pIC), float(Rwi), float(Sri), P, M)
