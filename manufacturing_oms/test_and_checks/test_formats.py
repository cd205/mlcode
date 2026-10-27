"""The sequence format and run() (web_app_plan.md §4-§5): presets, results JSON and per-Pass counts."""

import copy
import json
from pathlib import Path

import pytest

from oms.formats import dump_sequence, load_sequence, run

PRESETS = Path(__file__).resolve().parents[1] / "presets"


def preset(name):
    return json.loads((PRESETS / f"{name}.json").read_text())


class TestR1:
    """Thesis Fig 3.12/3.14: μ = 5, σ = 1, [3, 7], Rework Side above U."""

    def test_reproduces_the_reference_final_conformance(self):
        results = run(preset("r1"), action="evaluate", n_parts=10_000)
        reference = results["reference"]
        assert reference["quantity"] == "final_conformance"
        assert reference["computed"] == pytest.approx(0.97672, abs=reference["tolerance"])
        assert reference["within_tolerance"] is True

    def test_per_pass_counts_match_fig_3_14(self):
        stage = run(preset("r1"), n_parts=10_000)["stages"][0]
        totals = {kind: [round(sum(p[kind].values())) for p in stage["passes"]] for kind in ("conform", "rework", "scrap")}
        # Fig 3.14 prints C = 9545, 217, 5; R = 228, 5; S = 228, 5. The third Pass sends 0.1 parts to
        # rework and 0.1 to scrap, below the 0.5-part stop, so those round to 0 and are left as `remaining`.
        assert totals == {"conform": [9545, 217, 5], "rework": [228, 5, 0], "scrap": [228, 5, 0]}
        assert 0 < stage["remaining"] < 0.5


def stage_doc(name, lower, upper, side="upper", sigma=1.0, pc=0.0, rc=0.0, sc=0.0):
    reworkable = side != "none"
    return {
        "features": [{"name": name, "lower": lower, "upper": upper, "rework_side": side}],
        "variation": {"type": "normal", "sigmas": [sigma], "corr": 0.0},
        "costs": {"processing": pc, "rework": {name: rc} if reworkable else {},
                  "scrap": {"initial": sc, name: sc} if reworkable else {"initial": sc}},
        "inspection": {"per_stage": 0.0, "per_feature": 0.0},
    }


def sequence_doc(stages, means, selling_price=0.0):
    return {"format_version": 1, "name": "test", "selling_price": selling_price, "stages": stages,
            "means": {"scheme": "per_feature", "values": means}}


class TestPassCounts:
    def total(self, stage, kind):
        return sum(sum(p[kind].values()) for p in stage["passes"])

    @pytest.mark.parametrize(
        "mu, n_passes",
        [(5.0, 3), (9.0, 20)],  # μ = U + 2σ: 98% of each Pass goes back to rework, so the 20-Pass cap is hit
    )
    def test_conform_scrap_and_remaining_add_up_to_the_parts_entering(self, mu, n_passes):
        stage = run(sequence_doc([stage_doc("x", 3.0, 7.0)], [{"x": mu}]), n_parts=10_000)["stages"][0]
        assert len(stage["passes"]) == n_passes
        closed = self.total(stage, "conform") + self.total(stage, "scrap") + stage["remaining"]
        assert closed == pytest.approx(10_000, rel=1e-12)

    def test_parts_left_at_the_cap_are_reported_as_remaining(self):
        stage = run(sequence_doc([stage_doc("x", 3.0, 7.0)], [{"x": 9.0}]), n_parts=10_000)["stages"][0]
        # Each Pass sends p_R = Φ(2) of its parts back, so 10 000 · Φ(2)^20 ≈ 6314 are left after 20 Passes.
        assert stage["remaining"] == pytest.approx(10_000 * 0.9772498680518208**20, rel=1e-9)

    def test_later_stages_count_only_the_parts_that_reach_them(self):
        doc = sequence_doc([stage_doc("a", 8.0, 12.0), stage_doc("b", 13.0, 17.0)], [{"a": 10.5}, {"b": 15.6}])
        results = run(doc, n_parts=10_000)
        first, second = results["stages"]
        assert second["reach_probability"] == pytest.approx(first["final_conformance"], rel=1e-15)
        entering = 10_000 * second["reach_probability"]
        assert sum(second["passes"][0]["conform"].values()) + sum(second["passes"][0]["scrap"].values()) + sum(
            second["passes"][0]["rework"].values()) == pytest.approx(entering, rel=1e-12)
        conformed = self.total(second, "conform")
        assert conformed + self.total(second, "scrap") + second["remaining"] == pytest.approx(entering, rel=1e-12)
        assert conformed == pytest.approx(entering * second["final_conformance"], abs=0.5)


