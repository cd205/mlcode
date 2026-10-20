"""Faithful port of `legacy_matlab/production/Fun_CMC_Markov.m` (test oracle only, ADR 0002).

The MATLAB returns only Profit. Its locals are returned too so that m and f_C can be compared.
Limits, σ and costs are hard-coded as in the MATLAB, and the Rework Side is above USL. `cut` is a
scalar: the MATLAB divides with `/`, not `./`, so a vector `cut` errors or gives a least-squares value.
"""

from __future__ import annotations

from dataclasses import dataclass

from scipy.stats import norm


@dataclass(frozen=True)
class FunCMCMarkovOutput:
    TOT_Scrap: float
    TOT_Confm: float
    TOT_Rwork: float
    TOT: float
    ProdCost: float
    Profit: float


def fun_cmc_markov(cut: float) -> FunCMCMarkovOutput:
    LSL = 2; USL = 8; sigma = 1  # noqa: E702
    SP = 21; PC = 7; SC = 15; RC = 7  # noqa: E702

    p1r = (1 - norm.cdf(USL, cut, sigma))  # Rework
    p1a = (norm.cdf(USL, cut, sigma) - norm.cdf(LSL, cut, sigma))  # Conformance
    p1s = (norm.cdf(LSL, cut, sigma))  # scrap
    TOT_Scrap = p1s / (1 - p1r)
    TOT_Confm = p1a / (1 - p1r)
    TOT_Rwork = 1 / (1 - p1r) - 1

    TOT = TOT_Confm + TOT_Scrap
    ProdCost = PC + SC * (TOT_Scrap) + RC * (TOT_Rwork)
    Profit = SP * TOT_Confm - PC - SC * (TOT_Scrap) - RC * (TOT_Rwork)
    return FunCMCMarkovOutput(*(float(v) for v in (TOT_Scrap, TOT_Confm, TOT_Rwork, TOT, ProdCost, Profit)))
