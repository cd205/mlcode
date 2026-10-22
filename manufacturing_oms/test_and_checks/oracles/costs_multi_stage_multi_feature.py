"""Faithful port of `legacy_matlab/production/Costs_MultiStage_MultiFeature.m` (test oracle only, ADR 0002).

The MATLAB is a script. Its active part runs two Sequences of two Stages each, and evaluates each
Sequence twice: once through `StageCostFun_old` (full SIGMA) and once through `StageCostFun` (σ and a
scalar ρ, the "NEW METHOD"). Both loops compose thesis Eq 3.78. The two Sequences' hard-coded inputs
are kept as `TWO_STAGE_SINGLE_FEATURE` (R5, Table 3.5) and `TWO_STAGE_DUAL_FEATURE`. The commented-out
blocks are single-Stage checks covered by other oracles, so they are not ported.

The script has no Inspection Cost. Its Rework Side is hard-coded above U. Its `RwCost_vec` and
`SrCost_vec` weight Stage i by f_{C,i−1} rather than r_i, but they are never used and are not ported.
"""

from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from oracles.stage_cost_fun import stage_cost_fun
from oracles.stage_cost_fun_old import stage_cost_fun_old

# "2 Stage, single feature production". MU_cell{2} is 15.575, not the 15.591 Table 3.5 prints.
TWO_STAGE_SINGLE_FEATURE = dict(
    SP=120.0,
    PC=[25.0, 20.0],
    U_cell=[[12.0], [17.0]],
    L_cell=[[8.0], [13.0]],
    MU_cell=[[10.466], [15.575]],
    SIGMA_cell=[[[1.0]], [[1.0]]],
    S_Cost_cell=[[10.0, 10.0], [27.0, 27.0]],
    R_Cost_cell=[[15.0], [12.0]],
)

# "2 Stage, dual feature production"
TWO_STAGE_DUAL_FEATURE = dict(
    SP=120.0,
    PC=[45.0, 0.0],
    U_cell=[[12.0, 17.0], [15.0, 12.0]],
    L_cell=[[8.0, 13.0], [5.0, 6.0]],
    MU_cell=[[10.55137, 15.60796], [10.0, 9.0]],
    SIGMA_cell=[[[1.0, 0.0], [0.0, 1.0]], [[0.25, 0.0], [0.0, 0.25]]],
    S_Cost_cell=[[8.0, 9.0, 11.0, 14.0], [7.0, 10.0, 7.0, 10.0]],
    R_Cost_cell=[[15.0, 12.0, 20.0], [12.0, 13.0, 25.0]],
)


@dataclass(frozen=True)
class SequenceLoopOutput:
    F_stageC_vec: list[float]  # 1, then each Stage's f_C
    ProdCost: list[float]  # (PC_i + Sr_i + Rw_i) · Π_{l<i} f_{C,l}
    ProdCost_total: float  # ProdCost1 / ProdCost2
    EP: float  # EP1 / EP2


@dataclass(frozen=True)
class CostsMultiStageMultiFeatureOutput:
    old_method: SequenceLoopOutput  # StageCostFun_old
    new_method: SequenceLoopOutput  # StageCostFun


def costs_multi_stage_multi_feature(SP, PC, U_cell, L_cell, MU_cell, SIGMA_cell, S_Cost_cell, R_Cost_cell, rho=0.0):
    """Both loops of one block of the script. The NEW METHOD's `sigs_cell` is √diag(SIGMA), as in the script."""

    def old(i):
        out = stage_cost_fun_old(MU_cell[i], np.asarray(SIGMA_cell[i], dtype=float), U_cell[i], L_cell[i],
                                 R_Cost_cell[i], S_Cost_cell[i])
        return out.F_stageC, out.Rwi, out.Sri

    def new(i):
        sigs = np.sqrt(np.diag(np.asarray(SIGMA_cell[i], dtype=float)))
        F_stageC, _, Rwi, Sri = stage_cost_fun(MU_cell[i], sigs, rho, U_cell[i], L_cell[i], R_Cost_cell[i],
                                               S_Cost_cell[i])
        return F_stageC, Rwi, Sri

    def loop(stage_cost):
        F_stageC_vec = [1.0]
        ProdCost = []
        for i in range(len(U_cell)):
            F_stageC, Rwi, Sri = stage_cost(i)
            F_stageC_vec.append(F_stageC)  # store conformance from previous stage
            ProdCost.append((PC[i] + Sri + Rwi) * float(np.prod(F_stageC_vec[: i + 1])))
        EP = SP * float(np.prod(F_stageC_vec[1:])) - sum(ProdCost)
        return SequenceLoopOutput(F_stageC_vec, ProdCost, sum(ProdCost), EP)

    return CostsMultiStageMultiFeatureOutput(old_method=loop(old), new_method=loop(new))
