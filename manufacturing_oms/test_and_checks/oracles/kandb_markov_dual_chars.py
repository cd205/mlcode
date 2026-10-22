"""Faithful ports of `legacy_matlab/validation/KandBMarkov_DualChars.m` and `K_and_B_2008_Example.m`.

Test oracles only (ADR 0002). Khasawneh & Bowling 2008's two-Feature chain: states 1 (initial),
2 (rework x), 3 (rework y), 4 (rework both), 5 (conform), 6 (scrap). The Rework Side is hard-coded
above U. The script's literature profit (Table 3.1, cost-formula "Case I", D7) charges each state's
Scrap Cost as SC_j·(1 − f_j5) instead of Eq 3.44's expected scrap from that state.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from math import inf

from scipy.stats import norm

from oracles.mvncdf import mvncdf


@dataclass(frozen=True)
class KandBMarkovDualCharsOutput:
    p12: float
    p13: float
    p14: float
    p15: float
    p16: float
    p22: float
    p25: float
    p26: float
    p33: float
    p35: float
    p36: float
    m12: float
    m13: float
    m14: float
    f15: float
    f25: float
    f35: float
    f45: float
    f16: float
    f26: float
    f36: float
    f46: float


def kandb_markov_dual_chars(MU, SIGMA, Lx, Ly, Ux, Uy) -> KandBMarkovDualCharsOutput:
    sig11 = math.sqrt(SIGMA[0][0])
    sig22 = math.sqrt(SIGMA[1][1])

    p12 = mvncdf([Ux, Ly], [inf, Uy], MU, SIGMA)
    p13 = mvncdf([Lx, Uy], [Ux, inf], MU, SIGMA)
    p14 = mvncdf([Ux, Uy], [inf, inf], MU, SIGMA)
    p15 = mvncdf([Lx, Ly], [Ux, Uy], MU, SIGMA)
    p16 = (
        mvncdf([-inf, -inf], [Lx, inf], MU, SIGMA)
        + mvncdf([-inf, -inf], [inf, Ly], MU, SIGMA)
        - mvncdf([-inf, -inf], [Lx, Ly], MU, SIGMA)
    )

    p22 = 1 - norm.cdf(Ux, MU[0], sig11)
    p25 = norm.cdf(Ux, MU[0], sig11) - norm.cdf(Lx, MU[0], sig11)
    p26 = norm.cdf(Lx, MU[0], sig11)
    p33 = 1 - norm.cdf(Uy, MU[1], sig22)
    p35 = norm.cdf(Uy, MU[1], sig22) - norm.cdf(Ly, MU[1], sig22)
    p36 = norm.cdf(Ly, MU[1], sig22)
    p42 = p12
    p43 = p13
    p44 = p14
    p45 = p15
    p46 = p16

    m12 = p12 / ((1 - p22) * (1 - p44))
    m13 = p13 / ((1 - p33) * (1 - p44))
    m14 = p14 / (1 - p44)

    # Acceptance parts
    f15 = p15 + p12 * p25 / ((1 - p22) * (1 - p44)) + p13 * p35 / ((1 - p33) * (1 - p44)) + p14 * p45 / (1 - p44)
    f25 = p25 / (1 - p22)
    f35 = p35 / (1 - p33)
    f45 = p42 * p25 / ((1 - p22) * (1 - p44)) + p43 * p35 / ((1 - p33) * (1 - p44)) + p45 / (1 - p44)

    # Scrap parts
    f16 = p16 + p12 * p26 / ((1 - p22) * (1 - p44)) + p13 * p36 / ((1 - p33) * (1 - p44)) + p14 * p46 / (1 - p44)
    f26 = p26 / (1 - p22)
    f36 = p36 / (1 - p33)
    f46 = p42 * p26 / ((1 - p22) * (1 - p44)) + p43 * p36 / ((1 - p33) * (1 - p44)) + p46 / (1 - p44)

    values = dict(
        p12=p12, p13=p13, p14=p14, p15=p15, p16=p16, p22=p22, p25=p25, p26=p26, p33=p33, p35=p35, p36=p36,
        m12=m12, m13=m13, m14=m14, f15=f15, f25=f25, f35=f35, f45=f45, f16=f16, f26=f26, f36=f36, f46=f46,
    )
    return KandBMarkovDualCharsOutput(**{k: float(v) for k, v in values.items()})


@dataclass(frozen=True)
class KAndB2008ExampleOutput:
    Scrap: tuple[float, ...]
    Rwork: tuple[float, ...]
    EP: float


def k_and_b_2008_example(*, MU=(10.55137, 15.60796)) -> KAndB2008ExampleOutput:
    """The script's live (uncommented) part. Its hard-coded means become the `MU` default."""
    SP = 120
    PC = 45
    RC = [0, 15, 12, 20]
    SC = [8, 9, 11, 14]
    sig11 = 1
    sig22 = 1
    SIGMA = [[sig11**2, 0], [0, sig22**2]]
    Lx = 8
    Ly = 13
    Ux = 12
    Uy = 17
    out = kandb_markov_dual_chars(list(MU), SIGMA, Lx, Ly, Ux, Uy)
    fs = [out.f15, out.f25, out.f35, out.f45]
    ms = [out.m12, out.m13, out.m14]
    Scrap = [SC[j] * (1 - fs[j]) for j in range(4)]
    Rwork = [RC[k + 1] * ms[k] for k in range(3)]

    EP = SP * out.f15 - PC - sum(Scrap) - sum(Rwork)
    return KAndB2008ExampleOutput(tuple(Scrap), tuple(Rwork), float(EP))