class TestRoundTrip:
    def test_dumping_a_loaded_preset_gives_the_same_json(self):
        assert dump_sequence(load_sequence(preset("r1"))) == preset("r1")

    def test_dumped_json_survives_json_encoding(self):
        doc = sequence_doc([stage_doc("a", 8.0, 12.0, pc=25.0, rc=10.0, sc=15.0), stage_doc("b", 1.0, 2.0, "none")],
                           [{"a": 10.6}, {"b": 1.5}], selling_price=120.0)
        assert json.loads(json.dumps(dump_sequence(load_sequence(doc)))) == doc


def broken(path, value):
    """r1 with the field at `path` (keys and list indices) set to `value`, or deleted if `value` is DELETE."""
    doc = copy.deepcopy(preset("r1"))
    target = doc
    for key in path[:-1]:
        target = target[key]
    if value is DELETE:
        del target[path[-1]]
    else:
        target[path[-1]] = value
    return doc


DELETE = object()


class TestMalformedInput:
    @pytest.mark.parametrize(
        "path, value, message",
        [
            (("stages",), [], "stages: a Sequence needs at least one Stage"),
            (("format_version",), 2, "format_version: only version 1"),
            (("selling_price",), DELETE, "sequence: missing selling_price"),
            (("selling_price",), -1, "selling_price: must be non-negative"),
            (("colour",), "red", "sequence: unknown field colour"),
            (("stages", 0, "features", 0, "lower"), "3", "stages[0].features[0].lower: expected a finite number"),
            (("stages", 0, "features", 0, "lower"), 8, "stages[0].features[0]: Feature 'x': lower limit must be below upper"),
            (("stages", 0, "features", 0, "name"), "x y", "stages[0].features[0].name: Feature names are 1 to 16"),
            (("stages", 0, "features", 0, "rework_side"), "above", "stages[0].features[0].rework_side: must be one"),
            (("stages", 0, "variation", "sigmas"), [1, 1], "stages[0].variation.sigmas: need one per Feature"),
            (("stages", 0, "variation", "sigmas"), [0], "stages[0].variation: standard deviations must be positive"),
            (("stages", 0, "costs", "rework"), {"y": 0}, "stages[0].costs.rework: state key 'y'"),
            (("stages", 0, "costs", "scrap"), {"initial": 0}, "stages[0]: scrap costs must cover exactly"),
            (("means", "scheme"), "per_state", "means.scheme: only 'per_feature' is supported"),
            (("means", "values", 0), {"y": 5}, "means.values[0]: need a mean for exactly ['x']"),
            (("reference", "quantity"), "profit", "reference.quantity: must be one of"),
            (("stages", 0, "variation", "corr"), [[1]], "stages[0].variation.corr: only a scalar correlation"),
        ],
    )
    def test_raises_a_value_error_naming_the_field(self, path, value, message):
        with pytest.raises(ValueError) as error:
            load_sequence(broken(path, value))
        assert str(error.value).startswith(message)

    def test_not_an_object(self):
        with pytest.raises(ValueError, match="sequence: expected an object, got a list"):
            load_sequence([])

    @pytest.mark.parametrize("n_parts", [0, -1, float("inf"), float("nan"), True])
    def test_run_rejects_a_bad_part_count(self, n_parts):
        with pytest.raises(ValueError, match="n_parts: must be a positive finite number"):
            run(preset("r1"), n_parts=n_parts)
