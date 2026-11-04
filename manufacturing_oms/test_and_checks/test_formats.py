"""The sequence format and run() (web_app_plan.md §4-§5): presets, results JSON and per-Pass counts."""

import copy
import json
from pathlib import Path

import pytest

from oms.formats import dump_sequence, load_sequence, run

PRESETS = Path(__file__).resolve().parents[1] / "presets"
DELETE = object()  # in a test document, deletes the field


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


class TestSerialPresets:
    """R2 (Table 3.3, one Stage) and R5 (Table 3.5, two Serial Stages) at the printed means."""

    @pytest.mark.parametrize(
        "name, value",
        [
            ("r2", 93.4377),  # Table 3.3 prints only μ* = 10.61; this is the closed form there
            ("r5", 71.41),  # Table 3.5 text: "The highest profit (71.41)"
        ],
    )
    def test_reproduces_the_reference_expected_profit(self, name, value):
        reference = run(preset(name))["reference"]
        assert reference["quantity"] == "expected_profit"
        assert reference["value"] == value
        assert reference["computed"] == pytest.approx(value, abs=reference["tolerance"])
        assert reference["within_tolerance"] is True

    def test_r5_reports_the_printed_means_per_stage(self):
        assert run(preset("r5"))["means"]["values"] == [{"a": 10.466}, {"b": 15.591}]

    @pytest.mark.parametrize("name", ["r2", "r5"])
    def test_per_pass_counts_account_for_every_part_entering_each_stage(self, name):
        results = run(preset(name), n_parts=10_000)
        for stage in results["stages"]:
            entering = 10_000 * stage["reach_probability"]
            passes = stage["passes"]
            conformed = sum(sum(p["conform"].values()) for p in passes)
            scrapped = sum(sum(p["scrap"].values()) for p in passes)
            assert conformed + scrapped + stage["remaining"] == pytest.approx(entering, rel=1e-12)
            assert conformed == pytest.approx(entering * stage["final_conformance"], abs=0.5)

    def test_r5_second_stage_is_reached_by_the_first_stages_conforming_parts(self):
        first, second = run(preset("r5"))["stages"]
        assert second["reach_probability"] == pytest.approx(first["final_conformance"], rel=1e-15)
        assert 0.9 < second["reach_probability"] < 1

    @pytest.mark.parametrize("name", ["r2", "r5"])
    def test_round_trips(self, name):
        assert dump_sequence(load_sequence(preset(name))) == preset(name)


class TestParallelPresets:
    """R3 (Table 3.1) and R4 (Table 3.7): one Parallel Stage of two Features, at the printed means."""

    @pytest.mark.parametrize(
        "name, value",
        [
            ("r3", 71.4287),  # Table 3.1, Eq 3.44 cost formula
            ("r4", 71.17),  # Table 3.7
        ],
    )
    def test_reproduces_the_reference_expected_profit(self, name, value):
        reference = run(preset(name))["reference"]
        assert reference["quantity"] == "expected_profit"
        assert reference["value"] == value
        assert reference["computed"] == pytest.approx(value, abs=reference["tolerance"])
        assert reference["within_tolerance"] is True

    @pytest.mark.parametrize("name", ["r3", "r4"])
    def test_per_pass_counts_are_split_by_rework_state_and_close(self, name):
        stage = run(preset(name), n_parts=10_000)["stages"][0]
        first = stage["passes"][0]
        assert set(first["conform"]) == {"initial"}
        assert set(first["rework"]) == {"a", "b", "a+b"}
        assert set(stage["passes"][1]["conform"]) == {"a", "b", "a+b"}
        conformed = sum(sum(p["conform"].values()) for p in stage["passes"])
        scrapped = sum(sum(p["scrap"].values()) for p in stage["passes"])
        assert conformed + scrapped + stage["remaining"] == pytest.approx(10_000, rel=1e-12)
        assert conformed == pytest.approx(10_000 * stage["final_conformance"], abs=0.5)

    @pytest.mark.parametrize("name", ["r3", "r4"])
    def test_round_trips(self, name):
        assert dump_sequence(load_sequence(preset(name))) == preset(name)


