# Throwaway check of R6/R7 (Tables 3.11, 3.13): SP=400, sigma=2 (D11), rework side above U. Case I = per_feature, Case II = per_group_size.
import numpy as np
from scipy.stats import norm, multivariate_normal as mvn
from scipy.optimize import minimize
L, U, sd, SP, PC, SC, RCs, RCd = 4.0, 6.0, 2.0, 400.0, 50.0, 150.0, 25.0, 50.0
def F(a, b, mu, cov): return mvn(mu, cov).cdf([a, b]) if np.isfinite(a) and np.isfinite(b) else None
def box(lo, hi, mu, cov):
    big = 60.0
    lo = [max(l, -big) for l in lo]; hi = [min(h, big) for h in hi]
    c = lambda x, y: mvn.cdf([x, y], mean=mu, cov=cov, abseps=1e-12, releps=1e-12)
    return c(hi[0], hi[1]) - c(lo[0], hi[1]) - c(hi[0], lo[1]) + c(lo[0], lo[1])
def evaluate(md, ms, rho):
    cov = np.array([[sd*sd, rho*sd*sd], [rho*sd*sd, sd*sd]]); mu = [md, md]
    C = (L, U); R = (U, np.inf)
    pC = box([L, L], [U, U], mu, cov); p12 = box([U, U], [np.inf]*2, mu, cov)
    p1 = box([U, L], [np.inf, U], mu, cov); p2 = box([L, U], [U, np.inf], mu, cov)
    pX = 1 - pC - p12 - p1 - p2
    s_rw = norm.sf(U, ms, sd); s_c = norm.cdf(U, ms, sd) - norm.cdf(L, ms, sd); s_x = norm.cdf(L, ms, sd)
    # states 0=I,1={1},2={2},3={1,2}
    Q = np.zeros((4, 4)); Q[0, 1:] = [p1, p2, p12]; Q[3, 1:] = [p1, p2, p12]; Q[1, 1] = Q[2, 2] = s_rw
    pc = np.array([pC, s_c, s_c, pC]); px = np.array([pX, s_x, s_x, pX])
    m = np.linalg.inv(np.eye(4) - Q)[0]
    fC = m @ pc; Sr = SC * (m @ px); Rw = m[1]*RCs + m[2]*RCs + m[3]*RCd
    return SP*fC - PC - Sr - Rw, Sr + Rw, fC
for rho in (0.0, 0.8, -0.8):
    a = minimize(lambda x: -evaluate(x[0], x[0], rho)[0], [6.8], method="Nelder-Mead", options={"xatol":1e-6,"fatol":1e-10})
    b = minimize(lambda x: -evaluate(x[0], x[1], rho)[0], [6.7, 7.0], method="Nelder-Mead", options={"xatol":1e-6,"fatol":1e-10})
    ra = evaluate(a.x[0], a.x[0], rho); rb = evaluate(*b.x, rho)
    print(f"rho={rho:+.1f}  CaseI mu={a.x[0]:.3f} profit={ra[0]:.4f} cost={ra[1]:.2f} fC={ra[2]:.4f} | CaseII mu={b.x.round(3)} profit={rb[0]:.4f} cost={rb[1]:.2f} fC={rb[2]:.4f}")
