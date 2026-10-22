"""Faithful port of `legacy_matlab/validation/Markov_TriChars.m` (test oracle only, ADR 0002).

The MATLAB is a script for three independent Features. Its hard-coded inputs become keyword
defaults, and the values it computes are returned. The Rework Side is above B (the upper limits)
and A are the lower limits. The script stops at `S2`, which uses the undefined `p210`, so S2–S8
(and everything after them) are never computed and are not ported; the commented-out two-Feature
code is not ported either. The pair Rework States pass `[sig11 0; 0 sig22]` to `mvncdf`, so σ is
used as a variance there (D16).
"""

from __future__ import annotations

from dataclasses import dataclass
from math import inf

from scipy.stats import norm

from oracles.mvncdf import mvncdf


@dataclass(frozen=True)
class MarkovTriCharsOutput:
    ConformPrt: float
    conformpartchk: float
    RW1: float
    RW2: float
    RW3: float
    RW12: float
    RW13: float
    RW23: float
    RW123: float
    TotRW: float
    Scrap: float
    ShouldEqOne: float
    p2S: float
    p22: float
    p3S: float
    p33: float
    p4S: float
    p44: float
    p5S: float
    p55: float
    p6S: float
    p66: float
    p7S: float
    p77: float
    p8S: float


def markov_tri_chars(
    *,
    cut=(5, 5, 5),
    A=(3, 3, 3),
    B=(7, 7, 7),
    sig11: float = 2,
    sig22: float = 2,
    sig33: float = 2,
) -> MarkovTriCharsOutput:
    SIGMA = [[sig11**2, 0, 0], [0, sig22**2, 0], [0, 0, sig33**2]]
    upper = [inf, inf, inf]
    Fa1a2a3U = mvncdf([A[0], A[1], A[2]], upper, cut, SIGMA)
    Fa1a2b3U = mvncdf([A[0], A[1], B[2]], upper, cut, SIGMA)  # top plane
    Fb1a2a3U = mvncdf([B[0], A[1], A[2]], upper, cut, SIGMA)  # right plane
    Fa1b2a3U = mvncdf([A[0], B[1], A[2]], upper, cut, SIGMA)  # back plane
    Fa1b2b3U = mvncdf([A[0], B[1], B[2]], upper, cut, SIGMA)  # top back
    Fb1a2b3U = mvncdf([B[0], A[1], B[2]], upper, cut, SIGMA)  # top right
    Fb1b2a3U = mvncdf([B[0], B[1], A[2]], upper, cut, SIGMA)  # vertical right corner
    Fb1b2b3U = mvncdf([B[0], B[1], B[2]], upper, cut, SIGMA)

    # Conform
    ConformPrt = -Fb1b2b3U + Fb1b2a3U + Fb1a2b3U + Fa1b2b3U - Fa1b2a3U - Fb1a2a3U - Fa1a2b3U + Fa1a2a3U
    conformpartchk = mvncdf([A[0], A[1], A[2]], [B[0], B[1], B[2]], cut, SIGMA)

    # Rework
    RW1 = Fb1a2a3U - Fb1a2b3U - Fb1b2a3U + Fb1b2b3U
    RW2 = Fa1b2a3U - Fa1b2b3U - Fb1b2a3U + Fb1b2b3U
    RW3 = Fa1a2b3U - Fa1b2b3U - Fb1a2b3U + Fb1b2b3U
    RW12 = Fb1b2a3U - Fb1b2b3U
    RW13 = Fb1a2b3U - Fb1b2b3U
    RW23 = Fa1b2b3U - Fb1b2b3U
    RW123 = Fb1b2b3U

    TotRW = RW1 + RW2 + RW3 + RW12 + RW13 + RW23 + RW123

    # Scrap
    Scrap = 1 - Fa1a2a3U

    ShouldEqOne = Scrap + TotRW + ConformPrt

    p2S = norm.cdf(A[0], cut[0], sig11)
    p22 = 1 - norm.cdf(B[0], cut[0], sig11)
    p3S = norm.cdf(A[1], cut[1], sig22)
    p33 = 1 - norm.cdf(B[1], cut[1], sig22)
    p4S = norm.cdf(A[2], cut[2], sig33)
    p44 = 1 - norm.cdf(B[2], cut[2], sig33)
    p5S, p55 = _pair(A[0], A[1], B[0], B[1], cut[0], cut[1], sig11, sig22)
    p6S, p66 = _pair(A[0], A[2], B[0], B[2], cut[0], cut[2], sig11, sig33)
    p7S, p77 = _pair(A[1], A[2], B[1], B[2], cut[1], cut[2], sig22, sig33)
    p8S = 1 - Fa1a2a3U

    values = dict(
        ConformPrt=ConformPrt, conformpartchk=conformpartchk,
        RW1=RW1, RW2=RW2, RW3=RW3, RW12=RW12, RW13=RW13, RW23=RW23, RW123=RW123,
        TotRW=TotRW, Scrap=Scrap, ShouldEqOne=ShouldEqOne,
        p2S=p2S, p22=p22, p3S=p3S, p33=p33, p4S=p4S, p44=p44,
        p5S=p5S, p55=p55, p6S=p6S, p66=p66, p7S=p7S, p77=p77, p8S=p8S,
    )
    return MarkovTriCharsOutput(**{k: float(v) for k, v in values.items()})


def _pair(Ai, Aj, Bi, Bj, cut_i, cut_j, sig_i, sig_j):
    """p5S and p55 (likewise 6 and 7): scrap and rework-both for a pair Rework State, SIGMA = [sig_i 0; 0 sig_j]."""
    SIGMA = [[sig_i, 0], [0, sig_j]]  # sic: standard deviations where mvncdf expects variances (D16)
    mu = [cut_i, cut_j]
    pS = (
        mvncdf([-inf, -inf], [Ai, inf], mu, SIGMA)
        + mvncdf([-inf, -inf], [inf, Aj], mu, SIGMA)
        - mvncdf([-inf, -inf], [Ai, Aj], mu, SIGMA)
    )
    pR = mvncdf([Bi, Bj], [inf, inf], mu, SIGMA)
    return pS, pR