# Table 3.9's E(PR) and Fig 3.27's Stages, and the I column with Seq 8 corrected to 0.5 + 4 × 0.5 (D10a).
R8 = {
    1: (41.7523, [["f1"], ["f2"], ["f3"], ["f4"]], 4.0),
    2: (41.4665, [["f1", "f2"], ["f3"], ["f4"]], 3.5),
    3: (41.6588, [["f1"], ["f2", "f3"], ["f4"]], 3.5),
    4: (41.6501, [["f1"], ["f2"], ["f3", "f4"]], 3.5),
    5: (41.3642, [["f1", "f2"], ["f3", "f4"]], 3.0),
    6: (41.4215, [["f1"], ["f2", "f3", "f4"]], 3.0),
    7: (41.2628, [["f1", "f2", "f3"], ["f4"]], 3.0),
    8: (40.8657, [["f1", "f2", "f3", "f4"]], 2.5),
}


class TestR8Presets:
    """R8 (Tables 3.8, 3.9, Fig 3.27): one preset per Inspection placement for f1-f4, at the printed means."""

    @pytest.mark.parametrize("k", list(R8))
    def test_reproduces_table_3_9(self, k):
        value, groups, inspection_cost = R8[k]
        doc = preset(f"r8-seq{k}")
        assert [[f["name"] for f in s["features"]] for s in doc["stages"]] == groups
        results = run(doc)
        reference = results["reference"]
        assert (reference["source"], reference["quantity"], reference["value"]) == ("Table 3.9", "expected_profit", value)
        assert reference["within_tolerance"] is True
        assert results["totals"]["inspection_cost"] == inspection_cost

    @pytest.mark.parametrize("k", (6, 7, 8))
    def test_stages_of_three_or_four_features_note_the_eq_3_59_gap(self, k):
        reference = preset(f"r8-seq{k}")["reference"]
        assert "D1" in reference["note"] and "D10" in reference["note"]
        assert 5e-5 < reference["tolerance"] <= 5e-4  # printed precision plus the extra expected scrap (ADR 0001)

    @pytest.mark.parametrize("k", list(R8))
    def test_per_pass_counts_add_up_to_the_parts_entering_each_stage(self, k):
        results = run(preset(f"r8-seq{k}"), n_parts=10_000)
        for stage in results["stages"]:
            entering = 10_000 * stage["reach_probability"]
            conformed = sum(sum(p["conform"].values()) for p in stage["passes"])
            scrapped = sum(sum(p["scrap"].values()) for p in stage["passes"])
            assert conformed + scrapped + stage["remaining"] == pytest.approx(entering, rel=1e-12)
            assert conformed == pytest.approx(entering * stage["final_conformance"], abs=0.5)

    def test_one_stage_of_four_features_has_15_rework_states(self):
        (stage,) = run(preset("r8-seq8"))["stages"]
        assert len(stage["transitions"]) == 16  # the Initial State and 2^4 − 1 Rework States
        assert "f1+f2+f3+f4" in stage["transitions"]

    @pytest.mark.parametrize("k", list(R8))
    def test_round_trips(self, k):
        assert dump_sequence(load_sequence(preset(f"r8-seq{k}"))) == preset(f"r8-seq{k}")


def r4_with_costs(costs):
    doc = preset("r4")
    doc["stages"][0]["costs"] = costs
    return doc


R4_SHORTCUT = {"processing": 45, "rework_per_feature": {"a": 15, "b": 12}, "scrap_per_feature": {"a": 10, "b": 17}}


class TestCostShortcut:
    """C8: per-Feature costs build the additive tables (Table 3.7); never mixed with full tables."""

    def test_gives_the_same_results_as_the_full_tables(self):
        assert run(r4_with_costs(R4_SHORTCUT)) == run(preset("r4"))

    def test_is_dumped_as_full_tables(self):
        assert dump_sequence(load_sequence(r4_with_costs(R4_SHORTCUT))) == preset("r4")

    @pytest.mark.parametrize(
        "costs, message",
        [
            ({**R4_SHORTCUT, "rework": {"a": 15, "b": 12, "a+b": 27}},
             "stages[0].costs: give either rework and scrap tables or rework_per_feature and scrap_per_feature"),
            ({"processing": 45, "rework_per_feature": {"a": 15, "b": 12}},
             "stages[0].costs: missing scrap_per_feature"),
            ({**R4_SHORTCUT, "scrap_per_feature": {"a": 10}},
             "stages[0].costs.scrap_per_feature: need a cost for exactly ['a', 'b'], got ['a']"),
            ({**R4_SHORTCUT, "rework_per_feature": {"a": 15, "c": 1}},
             "stages[0].costs.rework_per_feature: need a cost for exactly the reworkable Features ['a', 'b'], "
             "got ['a', 'c']"),
            ({**R4_SHORTCUT, "scrap": 27}, "stages[0].costs: give either"),
            ({**R4_SHORTCUT, "rework_costs": {}}, "stages[0].costs: unknown field rework_costs"),
            ({"processing": 45, "rework": {}, "scrap": {}, "extra": 1}, "stages[0].costs: unknown field extra"),
            ({**R4_SHORTCUT, "rework_per_feature": {"a": -1, "b": 12}},
             "stages[0].costs.rework_per_feature.a: must be non-negative"),
        ],
    )
    def test_rejects_bad_shortcuts(self, costs, message):
        with pytest.raises(ValueError) as error:
            load_sequence(r4_with_costs(costs))
        assert str(error.value).startswith(message)

    def test_a_feature_without_rework_has_no_rework_cost(self):
        doc = r4_with_costs({**R4_SHORTCUT, "rework_per_feature": {"a": 15}})
        doc["stages"][0]["features"][1]["rework_side"] = "none"
        costs = dump_sequence(load_sequence(doc))["stages"][0]["costs"]
        assert costs["rework"] == {"a": 15}
        assert costs["scrap"] == {"initial": 27, "a": 27}


