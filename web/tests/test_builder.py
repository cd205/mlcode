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


def build(script, sequence=None, result="b.sequence"):
    """Run `script` with `Builder` imported and `b` a Builder over `sequence` (or a blank one); return `result`."""
    source = (f"import {{ Builder }} from {json.dumps((STATIC / 'builder.js').as_uri())};\n"
              f"const input = {json.dumps(sequence)};\n"
              "let b = input === null ? Builder.blank() : new Builder(input);\n"
              f"{script}\n"
              f"process.stdout.write(JSON.stringify({result}));")
    done = subprocess.run([NODE, "--input-type=module", "-e", source], capture_output=True, encoding="utf-8",
                          check=False)
    assert done.returncode == 0, done.stderr
    return json.loads(done.stdout)


def test_builder_unit_tests_pass():
    done = subprocess.run([NODE, "--test", "builder.test.mjs"], cwd=Path(__file__).parent, capture_output=True,
                          text=True, check=False)
    assert done.returncode == 0, done.stdout + done.stderr


def preset(preset_id):
    return client.get(f"/api/presets/{preset_id}").json()


PRESET_IDS = [p["id"] for p in client.get("/api/presets").json()]


def evaluate(sequence):
    response = client.post("/api/evaluate", json={"sequence": sequence})
    assert response.status_code == 200, response.json()
    return response.json()


def test_a_blank_sequence_evaluates():
    results = evaluate(build(""))
    assert [list(mu) for mu in results["means"]["values"]] == [["f1"]]
    assert results["means"]["values"][0]["f1"] == 10  # C17: midway between L = 8 and U = 12


@pytest.mark.parametrize("preset_id", PRESET_IDS)
def test_every_preset_loads_as_a_valid_list_and_gives_its_reference_result(preset_id):
    loaded = build("", preset(preset_id), result="{ rows: b.rows, problems: b.problems, sequence: b.sequence }")
    stages = preset(preset_id)["stages"]
    assert loaded["problems"] == []
    assert len(loaded["rows"]) == sum(len(s["features"]) + 1 for s in stages)
    shapes = [r["label"].rsplit(" · ", 1)[1] for r in loaded["rows"] if r["kind"] == "inspection"]
    assert shapes == ["Parallel" if len(s["features"]) > 1 else "Serial" for s in stages]
    assert loaded["sequence"] == with_split_processing(preset(preset_id))
    assert evaluate(loaded["sequence"])["reference"]["within_tolerance"]


def with_split_processing(sequence):
    """The sequence with each Stage's Processing Cost split evenly across its Operations (C24)."""
    for stage in sequence["stages"]:
        for feature in stage["features"]:
            feature["processing"] = stage["costs"]["processing"] / len(stage["features"])
    return sequence


@pytest.mark.parametrize("preset_id", ["r4", "r8-seq3"])
def test_a_preset_split_into_operation_costs_gives_the_same_results(preset_id):
    loaded = build("", preset(preset_id))
    assert evaluate(loaded) == evaluate(preset(preset_id))


def test_operation_processing_costs_go_to_the_server_and_come_back_from_a_download():
    edits = 'b.setFeature(0, 0, "processing", 30); b.addOperation("grind"); b.addOperation("drill"); b.addInspection();'
    sequence = build(edits, preset("r4"))
    assert [[f["processing"] for f in s["features"]] for s in sequence["stages"]] == [[30, 22.5], [5, 2]]
    assert [s["costs"]["processing"] for s in sequence["stages"]] == [52.5, 7]
    results = evaluate(sequence)
    assert [s["costs"]["processing"] / s["reach_probability"] for s in results["stages"]] == pytest.approx([52.5, 7])
    reloaded = build("b = Builder.upload(b.download());", sequence,
                     result="{ sequence: b.sequence, notes: [0, 1].map((i) => b.processingNote(i)) }")
    assert reloaded == {"sequence": sequence, "notes": [None, None]}


@pytest.mark.parametrize("preset_id", ["r1", "r4", "r8-seq3"])
def test_evaluate_runs_straight_after_adding_operations_and_an_inspection(preset_id):
    sequence = build('b.addOperation("drill"); b.addOperation("drill"); b.addInspection();', preset(preset_id))
    assert [f["name"] for f in sequence["stages"][-1]["features"]] == ["drill", "drill2"]
    results = evaluate(sequence)
    assert len(results["stages"]) == len(preset(preset_id)["stages"]) + 1


def test_a_list_with_problems_hands_out_no_sequence():
    assert build("b.addOperation();") is None
    assert build("b.addInspection();") is None


