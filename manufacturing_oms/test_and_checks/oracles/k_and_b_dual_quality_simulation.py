"""Faithful ports of `legacy_matlab/validation/K_and_B_DualQualitySimulation.m`, `KandBSimulate.m` and
`KandBSimulate_1Var.m`.

Test oracles only (ADR 0002). A Monte Carlo of Khasawneh & Bowling's two-Feature chain, with the Rework Side
hard-coded above B. `KandBSimulate` draws parts from the two-Feature normal and sorts them into finish, scrap
(either Feature below A), rework both (both above B), rework x and rework y. Rework-both parts are redrawn
with `KandBSimulate`; rework-x and rework-y parts with `KandBSimulate_1Var` on that Feature's marginal. The
script loops until no rework is left.

MATLAB's `mvnrnd`/`normrnd` stream can't be reproduced, so the port draws from a NumPy `Generator` seeded by
`seed`. The script's hard-coded inputs become keyword defaults. Its `SIGMA` line hard-codes a zero
correlation; the port takes `SIGMA` whole, as `KandBSimulate` does. The simulation's structs `s1`, `f1` and `S1` are
ported, with the script's analytic column `S3` from `KandBMarkov_DualChars`; the other displays (`SingleVar`,
`S4`, `m42`, `m43`, `M41`) only repeat `KandBMarkov_DualChars` quantities. `FinsihANDScrap` is first set
inside the script's loop, so MATLAB fails at `f1` if the first draw has no rework; the port starts it at
Finish + Scrap.
"""

from __future__ import annotations

import math
from dataclasses import dataclass

import numpy as np

from oracles.kandb_markov_dual_chars import KandBMarkovDualCharsOutput, kandb_markov_dual_chars


def kandb_simulate(CUT, SIGMA, A, B, Rework, rng):
    """[Finish,Scrap,ReworkXY,ReworkX,ReworkY] = KandBSimulate(CUT,SIGMA,A,B,Rework)."""
    LSLx, LSLy = A
    USLx, USLy = B
    PS = rng.multivariate_normal(CUT, SIGMA, size=int(Rework))
    x, y = PS[:, 0], PS[:, 1]
    finish = (x >= LSLx) & (x <= USLx) & (y >= LSLy) & (y <= USLy)
    scrap = ~finish & ((x < LSLx) | (y < LSLy))
    rest = ~finish & ~scrap
    rework_xy = rest & (x > USLx) & (y > USLy)
    rework_x = rest & ~rework_xy & (x > USLx)
    rework_y = rest & ~rework_xy & ~rework_x & (y > USLy)
    return tuple(int(c.sum()) for c in (finish, scrap, rework_xy, rework_x, rework_y))


def kandb_simulate_1var(cut, sig, L, U, RW, rng):
    """[Finish,Scrap,Rework] = KandBSimulate_1Var(cut,sig,L,U,RW)."""
    PS = rng.normal(cut, sig, size=int(RW))
    finish = (PS >= L) & (PS <= U)
    scrap = ~finish & (PS < L)
    rework = ~finish & ~scrap & (PS > U)
    return tuple(int(c.sum()) for c in (finish, scrap, rework))


@dataclass(frozen=True)
class FirstPass:
    """`s1`: the first draw of all n parts, as fractions of n."""

    Finish: float
    Scrap: float
    ReworkXY: float
    ReworkX: float
    ReworkY: float


@dataclass(frozen=True)
class Totals:
    """`f1`: counts over the whole simulation."""

    FinsihScrap: int
    Finish: int
    Scrap: int
    Total_Rework_xy: int
    Total_Rework_x: int
    Total_Rework_y: int


@dataclass(frozen=True)
class Simulated:
    """`S1`, as fractions of n. f15/f16 are all finished/scrapped parts; f25/f26, f35/f36 and f45/f46 those
    finished/scrapped by a rework-x, rework-y and rework-both draw; m12, m13, m14 the draws into each."""

    f15: float
    f25: float
    f35: float
    f45: float
    f16: float
    f26: float
    f36: float
    f46: float
    m12: float
    m13: float
    m14: float


@dataclass(frozen=True)
class Analytic:
    """`S3`: `KandBMarkov_DualChars` scaled to `S1`'s per-part fractions. P1s = [p12, p13, p14, p15, p16]."""

    f15: float
    f25_p12: float
    f35_p13: float
    f35_AA: float
    f45_p14: float
    f45_AA: float
    f16: float
    f26_p12: float
    f36_p13: float
    f46_p14: float
    m12: float
    m13: float
    m14: float


