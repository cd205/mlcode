"""The engine against a port of `K_and_B_DualQualitySimulation`, Khasawneh & Bowling's Monte Carlo (issue #13).

The script draws parts with `mvnrnd` (`KandBSimulate`) and sends the rework back through the two-Feature draw
(rework both) or a one-Feature draw (`KandBSimulate_1Var`, rework x or rework y) until none is left. It knows
nothing of the engine's absorbing-chain algebra, so agreement is an independent check of f_C, the scrap
probability and the expected visits m_{I,j}.

The port can't reproduce MATLAB's random stream, so the tolerance is statistical. The script's totals are
divided by n, so they are means of i.i.d. per-part counts. The port is run in `BATCHES` independent batches
from one fixed seed, and each check allows 4 standard errors of the batch means.
"""

import numpy as np
import pytest

from oms import CostTable, Feature, MeanSettings, MultivariateNormal, ReworkSide, Stage, evaluate_stage
from oracles import k_and_b_dual_quality_simulation, kandb_markov_dual_chars
from oracles.k_and_b_dual_quality_simulation import analytic_column

I = frozenset()
X1 = frozenset({"x1"})
X2 = frozenset({"x2"})
X12 = frozenset({"x1", "x2"})
SEED = 20261022
BATCHES = 20
N_PER_BATCH = 50_000


def evaluate_engine(CUT, SIGMA, A, B):
    """The engine on the script's inputs: Features x1, x2 with the Rework Side above B, unit costs."""
    names = ("x1", "x2")
    sd = np.sqrt(np.diag(SIGMA))
    rho = SIGMA[0][1] / (sd[0] * sd[1])
    stage = Stage(
        features=tuple(Feature(n, lower=a, upper=b, rework_side=ReworkSide.UPPER) for n, a, b in zip(names, A, B)),
        variation=MultivariateNormal(list(sd), rho),
        costs=CostTable(processing=0.0, rework={X1: 1.0, X2: 1.0, X12: 1.0}, scrap={I: 1.0, X1: 1.0, X2: 1.0, X12: 1.0}),
    )
    return evaluate_stage(stage, MeanSettings.per_feature(stage, dict(zip(names, CUT))))


def batches(**inputs):
    """The port's S1 struct from each batch, keyed by field, as arrays over the batches."""
    seeds = np.random.SeedSequence(SEED).spawn(BATCHES)
    runs = [k_and_b_dual_quality_simulation(**inputs, n=N_PER_BATCH, seed=s).S1 for s in seeds]
    return {field: np.array([getattr(r, field) for r in runs]) for field in type(runs[0]).__dataclass_fields__}


def assert_agrees(samples, exact):
    se = samples.std(ddof=1) / np.sqrt(len(samples))
    se = max(se, np.sqrt(max(exact, 1e-12) / (len(samples) * N_PER_BATCH)))  # a rare count may never occur
    assert abs(samples.mean() - exact) <= 4 * se, f"{samples.mean()} vs {exact} (se {se:.3g})"


SCRIPT = dict(CUT=(5.0, 5.0), SIGMA=((1.55**2, 0.0), (0.0, 1.55**2)), A=(3.0, 3.0), B=(7.0, 7.0))
CASES = [
    pytest.param(SCRIPT, id="script inputs"),
    pytest.param(
        dict(CUT=(10.5514, 15.6080), SIGMA=((1.0, 0.0), (0.0, 1.0)), A=(8.0, 13.0), B=(12.0, 17.0)), id="R3 means"
    ),
    pytest.param(
        dict(CUT=(11.6, 16.4), SIGMA=((1.0, 0.0), (0.0, 1.5**2)), A=(8.0, 13.0), B=(12.0, 17.0)), id="heavy rework"
    ),
    pytest.param(
        dict(CUT=(11.2, 16.1), SIGMA=((1.0, 0.75), (0.75, 1.5**2)), A=(8.0, 13.0), B=(12.0, 17.0)), id="rho=0.5"
    ),
]


@pytest.fixture(scope="module", params=CASES)
def case_inputs(request):
    return request.param


@pytest.fixture(scope="module")
def case(case_inputs):
    return evaluate_engine(**case_inputs), batches(**case_inputs)



@pytest.fixture(scope="module")
def S3(case_inputs):
    """The script's `S3` column on the case's inputs."""
    A, B = case_inputs["A"], case_inputs["B"]
    return analytic_column(kandb_markov_dual_chars(list(case_inputs["CUT"]), case_inputs["SIGMA"], *A, *B))


def test_final_conformance_and_scrap_agree_with_the_engine(case):
    result, sims = case
    assert_agrees(sims["f15"], result.final_conformance)
    assert_agrees(sims["f16"], result.scrap_probability)


def test_expected_visits_agree_with_the_engine(case):
    """m12, m13, m14 count the draws into rework x, rework y and rework both: m_{I,j}."""
    result, sims = case
    for field, state in (("m12", X1), ("m13", X2), ("m14", X12)):
        assert_agrees(sims[field], result.visits[state])


def test_conformance_and_scrap_by_rework_state_agree_with_the_engine(case):
    """f25, f35, f45 (f26, f36, f46) are the parts conforming (scrapped) from a Rework State: m_{I,j} p_{j,C}."""
    result, sims = case
    for state, conform, scrap in ((X1, "f25", "f26"), (X2, "f35", "f36"), (X12, "f45", "f46")):
        assert_agrees(sims[conform], result.visits[state] * result.transitions[state].conform)
        assert_agrees(sims[scrap], result.visits[state] * result.transitions[state].scrap)


class TestScriptsAnalyticColumn:
    """The script's `S3`: `KandBMarkov_DualChars` (the R3-oracle chain) scaled to the simulation's per-part counts.

    KB's f25 = p25/(1 − p22) is per part entering rework x, while the simulation's f25 is per part started, so
    the script multiplies by the parts entering, p12 + p14·p12/(1 − p14) = p12/(1 − p14).
    """

    MATCHES = {
        "f15": "f15", "f25_p12": "f25", "f35_p13": "f35", "f35_AA": "f35", "f45_p14": "f45",
        "f16": "f16", "f26_p12": "f26", "f36_p13": "f36", "f46_p14": "f46",
        "m12": "m12", "m13": "m13", "m14": "m14",
    }  # fmt: skip

    def test_agrees_with_the_simulation(self, S3, case):
        _, sims = case
        for analytic, simulated in self.MATCHES.items():
            assert_agrees(sims[simulated], getattr(S3, analytic))

    def test_f45_aa_is_not_the_simulated_f45(self, S3, case):
        """D20: f45·p14 is the probability of reaching rework both and then conforming by any route, including
        via rework x or rework y. The simulation's f45 counts conformance from the rework-both draw itself."""
        _, sims = case
        se = sims["f45"].std(ddof=1) / np.sqrt(BATCHES)
        assert S3.f45_AA - sims["f45"].mean() > 4 * se
