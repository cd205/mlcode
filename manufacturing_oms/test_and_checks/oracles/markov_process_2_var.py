"""Faithful port of `legacy_matlab/validation/MarkovProcess_2_Var.m` (test oracle only, ADR 0002).

The MATLAB is a script: two one-Feature Stages in series, evaluated three ways. Its hard-coded
inputs become keyword defaults, and the values it prints (and the intermediates they use) are
returned. The Rework Side is hard-coded above USL, and each Rework State reuses its Stage's mean
(D14). The "Modified Approach" `fIC` multiplies `pIC*pI2` where `ip2C*pI2` is meant; the two are
equal because ip2C = pIC.
"""

from __future__ import annotations

from dataclasses import dataclass

from scipy.stats import norm


@dataclass(frozen=True)
class MarkovProcess2VarOutput:
    # Conventional model (Bowling 2004)
    p11: float
    p12: float
    p14: float
    p22: float
    p23: float
    p24: float
    m11: float
    m22: float
    f13: float
    f24: float
    EPR_conventional: float
    # Alternative series model
    mIi2: float
    mIIii2: float
    fIC: float
    fIIS: float
    EPR_modified: float
    # Generalised multistage approach
    mI1_2: float
    fI1_C: float
    SR_1: float
    RW_1: float
    mI2_2: float
    fI2_C: float
    SR_2: float
    RW_2: float
    PC_Tot: float
    SR_Tot: float
    RW_Tot: float
    SP_Tot: float
    EPR_generalised: float


def markov_process_2_var(
    *,
    SP: float = 100,
    PC1: float = 4,
    PC2: float = 6,
    RC1: float = 1,
    RC2: float = 2,
    SC1: float = 5,
    SC2: float = 3,
    CUT=(5, 6.9),
    sig11: float = 1.5,
    sig22: float = 3.9,
    LSLx1: float = 1,
    LSLx2: float = 3,
    USLx1: float = 7,
    USLx2: float = 6,
) -> MarkovProcess2VarOutput:
    # conventional model Bowling 2004
    p11 = 1 - norm.cdf(USLx1, CUT[0], sig11)
    p12 = norm.cdf(USLx1, CUT[0], sig11) - norm.cdf(LSLx1, CUT[0], sig11)
    p14 = norm.cdf(LSLx1, CUT[0], sig11)
    p22 = 1 - norm.cdf(USLx2, CUT[1], sig22)
    p23 = norm.cdf(USLx2, CUT[1], sig22) - norm.cdf(LSLx2, CUT[1], sig22)
    p24 = norm.cdf(LSLx2, CUT[1], sig22)

    m11 = 1 / (1 - p11)
    m22 = 1 / (1 - p22)

    f13 = p12 * p23 / ((1 - p11) * (1 - p22))
    f24 = p24 / (1 - p22)

    EPR_conventional = (
        SP * f13
        - (PC1 + PC2 * p12 / (1 - p11))
        - (SC1 * p14 / (1 - p11) + SC2 * (p12 / (1 - p11)) * f24)
        - (RC1 * (m11 - 1) + RC2 * (m22 - 1) * (p12 / (1 - p11)))
    )

    # Alternative series model
    pI2 = 1 - norm.cdf(USLx1, CUT[0], sig11)
    pIC = norm.cdf(USLx1, CUT[0], sig11) - norm.cdf(LSLx1, CUT[0], sig11)
    pIS = norm.cdf(LSLx1, CUT[0], sig11)
    ip22 = pI2
    ip2C = pIC
    ip2S = pIS

    pII2 = 1 - norm.cdf(USLx2, CUT[1], sig22)
    pIIC = norm.cdf(USLx2, CUT[1], sig22) - norm.cdf(LSLx2, CUT[1], sig22)
    pIIS = norm.cdf(LSLx2, CUT[1], sig22)
    iip22 = pII2
    iip2S = pIIS

    mIi2 = pI2 / (1 - ip22)
    mIIii2 = -pII2 / (-1 + iip22)

    fIC = -(((pIC * pI2 - ip22 * pIC + pIC) * pIIC) / (-1 + ip22)) + (
        pII2 * pIIC * (ip2C * pI2 - ip22 * pIC + pIC)
    ) / ((-1 + ip22) * (-1 + iip22))
    fIIS = pIIS - ((pII2 * iip2S) / (-1 + iip22))

    EPR_modified = (
        SP * fIC
        - (PC1 + PC2 * (pIC + (pI2 * ip2C / (1 - ip22))))
        - (SC1 * (pIS + (pI2 * ip2S / (1 - ip22))) + SC2 * (pIC + (pI2 * ip2C / (1 - ip22))) * fIIS)
        - (RC1 * (mIi2) + RC2 * (mIIii2) * (pIC + (pI2 * ip2C / (1 - ip22))))
    )

    # Generalised multistage approach: the alternative one-Stage model, twice
    pI1_2 = 1 - norm.cdf(USLx1, CUT[0], sig11)
    pI1_C = norm.cdf(USLx1, CUT[0], sig11) - norm.cdf(LSLx1, CUT[0], sig11)
    pI1_S = norm.cdf(LSLx1, CUT[0], sig11)
    p1_22 = pI1_2
    p1_2C = pI1_C
    p1_2S = pI1_S

    mI1_2 = pI1_2 / (1 - p1_22)
    fI1_C = pI1_C + (pI1_2 * p1_2C / (1 - p1_22))

    SR_1 = SC1 * pI1_S + SC1 * pI1_2 * (p1_2S / (1 - p1_22))
    RW_1 = RC1 * mI1_2

    pI2_2 = 1 - norm.cdf(USLx2, CUT[1], sig22)
    pI2_C = norm.cdf(USLx2, CUT[1], sig22) - norm.cdf(LSLx2, CUT[1], sig22)
    pI2_S = norm.cdf(LSLx2, CUT[1], sig22)
    p2_22 = pI2_2
    p2_2C = pI2_C
    p2_2S = pI2_S

    mI2_2 = pI2_2 / (1 - p2_22)
    fI2_C = pI2_C + (pI2_2 * p2_2C / (1 - p2_22))

    SR_2 = SC2 * pI2_S + SC2 * pI2_2 * (p2_2S / (1 - p2_22))
    RW_2 = RC2 * mI2_2

    PC_Tot = PC1 * 1 + PC2 * fI1_C
    SR_Tot = SR_1 * 1 + SR_2 * fI1_C
    RW_Tot = RW_1 * 1 + RW_2 * fI1_C
    SP_Tot = SP * fI1_C * fI2_C

    EPR_generalised = SP_Tot - PC_Tot - SR_Tot - RW_Tot

    values = dict(
        p11=p11, p12=p12, p14=p14, p22=p22, p23=p23, p24=p24, m11=m11, m22=m22, f13=f13, f24=f24,
        EPR_conventional=EPR_conventional,
        mIi2=mIi2, mIIii2=mIIii2, fIC=fIC, fIIS=fIIS, EPR_modified=EPR_modified,
        mI1_2=mI1_2, fI1_C=fI1_C, SR_1=SR_1, RW_1=RW_1, mI2_2=mI2_2, fI2_C=fI2_C, SR_2=SR_2, RW_2=RW_2,
        PC_Tot=PC_Tot, SR_Tot=SR_Tot, RW_Tot=RW_Tot, SP_Tot=SP_Tot, EPR_generalised=EPR_generalised,
    )
    return MarkovProcess2VarOutput(**{k: float(v) for k, v in values.items()})
