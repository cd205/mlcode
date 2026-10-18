# Throwaway check of R4 (Table 3.7): 2 independent features in one Stage, per_feature means, Rework Side above U.
import numpy as np
from scipy.stats import norm
from scipy.optimize import minimize
L, U, sd, SP, PC, SC = np.array([8., 13.]), np.array([12., 17.]), 1.0, 120., 45., 27.
RC1, RC2, RC12 = 15., 12., 27.
def ev(mu):
    x = [norm.cdf(L[i], mu[i], sd) for i in range(2)]; r = [norm.sf(U[i], mu[i], sd) for i in range(2)]
    c = [1 - x[i] - r[i] for i in range(2)]
    pX = 1 - (1 - x[0]) * (1 - x[1]); pC = c[0] * c[1]; p1 = r[0] * c[1]; p2 = c[0] * r[1]; p12 = r[0] * r[1]
    Q = np.zeros((4, 4)); Q[0, 1:] = Q[3, 1:] = [p1, p2, p12]; Q[1, 1] = r[0]; Q[2, 2] = r[1]
    pc = np.array([pC, c[0], c[1], pC]); px = np.array([pX, x[0], x[1], pX])
    m = np.linalg.inv(np.eye(4) - Q)[0]
    fC = m @ pc; Sr = SC * (m @ px); Rw = m[1] * RC1 + m[2] * RC2 + m[3] * RC12
    return SP * fC - PC - Sr - Rw, PC + Sr + Rw
a = minimize(lambda v: -ev(v)[0], [10.5, 15.5], method="Nelder-Mead", options={"xatol": 1e-7, "fatol": 1e-10})
b = minimize(lambda v: ev(v)[1], [10.1, 15.1], method="Nelder-Mead", options={"xatol": 1e-7, "fatol": 1e-10})
print(f"max profit: {ev(a.x)[0]:.4f} @ {a.x.round(3)}   min PC+Sr+Rw: {ev(b.x)[1]:.4f} @ {b.x.round(3)}")
