# Throwaway check of R9 (Tables 4.1/4.3, connecting rod; D6). Units cm. Rework below L, scrap above U.
# x1 Normal, x2 tLocation-Scale, joined by a Gaussian copula. per_group_size means: [dual x1, dual x2, single x1, single x2].
import numpy as np
from scipy.stats import norm, t as tdist, multivariate_normal as mvn
from scipy.optimize import minimize

SP, PC, SC, RC1, RC2, RC12 = 100., 20., 50., 5., 5., 10.


def make(L, U, s1, s2, rho, nu):
    F1 = lambda x, m: norm.cdf(x, m, s1)
    F2 = (lambda x, m: tdist.cdf(x, nu, m, s2)) if nu else (lambda x, m: norm.cdf(x, m, s2))

    def C(u, v):
        u, v = np.clip([u, v], 1e-15, 1 - 1e-15)
        return mvn.cdf([norm.ppf(u), norm.ppf(v)], mean=[0, 0], cov=[[1, rho], [rho, 1]])

    def ev(mu):
        d1, d2, s1m, s2m = mu
        J = lambda a, b: C(F1(a, d1), F2(b, d2))
        Fbb, Fab, Fba, Faa = J(U[0], U[1]), J(L[0], U[1]), J(U[0], L[1]), J(L[0], L[1])
        p1, p2, p12, pC = Fab - Faa, Fba - Faa, Faa, Fbb - Fab - Fba + Faa
        pX = 1 - Fbb
        r1, c1, x1 = F1(L[0], s1m), F1(U[0], s1m) - F1(L[0], s1m), 1 - F1(U[0], s1m)
        r2, c2, x2 = F2(L[1], s2m), F2(U[1], s2m) - F2(L[1], s2m), 1 - F2(U[1], s2m)
        Q = np.zeros((4, 4)); Q[0, 1:] = Q[3, 1:] = [p1, p2, p12]; Q[1, 1] = r1; Q[2, 2] = r2
        m = np.linalg.inv(np.eye(4) - Q)[0]
        fC = m @ [pC, c1, c2, pC]; Sr = SC * (m @ [pX, x1, x2, pX]); Rw = m[1]*RC1 + m[2]*RC2 + m[3]*RC12
        return SP*fC - PC - Sr - Rw
    return ev


printed = [6.8737, 3.9514, 6.8441, 3.9486]   # Table 4.3, profit 44.47
cases = {
    "R9: Table 4.1 limits in cm, t marginal (thesis run)": ([6.9, 3.925], [7.1, 4.075], 0.1362, 0.0527, 0.7052, 2.2522),
    "committed ConRod_OptimalMeanSet_2D.m limits (D6)":    ([6.8, 3.8], [7.2, 4.2], 0.1362, 0.0527, 0.7052, 2.2522),
}
for label, args in cases.items():
    ev = make(*args)
    r = minimize(lambda v: -ev(v), printed, method="Nelder-Mead", options={"xatol": 1e-6, "fatol": 1e-9, "maxiter": 4000})
    print(f"{label:52s} profit@printed={ev(printed):.4f}  optimum={-r.fun:.4f} @ {r.x.round(4)}")
