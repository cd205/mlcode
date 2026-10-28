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


@pytest.mark.parametrize("preset_id, n_stages", [("r2", 1), ("r5", 2)])
def test_evaluate_serial_presets_match_their_references(preset_id, n_stages):
    sequence = client.get(f"/api/presets/{preset_id}").json()
    response = client.post("/api/evaluate", json={"sequence": sequence, "n_parts": 10_000})
    assert response.status_code == 200
    results = response.json()
    assert results["reference"]["within_tolerance"] is True
    assert len(results["stages"]) == n_stages
    for stage in results["stages"]:
        closed = sum(sum(p[kind].values()) for p in stage["passes"] for kind in ("conform", "scrap"))
        assert closed + stage["remaining"] == pytest.approx(10_000 * stage["reach_probability"], rel=1e-12)


def test_presets_lists_the_serial_presets():
    ids = {p["id"] for p in client.get("/api/presets").json()}
    assert {"r1", "r2", "r5"} <= ids


def assert_readable_error(response, status, *fragments):
    assert response.status_code == status
    detail = response.json()["detail"]
    assert isinstance(detail, str)
    assert "Traceback" not in detail and ".py" not in detail
    for fragment in fragments:
        assert fragment in detail


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
