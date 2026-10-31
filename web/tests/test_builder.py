"""The builder (static/builder.js) driven through node, its sequences checked by the real API (web_app_plan.md §7)."""

import json
import shutil
import subprocess
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app, raise_server_exceptions=False)
STATIC = Path(__file__).resolve().parents[1] / "static"
NODE = shutil.which("node")
pytestmark = pytest.mark.skipif(NODE is None, reason="the builder tests need node")


def build(script, sequence=None):
    """Run `script` with `Builder` imported and `b` a Builder over `sequence` (or a blank one); return b.sequence."""
    source = (f"import {{ Builder }} from {json.dumps((STATIC / 'builder.js').as_uri())};\n"
              f"const input = {json.dumps(sequence)};\n"
              "let b = input === null ? Builder.blank() : new Builder(input);\n"
              f"{script}\n"
              "process.stdout.write(JSON.stringify(b.sequence));")
    done = subprocess.run([NODE, "--input-type=module", "-e", source], capture_output=True, text=True, check=False)
    assert done.returncode == 0, done.stderr
    return json.loads(done.stdout)


def test_builder_unit_tests_pass():
    done = subprocess.run([NODE, "--test", "builder.test.mjs"], cwd=Path(__file__).parent, capture_output=True,
                          text=True, check=False)
    assert done.returncode == 0, done.stdout + done.stderr


def preset(preset_id):
    return client.get(f"/api/presets/{preset_id}").json()


def evaluate(sequence):
    response = client.post("/api/evaluate", json={"sequence": sequence})
    assert response.status_code == 200, response.json()
    return response.json()


def test_a_blank_sequence_evaluates():
    results = evaluate(build(""))
    assert [list(mu) for mu in results["means"]["values"]] == [["f1"]]
    assert results["means"]["values"][0]["f1"] == 10  # C17: midway between L = 8 and U = 12


@pytest.mark.parametrize("preset_id", ["r4", "r5", "r8-seq3"])
def test_evaluate_runs_straight_after_add_feature(preset_id):
    sequence = build("b.addFeature(0);", preset(preset_id))
    assert len(sequence["stages"][0]["features"]) == len(preset(preset_id)["stages"][0]["features"]) + 1
    evaluate(sequence)


@pytest.mark.parametrize("preset_id", ["r1", "r4", "r8-seq3"])
def test_evaluate_runs_straight_after_add_stage(preset_id):
    sequence = build("b.addStage();", preset(preset_id))
    results = evaluate(sequence)
    assert len(results["stages"]) == len(preset(preset_id)["stages"]) + 1


def test_an_edited_preset_evaluates_without_its_thesis_reference():
    edits = """
        b.setFeature(0, 0, "upper", 13);
        b.setFeature(1, 0, "name", "bore");
        b.setMean(1, "bore", 15.2);
        b.setSigma(1, 0, 0.8);
        b.setCorr(0, 0);
        b.setCost(1, "scrap", "bore", 30);
        b.setProcessing(0, 26);
        b.setSellingPrice(125);
        b.moveStage(1, -1);
    """
    sequence = build(edits, preset("r5"))
    assert "reference" not in sequence
    assert [s["features"][0]["name"] for s in sequence["stages"]] == ["bore", "a"]
    assert sequence["means"]["values"] == [{"bore": 15.2}, {"a": 10.466}]
    results = evaluate(sequence)
    assert "reference" not in results
    assert results["totals"]["expected_profit"] != pytest.approx(71.41, abs=0.01)


def test_editing_a_parallel_stage_keeps_its_full_cost_table_in_step():
    sequence = build('b.setFeature(0, 1, "name", "c"); b.addFeature(0); b.setFeature(0, 0, "rework_side", "none");',
                     preset("r4"))
    costs = sequence["stages"][0]["costs"]
    assert costs["rework"] == {"c": 12, "f1": 0, "c+f1": 12}
    assert costs["scrap"] == {"initial": 27, "c": 27, "f1": 27, "c+f1": 27}
    evaluate(sequence)


def test_download_then_upload_gives_the_same_sequence():
    original = build("b.addFeature(1); b.addStage(); b.deleteFeature(1, 0);", preset("r8-seq3"))
    uploaded = build("b = Builder.upload(b.download());", original)
    assert uploaded == original
    assert evaluate(uploaded) == evaluate(original)