def r4_with_feature_processing(a=20, b=25, total=DELETE):
    """r4 with Processing Costs on its Features; the Stage total is left out unless given."""
    doc = preset("r4")
    for feature, cost in zip(doc["stages"][0]["features"], (a, b)):
        if cost is not DELETE:
            feature["processing"] = cost
    if total is DELETE:
        del doc["stages"][0]["costs"]["processing"]
    else:
        doc["stages"][0]["costs"]["processing"] = total
    return doc


class TestFeatureProcessing:
    """C22: each Feature (Operation) may carry its own Processing Cost; the Stage's is their sum."""

    def test_the_stage_total_may_be_omitted(self):
        assert run(r4_with_feature_processing()) == run(preset("r4"))

    def test_a_stage_total_matching_the_sum_to_1e_9_is_accepted(self):
        assert run(r4_with_feature_processing(total=45 + 5e-10)) == run(preset("r4"))

    @pytest.mark.parametrize("total", [44, 45 + 2e-9])
    def test_a_stage_total_differing_from_the_sum_is_rejected(self, total):
        with pytest.raises(ValueError) as error:
            load_sequence(r4_with_feature_processing(total=total))
        assert str(error.value).startswith(f"stages[0].costs.processing: must equal the sum of the Features' "
                                           f"Processing Costs, 45.0, got {float(total)!r}")

    @pytest.mark.parametrize("total", [DELETE, 45])
    def test_some_but_not_all_features_having_one_is_rejected(self, total):
        with pytest.raises(ValueError) as error:
            load_sequence(r4_with_feature_processing(b=DELETE, total=total))
        assert str(error.value).startswith("stages[0].features[1].processing: missing; give a Processing Cost for "
                                           "every Feature of the Stage or for none")

    def test_without_them_the_stage_total_is_still_required(self):
        with pytest.raises(ValueError) as error:
            load_sequence(r4_with_feature_processing(a=DELETE, b=DELETE))
        assert str(error.value).startswith("stages[0].costs: missing processing")

    def test_dumping_writes_them_and_the_stage_total(self):
        dumped = dump_sequence(load_sequence(r4_with_feature_processing()))
        assert dumped == r4_with_feature_processing(total=45.0)
        assert load_sequence(dumped) == load_sequence(r4_with_feature_processing())

    def test_work_with_the_cost_shortcut(self):
        doc = r4_with_feature_processing()
        doc["stages"][0]["costs"] = {k: v for k, v in R4_SHORTCUT.items() if k != "processing"}
        assert run(doc) == run(preset("r4"))
        assert dump_sequence(load_sequence(doc)) == r4_with_feature_processing(total=45.0)

    def test_a_shortcut_total_differing_from_the_sum_is_rejected(self):
        doc = r4_with_feature_processing()
        doc["stages"][0]["costs"] = {**R4_SHORTCUT, "processing": 40}
        with pytest.raises(ValueError, match=r"^stages\[0\]\.costs\.processing: must equal the sum"):
            load_sequence(doc)

    def test_only_stages_with_them_dump_them(self):
        doc = sequence_doc([stage_doc("a", 8.0, 12.0, pc=25.0), stage_doc("b", 1.0, 2.0, pc=5.0)],
                           [{"a": 10.6}, {"b": 1.5}])
        doc["stages"][1]["features"][0]["processing"] = 5.0
        assert json.loads(json.dumps(dump_sequence(load_sequence(doc)))) == doc

    def test_a_negative_one_is_rejected(self):
        with pytest.raises(ValueError) as error:
            load_sequence(r4_with_feature_processing(a=-1))
        assert str(error.value).startswith("stages[0].features[0].processing: must be non-negative")


