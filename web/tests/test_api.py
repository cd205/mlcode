"""The web API (web_app_plan.md §6, C18), tested over HTTP."""

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app, raise_server_exceptions=False)


def r1():
    response = client.get("/api/presets/r1")
    assert response.status_code == 200
    return response.json()


def test_root_serves_the_page():
    response = client.get("/")
    assert response.status_code == 200
    assert "<title>OMS Sequence Builder</title>" in response.text


def test_presets_lists_r1_with_its_name():
    response = client.get("/api/presets")
    assert response.status_code == 200
    r1_entry = next(p for p in response.json() if p["id"] == "r1")
    assert r1_entry["name"].startswith("R1:")
    assert "description" in r1_entry


def test_unknown_preset_is_404():
    response = client.get("/api/presets/nope")
    assert response.status_code == 404
    assert "nope" in response.json()["detail"]


def test_evaluate_r1_matches_its_reference_and_fig_3_14():
    response = client.post("/api/evaluate", json={"sequence": r1(), "n_parts": 10_000})
    assert response.status_code == 200
    results = response.json()
    assert results["reference"]["computed"] == pytest.approx(0.97672, abs=0.000005)
    assert results["reference"]["within_tolerance"] is True
    conform = [round(sum(p["conform"].values())) for p in results["stages"][0]["passes"]]
    assert conform == [9545, 217, 5]


R8_STAGES = {"r8-seq1": 4, "r8-seq2": 3, "r8-seq3": 3, "r8-seq4": 3, "r8-seq5": 2, "r8-seq6": 2, "r8-seq7": 2,
             "r8-seq8": 1}


@pytest.mark.parametrize("preset_id, n_stages", [("r2", 1), ("r3", 1), ("r4", 1), ("r5", 2), *R8_STAGES.items(),
                                                ("cs-piston-rings", 1), ("cs-piston-rings-tight", 1)])
def test_evaluate_presets_match_their_references(preset_id, n_stages):
    sequence = client.get(f"/api/presets/{preset_id}").json()
    response = client.post("/api/evaluate", json={"sequence": sequence, "n_parts": 10_000})
    assert response.status_code == 200
    results = response.json()
    assert results["reference"]["within_tolerance"] is True
    assert len(results["stages"]) == n_stages
    for stage in results["stages"]:
        closed = sum(sum(p[kind].values()) for p in stage["passes"] for kind in ("conform", "scrap"))
        assert closed + stage["remaining"] == pytest.approx(10_000 * stage["reach_probability"], rel=1e-12)


@pytest.mark.parametrize("objective, mu", [("expected_profit", 10.61), ("production_cost", 10.09)])
def test_optimise_r2_returns_the_printed_optimum_and_the_optimiser_record(objective, mu):
    sequence = client.get("/api/presets/r2").json()
    response = client.post("/api/optimise", json={"sequence": sequence, "objective": objective})
    assert response.status_code == 200
    results = response.json()
    assert results["action"] == "optimise"
    assert results["means"]["values"][0]["x"] == pytest.approx(mu, abs=0.005)
    record = results["optimisation"]
    assert record["objective"] == objective
    assert record["bounds"] == {"x": [5.0, 15.0]}
    assert {"method", "n_starts", "seed", "n_evaluations", "success"} <= set(record)


def test_optimised_means_can_be_evaluated_and_undone():
    sequence = client.get("/api/presets/r2").json()
    before = client.post("/api/evaluate", json={"sequence": sequence}).json()
    optimised = client.post("/api/optimise", json={"sequence": sequence}).json()
    previous, sequence["means"] = sequence["means"], optimised["means"]  # C16: replace, keeping one undo slot
    replaced = client.post("/api/evaluate", json={"sequence": sequence}).json()
    assert replaced["totals"] == optimised["totals"]
    sequence["means"] = previous
    assert client.post("/api/evaluate", json={"sequence": sequence}).json() == before


def test_optimise_with_an_unknown_objective_is_422():
    response = client.post("/api/optimise", json={"sequence": r1(), "objective": "profit"})
    assert_readable_error(response, 422, "objective")


def test_presets_lists_the_serial_and_parallel_presets():
    ids = {p["id"] for p in client.get("/api/presets").json()}
    assert {"r1", "r2", "r3", "r4", "r5"} <= ids