def analytic_column(out: KandBMarkovDualCharsOutput) -> Analytic:
    P1s = [out.p12, out.p13, out.p14, out.p15, out.p16]
    return Analytic(
        f15=out.f15,
        f25_p12=out.f25 * (P1s[0] + (P1s[2] * (P1s[0] / (1 - P1s[2])))),
        f35_p13=out.f35 * (P1s[1] + (P1s[2] * (P1s[1] / (1 - P1s[2])))),
        f35_AA=out.f35 * (P1s[1] / (1 - P1s[2])),
        f45_p14=P1s[2] * (P1s[3] / (1 - P1s[2])),
        f45_AA=out.f45 * (P1s[2]),
        f16=out.f16,
        f26_p12=out.f26 * (P1s[2] * (P1s[0] / (1 - P1s[2])) + P1s[0]),
        f36_p13=out.f36 * (P1s[2] * (P1s[1] / (1 - P1s[2])) + P1s[1]),
        f46_p14=P1s[2] * (P1s[4] / (1 - P1s[2])),
        m12=out.m12,
        m13=out.m13,
        m14=out.m14,
    )


@dataclass(frozen=True)
class KAndBDualQualitySimulationOutput:
    s1: FirstPass
    f1: Totals
    S1: Simulated
    S3: Analytic
    count: int


def k_and_b_dual_quality_simulation(
    *,
    CUT=(5.0, 5.0),
    SIGMA=((1.55**2, 0.0), (0.0, 1.55**2)),
    A=(3.0, 3.0),
    B=(7.0, 7.0),
    n=1_000_000,
    seed=None,
) -> KAndBDualQualitySimulationOutput:
    rng = np.random.default_rng(seed)
    sig11 = math.sqrt(SIGMA[0][0])
    sig22 = math.sqrt(SIGMA[1][1])

    Finish, Scrap, ReworkXY, ReworkX, ReworkY = kandb_simulate(CUT, SIGMA, A, B, n, rng)
    s1 = FirstPass(Finish / n, Scrap / n, ReworkXY / n, ReworkX / n, ReworkY / n)

    RWXY, RWX, RWY = ReworkXY, ReworkX, ReworkY
    Fin2count = Fin3count = Fin4count = 0
    RWXYcount = RWXcount = RWYcount = 0
    Scrap2count = Scrap3count = Scrap4count = 0
    FinsihANDScrap = Finish + Scrap
    count = 0
    while RWXY > 0 or RWX > 0 or RWY > 0:  # If there is rework do the following
        Fin2, Scr2, RWX2 = kandb_simulate_1var(CUT[0], sig11, A[0], B[0], RWX, rng)
        Fin3, Scr3, RWY3 = kandb_simulate_1var(CUT[1], sig22, A[1], B[1], RWY, rng)
        Fin4, Scr4, RWXY4, RWX4, RWY4 = kandb_simulate(CUT, SIGMA, A, B, RWXY, rng)

        Finish = Finish + Fin2 + Fin3 + Fin4
        Scrap = Scrap + Scr2 + Scr3 + Scr4
        Fin2count += Fin2
        Fin3count += Fin3
        Fin4count += Fin4
        RWXcount += RWX
        RWYcount += RWY
        RWXYcount += RWXY
        Scrap2count += Scr2
        Scrap3count += Scr3
        Scrap4count += Scr4
        RWXY, RWX, RWY = RWXY4, RWX2 + RWX4, RWY3 + RWY4
        FinsihANDScrap = Finish + Scrap
        count += 1

    f1 = Totals(FinsihANDScrap, Finish, Scrap, RWXYcount, RWXcount, RWYcount)
    S1 = Simulated(
        f15=Finish / n, f25=Fin2count / n, f35=Fin3count / n, f45=Fin4count / n,
        f16=Scrap / n, f26=Scrap2count / n, f36=Scrap3count / n, f46=Scrap4count / n,
        m12=RWXcount / n, m13=RWYcount / n, m14=RWXYcount / n,
    )  # fmt: skip

    LSLx, LSLy = A
    USLx, USLy = B
    S3 = analytic_column(kandb_markov_dual_chars(list(CUT), SIGMA, LSLx, LSLy, USLx, USLy))
    return KAndBDualQualitySimulationOutput(s1, f1, S1, S3, count)