class TestStateKeys:
    """C7: "initial" and Feature names joined by '+'; order ignored when parsing, Feature order when writing."""

    def test_parsing_ignores_the_order_of_feature_names(self):
        doc = r4_with_costs({"processing": 45, "rework": {"b+a": 27, "b": 12, "a": 15},
                             "scrap": {"a+b": 27, "b": 27, "initial": 27, "a": 27}})
        assert run(doc) == run(preset("r4"))
        assert dump_sequence(load_sequence(doc)) == preset("r4")

    @pytest.mark.parametrize(
        "table, keys, message",
        [
            ("rework", {"a": 15, "b": 12}, "stages[0].costs.rework: missing state a+b"),
            ("scrap", {"a": 27, "b": 27, "a+b": 27}, "stages[0].costs.scrap: missing state initial"),
            ("rework", {"initial": 0, "a": 15, "b": 12, "a+b": 27}, "stages[0].costs.rework: unexpected state initial"),
            ("rework", {"a": 15, "b": 12, "a+b": 27, "b+a": 27}, "stages[0].costs.rework: state 'b+a' is given twice"),
            ("rework", {"a": 15, "b": 12, "a+c": 27}, "stages[0].costs.rework: state key 'a+c' must be"),
            ("rework", {"a": 15, "b": 12, "a+a": 27}, "stages[0].costs.rework: state key 'a+a' must be"),
            ("scrap", {"Initial": 27, "a": 27, "b": 27, "a+b": 27}, "stages[0].costs.scrap: state key 'Initial'"),
        ],
    )
    def test_wrong_or_missing_state_keys_are_rejected(self, table, keys, message):
        doc = preset("r4")
        doc["stages"][0]["costs"][table] = keys
        with pytest.raises(ValueError) as error:
            load_sequence(doc)
        assert str(error.value).startswith(message)

    def test_a_feature_without_rework_has_no_rework_states(self):
        doc = preset("r4")
        doc["stages"][0]["features"][1]["rework_side"] = "none"
        with pytest.raises(ValueError) as error:
            load_sequence(doc)
        assert str(error.value).startswith("stages[0].costs.rework: unexpected states b, a+b")

    @pytest.mark.parametrize(
        "name, message",
        [
            ("a+b", "stages[0].features[1].name: Feature names are 1 to 16 letters, digits or underscores"),
            ("initial", "stages[0].features[1].name: 'initial' is reserved"),
            ("a", "stages[0]: Feature names must be unique within a Stage"),
        ],
    )
    def test_bad_feature_names_are_rejected(self, name, message):
        doc = preset("r4")
        doc["stages"][0]["features"][1]["name"] = name
        with pytest.raises(ValueError) as error:
            load_sequence(doc)
        assert str(error.value).startswith(message)

    def test_feature_names_must_be_unique_across_stages(self):
        doc = sequence_doc([stage_doc("a", 8.0, 12.0), stage_doc("a", 13.0, 17.0)], [{"a": 10.5}, {"a": 15.6}])
        with pytest.raises(ValueError) as error:
            load_sequence(doc)
        assert str(error.value).startswith("stages: Feature names must be unique across a Sequence's Stages")


class TestCorrelation:
    """A scalar correlation per Stage (C11)."""

    def test_round_trips_and_changes_the_result(self):
        doc = preset("r4")
        doc["stages"][0]["variation"]["corr"] = 0.5
        assert dump_sequence(load_sequence(doc)) == doc
        assert run(doc)["totals"]["expected_profit"] != pytest.approx(run(preset("r4"))["totals"]["expected_profit"])

    def test_out_of_range_is_rejected(self):
        doc = preset("r4")
        doc["stages"][0]["variation"]["corr"] = 1.5
        with pytest.raises(ValueError, match=r"^stages\[0\]\.variation: "):
            load_sequence(doc)


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
            (("stages", 0, "costs", "scrap"), {"initial": 0}, "stages[0].costs.scrap: missing state x"),
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