def test_presets_lists_the_eight_inspection_placements_in_order():
    ids = [p["id"] for p in client.get("/api/presets").json()]
    assert [i for i in ids if i.startswith("r8-")] == list(R8_STAGES)


def assert_readable_error(response, status, *fragments):
    assert response.status_code == status
    detail = response.json()["detail"]
    assert isinstance(detail, str)
    assert "Traceback" not in detail and ".py" not in detail
    for fragment in fragments:
        assert fragment in detail


def test_parallel_stage_reports_passes_by_rework_state():
    sequence = client.get("/api/presets/r4").json()
    results = client.post("/api/evaluate", json={"sequence": sequence}).json()
    stage = results["stages"][0]
    assert set(stage["visits"]) == {"initial", "a", "b", "a+b"}
    assert set(stage["passes"][0]["rework"]) == {"a", "b", "a+b"}


def test_cost_shortcut_mixed_with_a_full_table_is_422():
    sequence = client.get("/api/presets/r4").json()
    sequence["stages"][0]["costs"]["rework_per_feature"] = {"a": 15, "b": 12}
    response = client.post("/api/evaluate", json={"sequence": sequence})
    assert_readable_error(response, 422, "stages[0].costs", "not a mix")


def test_missing_state_key_is_422_naming_the_state():
    sequence = client.get("/api/presets/r4").json()
    del sequence["stages"][0]["costs"]["rework"]["a+b"]
    response = client.post("/api/evaluate", json={"sequence": sequence})
    assert_readable_error(response, 422, "stages[0].costs.rework", "missing state a+b")


def r4_with_feature_processing(a, b):
    """r4 with Processing Costs on its Features (C22) and no Stage total."""
    sequence = client.get("/api/presets/r4").json()
    for feature, cost in zip(sequence["stages"][0]["features"], (a, b)):
        if cost is not None:
            feature["processing"] = cost
    del sequence["stages"][0]["costs"]["processing"]
    return sequence


def test_per_feature_processing_costs_evaluate_as_their_stage_total():
    response = client.post("/api/evaluate", json={"sequence": r4_with_feature_processing(20, 25)})
    assert response.status_code == 200
    assert response.json()["reference"]["within_tolerance"]


def test_stage_total_differing_from_the_feature_sum_is_422():
    sequence = r4_with_feature_processing(20, 25)
    sequence["stages"][0]["costs"]["processing"] = 40
    response = client.post("/api/evaluate", json={"sequence": sequence})
    assert_readable_error(response, 422, "stages[0].costs.processing", "must equal the sum")


def test_processing_cost_on_only_some_features_is_422():
    response = client.post("/api/evaluate", json={"sequence": r4_with_feature_processing(20, None)})
    assert_readable_error(response, 422, "stages[0].features[1].processing", "missing")


def test_request_without_a_sequence_is_422_with_a_readable_message():
    response = client.post("/api/evaluate", json={"n_parts": 10})
    assert_readable_error(response, 422, "sequence")


def test_request_that_is_not_json_is_422():
    response = client.post("/api/evaluate", content=b"{not json", headers={"content-type": "application/json"})
    assert_readable_error(response, 422, "not valid JSON")


def test_engine_value_error_is_422_naming_the_bad_field():
    sequence = r1()
    sequence["stages"][0]["features"][0]["lower"] = 9  # above upper = 7
    response = client.post("/api/evaluate", json={"sequence": sequence})
    assert_readable_error(response, 422, "stages[0].features[0]")


@pytest.mark.parametrize("n_parts", [-1, True, "500"])
def test_bad_n_parts_is_422(n_parts):
    response = client.post("/api/evaluate", json={"sequence": r1(), "n_parts": n_parts})
    assert_readable_error(response, 422, "n_parts")


def test_corrupt_preset_file_is_a_generic_500(tmp_path, monkeypatch):
    (tmp_path / "broken.json").write_text("{not json", encoding="utf-8")
    monkeypatch.setattr("app.main.PRESETS", tmp_path)
    assert_readable_error(client.get("/api/presets/broken"), 500)


def test_unexpected_error_is_a_generic_500_logged_on_the_server(monkeypatch, caplog):
    def broken_run(*args, **kwargs):
        raise ZeroDivisionError("secret engine detail")

    monkeypatch.setattr("app.main.run", broken_run)
    response = client.post("/api/evaluate", json={"sequence": r1()})
    assert_readable_error(response, 500)
    assert "secret" not in response.text
    assert "secret engine detail" in caplog.text