def test_an_edited_preset_evaluates_without_its_thesis_reference():
    edits = """
        b.setFeature(0, 0, "upper", 13);
        b.setFeature(1, 0, "name", "bore");
        b.setMean(1, "bore", 15.2);
        b.setSigma(1, 0, 0.8);
        b.setCorr(0, 0);
        b.setCost(1, "scrap", "bore", 30);
        b.setFeature(0, 0, "processing", 26);
        b.setSellingPrice(125);
    """
    sequence = build(edits, preset("r5"))
    assert "reference" not in sequence
    assert [s["features"][0]["name"] for s in sequence["stages"]] == ["a", "bore"]
    assert sequence["means"]["values"] == [{"a": 10.466}, {"bore": 15.2}]
    results = evaluate(sequence)
    assert "reference" not in results
    assert results["totals"]["expected_profit"] != pytest.approx(71.41, abs=0.01)


def test_editing_a_parallel_stage_keeps_its_full_cost_table_in_step():
    edits = 'b.setFeature(0, 1, "name", "c"); b.moveOperation(0, 1, -1); b.setFeature(0, 1, "rework_side", "none");'
    sequence = build(edits, preset("r4"))
    assert [f["name"] for f in sequence["stages"][0]["features"]] == ["c", "a"]
    costs = sequence["stages"][0]["costs"]
    assert costs["rework"] == {"c": 12}
    assert costs["scrap"] == {"initial": 27, "c": 27}
    evaluate(sequence)


STAGE_MOVES = {
    # r4 then two Operations in a second Stage: a b | drill drill2 |
    "Operation down into the next Stage": ("b.moveOperation(0, 1, +1);", [["a"], ["b", "drill", "drill2"]]),
    "Operation up into a full table": ("b.moveOperation(1, 0, -1);", [["a", "b", "drill"], ["drill2"]]),
    "Inspection up": ("b.moveInspection(0, -1);", [["a"], ["b", "drill", "drill2"]]),
    "Inspection down": ("b.moveInspection(0, +1);", [["a", "b", "drill"], ["drill2"]]),
    "Inspection deleted": ("b.deleteInspection(0);", [["a", "b", "drill", "drill2"]]),
    "out and back": ("b.moveOperation(1, 1, +1); b.moveInspection(1, +1);", [["a", "b"], ["drill", "drill2"]]),
}


@pytest.mark.parametrize("case", STAGE_MOVES.values(), ids=STAGE_MOVES.keys())
def test_moves_that_change_stages_give_a_sequence_the_api_accepts(case):
    script, names = case
    sequence = build(f'b.addOperation("drill"); b.addOperation("drill"); b.addInspection(); {script}', preset("r4"))
    assert [[f["name"] for f in s["features"]] for s in sequence["stages"]] == names
    assert "reference" not in sequence
    assert [s["costs"]["processing"] for s in sequence["stages"]] == \
        [sum(f["processing"] for f in s["features"]) for s in sequence["stages"]]
    results = evaluate(sequence)
    assert [list(mu) for mu in results["means"]["values"]] == names


def test_a_merge_refused_as_too_big_leaves_the_sequence_as_it_was():
    script = """
        for (const name of ["turn", "drill", "mill"]) b.addOperation(name);
        b.addInspection();
        let message = null;
        try { b.deleteInspection(0); } catch (e) { message = e.message; }
    """
    done = build(script, preset("r4"), result="{ message, sequence: b.sequence }")
    assert done["message"] == "Stage 1 would have 5 Operations; a Stage can have at most 4."
    assert [len(s["features"]) for s in done["sequence"]["stages"]] == [2, 3]
    evaluate(done["sequence"])


def test_download_then_upload_gives_the_same_sequence():
    original = build("b.addOperation(); b.addInspection(); b.moveOperation(1, 1, -1);", preset("r8-seq3"))
    uploaded = build("b = Builder.upload(b.download());", original)
    assert uploaded == original
    assert evaluate(uploaded) == evaluate(original)


# mill and turn in parallel, then drill: with C17's free rework, Optimise ran every mean to its bound (#41).
MILL_TURN_DRILL = """
b.setSellingPrice(10);
b.setFeature(0, 0, "name", "mill");
b.addOperation("turn");
b.moveInspection(0, +1);
b.addOperation("drill");
b.addInspection();
"""


def test_a_new_sequence_optimises_to_means_near_the_midpoints_not_the_bounds():
    # C30: with rework at half the Processing Cost, oversizing every part no longer pays.
    sequence = build(MILL_TURN_DRILL)
    assert sequence["stages"][1]["costs"]["rework_per_feature"] == {"drill": 1}
    response = client.post("/api/optimise", json={"sequence": sequence})
    assert response.status_code == 200, response.json()
    means = [mu for stage in response.json()["means"]["values"] for mu in stage.values()]
    assert all(10 < mu < 11 for mu in means), means


def test_a_material_value_and_a_scrap_cost_recovering_it_are_accepted():
    sequence = build(MILL_TURN_DRILL + "b.setMaterialValue(5); b.setStageScrap(1, -5);")
    assert sequence["material_value"] == 5
    totals = evaluate(sequence)["totals"]
    assert totals["material_cost"] == 5
    assert totals["scrap_cost"] < 0