class TestOptimise:
    """C15, C16: run(action="optimise") replaces the means with the optimum and reports the optimiser record."""

    @pytest.mark.parametrize(
        "objective, mu",
        [
            ("expected_profit", 10.61),  # Table 3.3
            ("production_cost", 10.09),  # Table 3.3, minimum PC + Sr + Rw (U2)
        ],
    )
    def test_r2_recovers_the_printed_optimum(self, objective, mu):
        results = run(preset("r2"), action="optimise", objective=objective)
        assert results["means"]["values"][0]["x"] == pytest.approx(mu, abs=0.005)

    def test_reports_the_optimiser_record_with_the_engine_defaults(self):
        record = run(preset("r2"), action="optimise")["optimisation"]
        assert record["objective"] == "expected_profit"
        assert record["scheme"] == "per_feature"
        assert record["method"] == "L-BFGS-B"
        assert record["bounds"] == {"x": [5.0, 15.0]}  # [L - 3σ, U + 3σ]
        assert (record["n_starts"], record["seed"]) == (8, 0)
        assert record["n_evaluations"] > record["n_starts"]
        assert record["success"] is True

    def test_evaluating_the_optimised_means_gives_the_same_results(self):
        optimised = run(preset("r5"), action="optimise")
        doc = preset("r5")
        doc["means"] = optimised["means"]
        evaluated = run(doc)
        assert evaluated["totals"] == optimised["totals"]
        assert evaluated["stages"] == optimised["stages"]
        assert optimised["totals"]["expected_profit"] >= run(preset("r5"))["totals"]["expected_profit"]
        assert optimised["optimisation"]["objective_value"] == optimised["totals"]["expected_profit"]

    def test_minimising_production_cost_reports_it_as_the_objective_value(self):
        results = run(preset("r2"), action="optimise", objective="production_cost")
        assert results["optimisation"]["objective_value"] == results["totals"]["production_cost"]

    def test_unknown_objective_is_rejected(self):
        with pytest.raises(ValueError, match=r"^objective: must be 'expected_profit' or 'production_cost'"):
            run(preset("r2"), action="optimise", objective="profit")

    def test_unknown_action_is_rejected(self):
        with pytest.raises(ValueError, match=r"^action: "):
            run(preset("r2"), action="search")

    def test_omits_the_reference_check_which_is_for_the_given_means(self):
        assert "reference" in run(preset("r2"))
        assert "reference" not in run(preset("r2"), action="optimise", objective="production_cost")


def with_material(doc, material_value):
    return {**copy.deepcopy(doc), "material_value": material_value}


class TestMaterialValue:
    """C27, C28, ADR 0006: paid for every part started; a Scrap Cost may recover it, but no more."""

    def test_defaults_to_zero_and_leaves_the_presets_unchanged(self):
        totals = run(preset("r5"))["totals"]
        assert totals["material_cost"] == 0.0
        assert run(with_material(preset("r5"), 0)) == run(preset("r5"))

    def test_is_charged_per_part_started(self):
        before, after = run(preset("r5"))["totals"], run(with_material(preset("r5"), 5))["totals"]
        assert after["material_cost"] == 5.0
        assert after["expected_profit"] == pytest.approx(before["expected_profit"] - 5.0, abs=1e-12)
        assert after["production_cost"] == pytest.approx(before["production_cost"] + 5.0, abs=1e-12)

    def test_is_dumped_only_when_not_zero(self):
        assert "material_value" not in dump_sequence(load_sequence(preset("r5")))
        doc = with_material(preset("r5"), 5.0)
        assert dump_sequence(load_sequence(doc)) == doc

    def test_must_be_non_negative(self):
        with pytest.raises(ValueError, match=r"^material_value: must be non-negative"):
            load_sequence(with_material(preset("r5"), -1))

    def test_a_scrap_cost_may_recover_the_material_value(self):
        doc = with_material(preset("r5"), 5)
        doc["stages"][0]["costs"]["scrap"] = {"initial": -5, "a": -5}
        assert run(doc)["stages"][0]["costs"]["scrap"] < 0
        shortcut = with_material(r4_with_costs(R4_SHORTCUT), 5)
        shortcut["stages"][0]["costs"]["scrap_per_feature"] = {"a": -6, "b": 1}  # a scrapped part: -5
        assert run(shortcut)["totals"]["scrap_cost"] < 0

    def test_a_scrap_cost_recovering_more_is_rejected_by_field(self):
        doc = with_material(preset("r5"), 5)
        doc["stages"][1]["costs"]["scrap"]["b"] = -6
        with pytest.raises(ValueError) as error:
            load_sequence(doc)
        assert str(error.value) == "stages[1].costs.scrap.b: must be at least minus the material_value, -5.0, got -6.0"

        shortcut = r4_with_costs(R4_SHORTCUT)
        shortcut["stages"][0]["costs"]["scrap_per_feature"] = {"a": -1, "b": 0}
        with pytest.raises(ValueError) as error:
            load_sequence(shortcut)
        assert str(error.value) == ("stages[0].costs.scrap_per_feature: a scrapped part costs their sum, -1.0, "
                                    "which must be at least minus the material_value, 0.0")
