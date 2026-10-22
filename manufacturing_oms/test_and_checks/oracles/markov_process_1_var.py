"""Faithful port of `legacy_matlab/validation/MarkovProcess_1_Var.m` (test oracle only, ADR 0002).

The MATLAB is a script. Its hard-coded inputs become keyword defaults, and the values it prints
(and the intermediates they use) are returned. The Rework Side is hard-coded above USL.
"""

from __future__ import annotations

from dataclasses import dataclass

from scipy.stats import norm


@dataclass(frozen=True)
class MarkovProcess1VarOutput:
    # Conventional model (Bowling 2004): one transient state looping back on itself.
    p11: float
    p12: float
    p13: float
    m11: float
    f12: float
    f13: float
    EPR_conventional: float
    # Alternative series model: Initial State I and Rework State 2.
    pI2: float
    pIC: float
    pIS: float
    p22: float
    p2C: float
    p2S: float
    mI2: float
    m22: float
    fIC: float
    fIS: float
    f2C: float
    f2S: float
    EPR_series: float


def markov_process_1_var(
    *,
    SP: float = 120,
    PC1: float = 45,
    RC1: float = 3,
    SC1: float = 3,
    cut: float = 4.5,
    sig11: float = 1.7,
    LSLx1: float = 3,
    USLx1: float = 7,
) -> MarkovProcess1VarOutput:
    # conventional model Bowling 2004
    p11 = 1 - norm.cdf(USLx1, cut, sig11)
    p12 = norm.cdf(USLx1, cut, sig11) - norm.cdf(LSLx1, cut, sig11)
    p13 = norm.cdf(LSLx1, cut, sig11)

    m11 = 1 / (1 - p11)

    f12 = p12 / (1 - p11)
    f13 = p13 / (1 - p11)

    EPR_conventional = SP * f12 - PC1 - SC1 * f13 - RC1 * (m11 - 1)

    # Alternative series model
    pI2 = 1 - norm.cdf(USLx1, cut, sig11)
    pIC = norm.cdf(USLx1, cut, sig11) - norm.cdf(LSLx1, cut, sig11)
    pIS = norm.cdf(LSLx1, cut, sig11)

    p22 = pI2
    p2C = pIC
    p2S = pIS

    mI2 = pI2 / (1 - p22)
    m22 = 1 / (1 - p22)

    fIC = pIC + (pI2 * p2C / (1 - p22))
    fIS = pIS + (pI2 * p2S / (1 - p22))
    f2C = p2C / (1 - p22)
    f2S = p2S / (1 - p22)

    EPR_series = SP * fIC - PC1 - (SC1 * pIS + SC1 * pI2 * (p2S / (1 - p22))) - RC1 * mI2

    values = dict(
        p11=p11, p12=p12, p13=p13, m11=m11, f12=f12, f13=f13, EPR_conventional=EPR_conventional,
        pI2=pI2, pIC=pIC, pIS=pIS, p22=p22, p2C=p2C, p2S=p2S, mI2=mI2, m22=m22,
        fIC=fIC, fIS=fIS, f2C=f2C, f2S=f2S, EPR_series=EPR_series,
    )
    return MarkovProcess1VarOutput(**{k: float(v) for k, v in values.items()})
