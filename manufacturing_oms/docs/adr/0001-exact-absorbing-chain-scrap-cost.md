# Expected scrap cost uses the exact absorbing-chain expectation, not thesis Eq 3.59

Expected scrap cost per Stage is computed as Σ_j m_{I,j} · p_{j,S} · SC_j, where m_{I,j} are the expected visit counts from the fundamental matrix M = (I − Q)^-1. This is the same matrix that already gives Final Conformance Probability and Rework Cost. The thesis (Eq 3.59) and the MATLAB (`StageCostFun`, S∘D "feed-in" matrices) use a path-enumeration formula instead. That formula is exact for N ≤ 2 Features in a Stage. For N ≥ 3 it underestimates, for two reasons: it counts only one-hop feed-ins into each Rework State, and it takes the transition probability out of a larger Rework State w from the Initial State's row rather than from state w's own row.

An independent check (independent normal Features, unit scrap cost) gave these differences:

| Case | Exact | Eq 3.59 | Diff |
|---|---|---|---|
| N=2, Table 3.1 means | 0.0107240 | 0.0107240 | 0 |
| N=3, μ=[6,5.5,5], σ=[2,2.5,3], L=3, U=7 | 0.53254 | 0.52813 | −4.4e-3 |
| N=4, Table 3.8 means | 0.0185160 | 0.0185111 | −4.9e-6 |

Eq 3.59 is kept as a test oracle (see ADR 0002). It must match exactly for N ≤ 2, and its gap for N ≥ 3 is logged as a documented discrepancy. Thesis results with N ≥ 3 in one Stage (e.g. Table 3.9, Seq 8) are therefore expected to differ slightly.
