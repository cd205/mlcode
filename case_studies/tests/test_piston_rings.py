"""The piston-ring case study: its data, its independent check of the engine, and the web presets it writes."""

import json

import numpy as np
import pytest

from oms import MultivariateNormal
from oms.formats import run
from piston_rings import run_case_study as cs

RINGS = cs.load_rings()
PHASE_ONE = cs.fit([r for r in RINGS if r.phase_one])
SIGMA = round(PHASE_ONE["sigma_pooled"], cs.SIGMA_DP)
MEAN = round(PHASE_ONE["mean"], cs.MEAN_DP)


def test_data_is_the_documented_200_rings_in_40_samples_of_5():
    assert len(RINGS) == 200
    assert sum(r.phase_one for r in RINGS) == 125
    assert {len(x) for x in cs.by_sample(RINGS).values()} == {5}


def test_phase_one_fit_matches_the_textbook_scale():
    # Montgomery rounds R̄ to 0.023 and quotes σ̂ = R̄/d₂ ≈ 0.0099 mm; unrounded it is 0.00979
    assert PHASE_ONE["sigma_rbar"] == pytest.approx(0.0099, abs=0.0002)
    assert (SIGMA, MEAN) == (0.00986, 74.0012)


@pytest.mark.parametrize("half", [cs.PUBLISHED_HALF, 0.03, cs.TIGHT_HALF, 0.012])
@pytest.mark.parametrize("mu", [73.985, 73.995, 74.0, 74.004, 74.015])
def test_engine_matches_the_closed_form(half, mu):
    sequence = cs.sequence_for(half, MultivariateNormal([SIGMA]))
    assert cs.at(sequence, mu)["expected_profit"] == pytest.approx(cs.closed_form(mu, SIGMA, half), abs=1e-10)


def test_simulation_agrees_with_the_closed_form():
    sim = cs.simulate(73.995, SIGMA, cs.TIGHT_HALF, 200_000, seed=1)
    assert abs(sim["expected_profit"] - cs.closed_form(73.995, SIGMA, cs.TIGHT_HALF)) < 4 * sim["standard_error"]


def test_oms_moves_towards_the_reworkable_side_only_when_limits_are_tight():
    published = cs.compare(cs.PUBLISHED_HALF, SIGMA, MEAN)
    tight = cs.compare(cs.TIGHT_HALF, SIGMA, MEAN)
    assert published["gain_vs_nominal"] < 1e-3
    assert tight["gain_vs_nominal"] > 0.5
    assert tight["oms"]["mean_setting"] < cs.NOMINAL


def test_pays_below_interpolates_the_crossing():
    rows = [{"cp": cp, "gain_vs_nominal": g} for cp, g in [(0.8, 0.4), (0.9, 0.2), (1.0, 0.05), (1.1, 0.01)]]
    assert cs.pays_below(rows, 0.1) == pytest.approx(1.0 - 0.1 * (0.1 - 0.05) / (0.2 - 0.05))
    assert cs.pays_below(rows, 5.0) is None


@pytest.mark.parametrize("preset_id", ["cs-piston-rings", "cs-piston-rings-tight"])
def test_presets_on_disk_are_current_and_pass_their_reference(preset_id):
    on_disk = json.loads((cs.PRESETS / f"{preset_id}.json").read_text(encoding="utf-8"))
    assert on_disk == json.loads(json.dumps(cs.presets(SIGMA, MEAN)[preset_id])), "rerun run_case_study.py"
    results = run(on_disk, action="evaluate")
    assert results["reference"]["within_tolerance"] is True


def test_web_optimise_of_the_tight_preset_finds_the_case_study_optimum():
    preset = cs.presets(SIGMA, MEAN)["cs-piston-rings-tight"]
    found = run(preset, action="optimise")["means"]
    expected = cs.compare(cs.TIGHT_HALF, SIGMA, MEAN)["oms"]["mean_setting"]
    assert np.ravel([list(m.values()) for m in found["values"]])[0] == pytest.approx(expected, abs=1e-6)
