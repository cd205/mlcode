# Throwaway check of R2 (Table 3.3 / Fig 3.24): 1 feature, Rework Side above U. Tests which "production cost" gives mu = 10.09 (U2).
from scipy.stats import norm
from scipy.optimize import minimize_scalar
L, U, sd, SP, PC, RC, SC = 8.0, 12.0, 1.0, 120.0, 25.0, 10.0, 15.0
def ev(mu):
    pR = norm.sf(U, mu, sd); pC = norm.cdf(U, mu, sd) - norm.cdf(L, mu, sd); pX = norm.cdf(L, mu, sd)
    m_I, m_2 = 1.0, pR / (1 - pR)       # visits: initial once, rework state pR/(1-pR)
    fC = pC / (1 - pR); Sr = SC * pX / (1 - pR); Rw = RC * m_2
    return SP * fC - PC - Sr - Rw, Sr, Rw, fC
cands = {
  "max E(PR)":                 lambda m: -ev(m)[0],
  "min Sr+Rw (=PC+Sr+Rw)":     lambda m: ev(m)[1] + ev(m)[2],
  "min (PC+Sr+Rw)/fC":         lambda m: (PC + ev(m)[1] + ev(m)[2]) / ev(m)[3],
  "min Sr only":               lambda m: ev(m)[1],
}
for k, f in cands.items():
    r = minimize_scalar(f, bounds=(8, 13), method="bounded", options={"xatol": 1e-8})
    print(f"{k:24s} mu*={r.x:.4f}  E(PR)={ev(r.x)[0]:.4f}  Sr+Rw={ev(r.x)[1]+ev(r.x)[2]:.4f}")
