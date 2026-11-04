// The builder's edits (static/builder.js). Run with: node --test tests/  (test_builder.py runs this too.)

import assert from "node:assert/strict";
import { test } from "node:test";

import { Builder } from "../static/builder.js";

const r4 = () => new Builder({
  format_version: 1, name: "R4", selling_price: 120,
  stages: [{
    features: [{ name: "a", lower: 8, upper: 12, rework_side: "upper" },
               { name: "b", lower: 13, upper: 17, rework_side: "upper" }],
    variation: { type: "normal", sigmas: [1, 1], corr: 0 },
    costs: { processing: 45, rework: { a: 15, b: 12, "a+b": 27 }, scrap: { initial: 27, a: 27, b: 27, "a+b": 27 } },
    inspection: { per_stage: 0, per_feature: 0 },
  }],
  means: { scheme: "per_feature", values: [{ a: 10.537, b: 15.59 }] },
  reference: { source: "Table 3.7", quantity: "expected_profit", value: 71.17, tolerance: 0.005 },
});

test("a preset's Stages show as Operation rows, each Stage closed by an Inspection row", () => {
  const b = new Builder({ ...r4().sequence, stages: [r4().sequence.stages[0], serialStage("c")],
                          means: { scheme: "per_feature", values: [{ a: 10.537, b: 15.59 }, { c: 10 }] } });
  assert.deepEqual(b.rows.map(describe), [
    "a 8–12 μ 10.537", "b 13–17 μ 15.59", "Inspection · Stage 1 · Parallel",
    "c 8–12 μ 10", "Inspection · Stage 2 · Serial",
  ]);
  assert.deepEqual(b.problems, []);
  assert.equal(b.sequence.stages.length, 2);
});

const serialStage = (name) => ({
  features: [{ name, lower: 8, upper: 12, rework_side: "upper" }],
  variation: { type: "normal", sigmas: [1], corr: 0 },
  costs: { processing: 5, rework_per_feature: { [name]: 1 }, scrap_per_feature: { [name]: 2 } },
  inspection: { per_stage: 0, per_feature: 0 },
});

// A row as the list shows it.
const describe = (row) => (row.kind === "operation" ? `${row.name} ${row.lower}–${row.upper} μ ${row.mean}` : row.label);

test("a new Operation takes the next unused name and the C17 defaults", () => {
  const b = Builder.blank();  // f1
  b.addOperation();  // f2
  b.setFeature(0, 0, "name", "g");
  b.addOperation();
  b.addInspection();
  const stage = b.sequence.stages[1];
  assert.deepEqual(stage.features.map((f) => f.name), ["f2", "f1"]);
  assert.deepEqual(stage.features[1], { name: "f1", lower: 8, upper: 12, rework_side: "upper", processing: 1 });
  assert.deepEqual(stage.variation, { type: "normal", sigmas: [1, 1], corr: 0 });
  // Rework Cost half the Processing Cost (C30); the Stage's one Scrap Cost, the extra cost of scrapping, 0 (C28, C29).
  assert.deepEqual(stage.costs, { processing: 2, rework_per_feature: { f2: 0.5, f1: 0.5 }, scrap_per_feature: { f2: 0, f1: 0 } });
  assert.deepEqual(stage.inspection, { per_stage: 0, per_feature: 0 });
  assert.deepEqual(b.sequence.means.values[1], { f2: 10, f1: 10 });
});

test("a new sequence sells at 100, and the Selling Price can't be 0 (C31)", () => {
  const b = Builder.blank();
  assert.equal(b.sequence.selling_price, 100);
  assert.throws(() => b.setSellingPrice(0), /Selling Price must be more than 0/);
  assert.throws(() => b.setSellingPrice(-5), /Selling Price must be more than 0/);
  assert.equal(b.sequence.selling_price, 100);
});

test("a new Operation given a name that is taken gets a numbered one", () => {
  const b = Builder.blank();
  b.addOperation("drill");
  b.addOperation(" drill ");
  b.addOperation("drill");
  b.addOperation("turn");
  assert.deepEqual(b.rows.filter((r) => r.stage === 1).map((r) => r.name), ["drill", "drill2", "drill3", "turn"]);
  assert.throws(() => b.addOperation("a+b"), /letters, digits or underscores/);
  assert.throws(() => b.addOperation("initial"), /reserved/);
  assert.throws(() => b.setFeature(1, 1, "name", "drill"), /already a Feature called drill/);  // renaming: as before
});

test("a new Feature's Mean Setting follows L and U until a mean is typed", () => {
  const b = Builder.blank();
  b.setFeature(0, 0, "upper", 16);
  assert.equal(b.sequence.means.values[0].f1, 12);
  b.setFeature(0, 0, "name", "bore");
  b.setFeature(0, 0, "lower", 10);
  assert.equal(b.sequence.means.values[0].bore, 13);
  b.setMean(0, "bore", 12.5);
  b.setFeature(0, 0, "upper", 20);
  assert.equal(b.sequence.means.values[0].bore, 12.5);
});

test("a preset's Mean Settings stay where they are when L and U change", () => {
  const b = r4();
  b.setFeature(0, 0, "upper", 14);
  assert.equal(b.sequence.means.values[0].a, 10.537);
});

test("every edit makes a new sequence and drops the thesis reference; new means keep it", () => {
  const b = r4();
  const before = b.sequence;
  b.setMeans({ scheme: "per_feature", values: [{ a: 10, b: 15 }] });
  assert.ok(b.sequence.reference);
  b.setSellingPrice(130);
  assert.notEqual(b.sequence, before);
  assert.equal(b.sequence.reference, undefined);
  assert.equal(before.selling_price, 120);
});

test("an additive full table becomes the per-Feature shortcut and back without changing a cost", () => {
  const b = r4();
  assert.ok(b.canUseShortcut(0));
  b.setCostMode(0, "shortcut");
  assert.deepEqual(b.sequence.stages[0].costs,
    { processing: 45, rework_per_feature: { a: 15, b: 12 }, scrap_per_feature: { a: 27, b: 0 } });
  b.setCostMode(0, "full");
  assert.deepEqual(b.sequence.stages[0].costs,
    { processing: 45, rework: { a: 15, b: 12, "a+b": 27 }, scrap: { initial: 27, a: 27, b: 27, "a+b": 27 } });
});

test("a table that is not additive can only be edited in full", () => {
  const b = r4();
  b.setCost(0, "rework", "a+b", 20);
  assert.equal(b.canUseShortcut(0), false);
  assert.throws(() => b.setCostMode(0, "shortcut"), /not additive/);
});

test("an Operation moves up or down within its Stage, with its sigma, but not past the ends of the list", () => {
  const b = r4();
  b.setSigma(0, 1, 0.5);
  b.addOperation();
  assert.deepEqual(b.rows.map((r) => [r.canMoveUp, r.canMoveDown]),
    [[false, true], [true, true], [true, true], [true, false]]);
  b.moveOperation(0, 1, -1);
  const [stage] = b.sequence?.stages ?? [];
  assert.equal(stage, undefined);  // f1 is still after the last Inspection
  b.addInspection();
  const moved = b.sequence.stages[0];
  assert.deepEqual(moved.features.map((f) => f.name), ["b", "a"]);
  assert.deepEqual(moved.variation.sigmas, [0.5, 1]);
  assert.deepEqual(moved.costs.rework, { b: 12, a: 15, "b+a": 27 });
  assert.deepEqual(b.sequence.means.values[0], { b: 15.59, a: 10.537 });
  assert.throws(() => b.moveOperation(0, 0, -1), /first Operation can't move up/);
  b.addOperation();
  assert.throws(() => b.moveOperation(2, 0, +1), /last Operation can't move down/);
});

test("deleting an Operation removes its costs and mean; deleting a Stage's last one leaves its Inspection", () => {
  const b = r4();
  b.deleteOperation(0, 0);
  assert.deepEqual(b.sequence.stages[0].costs.rework, { b: 12 });
  assert.deepEqual(b.sequence.means.values, [{ b: 15.59 }]);
  b.deleteOperation(0, 0);
  assert.deepEqual(b.rows.map(describe), ["Inspection · Stage 1 · no Operations"]);
  assert.equal(b.sequence, null);
  b.addOperation();
  b.deleteOperation(1, 0);  // an unclosed Operation goes without a trace
  assert.equal(b.rows.length, 1);
  b.addOperation();
  b.addInspection();
  assert.equal(b.rows.at(-1).label, "Inspection · Stage 2 · Serial");
});

test("the list's problems: Operations left open, a leading or doubled Inspection, too many of either", () => {
  const messages = (b) => b.problems.map((p) => `${p.row}: ${p.message}`);
  const b = Builder.blank();
  b.deleteOperation(0, 0);
  b.addInspection();
  assert.deepEqual(messages(b), [
    "0: The list starts with an Inspection: Stage 1 has no Operations.",
    "1: Two Inspections in a row: Stage 2 has no Operations.",
  ]);

  const big = Builder.blank();
  for (let k = 0; k < 5; k += 1) big.addOperation();
  big.addInspection();
  assert.deepEqual(messages(big), ["7: Stage 2 has 5 Operations; a Stage can have at most 4."]);
  big.deleteOperation(1, 0);
  for (let k = 0; k < 5; k += 1) { big.addOperation(); big.addInspection(); }
  assert.deepEqual(messages(big), ["16: A Sequence can have at most 6 Inspections."]);
  big.addOperation();
  assert.deepEqual(messages(big).at(-1), "17: Operations after the last Inspection: add an Inspection to close Stage 8.");
  assert.throws(() => big.download(), /Fix the warnings/);
});

test("bad edits are refused with a readable message and change nothing", () => {
  const b = r4();
  const before = b.sequence;
  assert.throws(() => b.setFeature(0, 1, "name", "a"), /already a Feature called a/);
  assert.throws(() => b.setFeature(0, 1, "name", "a+b"), /letters, digits or underscores/);
  assert.throws(() => b.setFeature(0, 1, "name", "initial"), /reserved/);
  assert.throws(() => b.setFeature(0, 0, "lower", ""), /L must be a number/);
  assert.throws(() => b.setCost(0, "scrap", "a", -1), /recover at most the Material Value, 0/);
  assert.throws(() => b.setSigma(0, 0, 0), /positive/);
  assert.throws(() => b.addOperation("x".repeat(17)), /letters, digits or underscores/);
  assert.equal(b.sequence, before);
});

test("preset-only settings stay read-only", () => {
  const seq = r4().sequence;
  seq.stages[0].variation.corr = [[1, 0.5], [0.5, 1]];
  const matrix = new Builder(seq);
  assert.equal(matrix.variationEditable(0), false);
  assert.throws(() => matrix.setCorr(0, 0), /read-only/);
  assert.throws(() => matrix.moveOperation(0, 0, +1), /preset-only/);
  assert.throws(() => matrix.deleteOperation(0, 1), /preset-only/);
  matrix.setCost(0, "scrap", "initial", 30);  // the costs are still the builder's

  const grouped = new Builder({ ...r4().sequence, means: { scheme: "per_group_size", values: [{ 1: 10 }] } });
  assert.equal(grouped.meansEditable, false);
  assert.throws(() => grouped.setMean(0, "a", 10), /per_group_size scheme/);
  assert.throws(() => grouped.addOperation(), /read-only/);
  assert.throws(() => grouped.addInspection(), /read-only/);
  assert.throws(() => grouped.setFeature(0, 0, "rework_side", "none"), /read-only/);  // it changes the Rework States
});

test("an upload that is not a sequence is refused", () => {
  assert.throws(() => Builder.upload("{not json"), /not JSON/);
  assert.throws(() => Builder.upload('{"stages": 3}'), /not a sequence/);
});

test("Add Operation appends an unclosed Operation; Add Inspection closes it into a Stage", () => {
  const b = Builder.blank();
  assert.deepEqual(b.rows.map(describe), ["f1 8–12 μ 10", "Inspection · Stage 1 · Serial"]);
  b.addOperation();
  b.addOperation();
  assert.deepEqual(b.rows.map(describe).slice(2), ["f2 8–12 μ 10", "f3 8–12 μ 10"]);
  assert.deepEqual(b.problems.map((p) => [p.row, p.message]),
    [[2, "Operations after the last Inspection: add an Inspection to close Stage 2."]]);
  assert.equal(b.sequence, null);
  b.addInspection();
  assert.equal(b.rows.at(-1).label, "Inspection · Stage 2 · Parallel");
  assert.deepEqual(b.problems, []);
  const stage = b.sequence.stages[1];
  assert.deepEqual(stage.features.map((f) => f.name), ["f2", "f3"]);
  assert.deepEqual(stage.costs, { processing: 2, rework_per_feature: { f2: 0.5, f3: 0.5 }, scrap_per_feature: { f2: 0, f3: 0 } });
  assert.deepEqual(b.sequence.means.values, [{ f1: 10 }, { f2: 10, f3: 10 }]);
});

test("an Inspection's cost is per Stage plus per Feature inspected", () => {
  const b = r4();
  b.setInspection(0, "per_stage", 1.5);
  b.setInspection(0, "per_feature", "0.25");
  assert.deepEqual(b.sequence.stages[0].inspection, { per_stage: 1.5, per_feature: 0.25 });
  assert.throws(() => b.setInspection(0, "per_feature", -1), /can't be negative/);
  assert.throws(() => b.setInspection(0, "total", 1), /Unknown Inspection Cost/);
});

test("a new Operation's Processing Cost is nominal for its name, and its Stage's is their sum", () => {
  const b = Builder.blank();  // f1
  for (const name of ["turn", "drill", "mill", "bore", "grind", "drill", "deburr"]) b.addOperation(name);
  b.addInspection();
  const [first, second] = b.document.stages;  // too many Operations for a valid Stage, which doesn't matter here
  assert.deepEqual(first.features.map((f) => f.processing), [1]);
  assert.equal(first.costs.processing, 1);
  assert.deepEqual(second.features.map((f) => [f.name, f.processing]),
    [["turn", 3], ["drill", 2], ["mill", 4], ["bore", 3], ["grind", 5], ["drill2", 2], ["deburr", 1]]);
  assert.equal(second.costs.processing, 20);
});

test("an Operation's Processing Cost follows its name until a cost is typed", () => {
  const b = Builder.blank();
  b.setFeature(0, 0, "name", "grind");
  assert.equal(b.sequence.stages[0].features[0].processing, 5);
  assert.ok(b.isAutoProcessing("grind"));
  b.setFeature(0, 0, "processing", "6.5");
  assert.equal(b.isAutoProcessing("grind"), false);
  b.setFeature(0, 0, "name", "turn");
  assert.equal(b.sequence.stages[0].features[0].processing, 6.5);
  assert.equal(b.sequence.stages[0].costs.processing, 6.5);
  assert.throws(() => b.setFeature(0, 0, "processing", -1), /Processing Cost can't be negative/);
});

test("deleting an Operation takes its Processing Cost out of its Stage's", () => {
  const b = Builder.blank();
  b.addOperation("mill");
  b.addOperation("grind");
  b.addInspection();
  b.deleteOperation(1, 0);
  assert.equal(b.sequence.stages[1].costs.processing, 5);
});

test("a preset's Stage Processing Cost is split evenly across its Operations, with a note", () => {
  const b = r4();
  assert.deepEqual(b.sequence.stages[0].features.map((f) => f.processing), [22.5, 22.5]);
  assert.equal(b.sequence.stages[0].costs.processing, 45);
  assert.ok(b.sequence.reference);  // loading is not an edit
  assert.equal(b.processingNote(0), "split evenly from the preset's Stage total");
  assert.equal(b.isAutoProcessing("a"), false);
  b.setFeature(0, 0, "name", "turn");  // a preset's cost doesn't follow the name
  assert.equal(b.sequence.stages[0].features[0].processing, 22.5);
  b.setFeature(0, 1, "processing", 20);
  assert.equal(b.sequence.stages[0].costs.processing, 42.5);
  assert.equal(b.processingNote(0), null);
});

test("a sequence whose Operations carry Processing Costs loads them as they are", () => {
  const seq = r4().sequence;
  seq.stages[0].features[0].processing = 30;
  seq.stages[0].features[1].processing = 15;
  delete seq.stages[0].costs.processing;  // optional when the Operations carry them (C22)
  const b = new Builder(seq);
  assert.deepEqual(b.sequence.stages[0].features.map((f) => f.processing), [30, 15]);
  assert.equal(b.sequence.stages[0].costs.processing, 45);
  assert.equal(b.processingNote(0), null);
});

// R4's Parallel Stage (full table) then a Serial Stage c (shortcut).
const twoStages = () => new Builder({ ...r4().sequence, stages: [r4().sequence.stages[0], serialStage("c")],
                                      means: { scheme: "per_feature", values: [{ a: 10.537, b: 15.59 }, { c: 10 }] } });

test("an Operation moved down past an Inspection starts the next Stage, its costs leaving the old one", () => {
  const b = twoStages();
  b.moveOperation(0, 1, +1);  // b
  assert.deepEqual(b.rows.map(describe), [
    "a 8–12 μ 10.537", "Inspection · Stage 1 · Serial",
    "b 13–17 μ 15.59", "c 8–12 μ 10", "Inspection · Stage 2 · Parallel",
  ]);
  const [first, second] = b.sequence.stages;
  assert.deepEqual(first.costs, { processing: 22.5, rework: { a: 15 }, scrap: { initial: 27, a: 27 } });
  assert.deepEqual(first.variation.sigmas, [1]);
  assert.deepEqual(second.features.map((f) => [f.name, f.processing]), [["b", 22.5], ["c", 5]]);
  assert.deepEqual(second.variation.sigmas, [1, 1]);
  // b takes its Rework Cost (C30); the Stage keeps its Scrap Cost, now on its first Feature (C29).
  assert.deepEqual(second.costs, { processing: 27.5, rework_per_feature: { b: 12, c: 1 }, scrap_per_feature: { b: 2, c: 0 } });
  assert.deepEqual(b.sequence.means.values, [{ a: 10.537 }, { b: 15.59, c: 10 }]);
  assert.equal(b.sequence.reference, undefined);
});

test("an Operation moved up into a full table adds its Rework States at the sum of their Features' Rework Costs", () => {
  const b = twoStages();
  b.setCost(0, "scrap", "initial", 30);
  b.moveOperation(1, 0, -1);  // c
  assert.deepEqual(b.rows.map(describe).slice(0, 4),
    ["a 8–12 μ 10.537", "b 13–17 μ 15.59", "c 8–12 μ 10", "Inspection · Stage 1 · Parallel"]);
  const { costs } = b.document.stages[0];
  assert.deepEqual(costs.rework, { a: 15, b: 12, c: 1, "a+b": 27, "a+c": 16, "b+c": 13, "a+b+c": 28 });  // c's own (C30)
  assert.deepEqual(costs.scrap,
    { initial: 30, a: 27, b: 27, c: 30, "a+b": 27, "a+c": 30, "b+c": 30, "a+b+c": 30 });
  assert.equal(costs.processing, 50);
  assert.deepEqual(b.document.stages[1].costs, { processing: 0, rework_per_feature: {}, scrap_per_feature: {} });
  assert.deepEqual(b.problems.map((p) => p.message), ["Two Inspections in a row: Stage 2 has no Operations."]);
});

test("an Operation moved down past the last Inspection is left unclosed; moved back up, the list closes again", () => {
  const b = twoStages();
  b.moveOperation(1, 0, +1);
  assert.deepEqual(b.rows.map(describe).slice(2),
    ["Inspection · Stage 1 · Parallel", "Inspection · Stage 2 · no Operations", "c 8–12 μ 10"]);
  assert.deepEqual(b.problems.map((p) => p.row), [3, 4]);
  b.moveOperation(2, 0, -1);
  assert.deepEqual(b.problems, []);
  assert.deepEqual(b.sequence.stages[1].costs, { processing: 5, rework_per_feature: { c: 1 }, scrap_per_feature: { c: 0 } });
  assert.equal(b.sequence.stages.length, 2);
});

test("moving an Operation between Stages moves its Processing Cost", () => {
  const b = twoStages();
  b.addOperation("drill");
  b.addInspection();  // Stage 3
  b.moveOperation(1, 0, -1);  // c, 5, from Stage 2 to Stage 1
  assert.deepEqual(b.document.stages.map((s) => s.costs.processing), [50, 0, 2]);
});

test("an Inspection moved up or down regroups the Operations around it", () => {
  const b = twoStages();
  b.moveInspection(0, -1);  // past b
  assert.deepEqual(b.rows.map(describe), [
    "a 8–12 μ 10.537", "Inspection · Stage 1 · Serial",
    "b 13–17 μ 15.59", "c 8–12 μ 10", "Inspection · Stage 2 · Parallel",
  ]);
  b.moveInspection(0, +1);  // back past b
  b.moveInspection(0, +1);  // and past c
  assert.deepEqual(b.rows.map(describe), [
    "a 8–12 μ 10.537", "b 13–17 μ 15.59", "c 8–12 μ 10", "Inspection · Stage 1 · Parallel",
    "Inspection · Stage 2 · no Operations",
  ]);
  b.moveInspection(0, -1);  // c out of Stage 1 into Stage 2
  assert.deepEqual(b.problems, []);
  assert.deepEqual(b.sequence.means.values, [{ a: 10.537, b: 15.59 }, { c: 10 }]);
  assert.throws(() => b.moveInspection(1, +1), /nothing after/);

  const empty = Builder.blank();
  empty.addInspection();
  assert.throws(() => empty.moveInspection(1, -1), /no Operations/);
  b.addOperation();
  assert.throws(() => b.moveInspection(2, -1), /Stage 3 has no Inspection/);
  assert.throws(() => b.deleteInspection(2), /Stage 3 has no Inspection/);
});

test("moving the last Inspection up leaves the Operation after it unclosed; down closes it again", () => {
  const b = twoStages();
  b.moveInspection(1, -1);
  assert.deepEqual(b.rows.map(describe).slice(2),
    ["Inspection · Stage 1 · Parallel", "Inspection · Stage 2 · no Operations", "c 8–12 μ 10"]);
  b.moveInspection(1, +1);
  assert.deepEqual(b.problems, []);
  assert.equal(b.rows.at(-1).label, "Inspection · Stage 2 · Serial");
});

test("deleting an Inspection merges its Operations into the next Stage, which keeps its own costs", () => {
  const b = twoStages();
  b.setInspection(1, "per_stage", 0.5);
  b.deleteInspection(0);
  assert.deepEqual(b.rows.map(describe),
    ["a 8–12 μ 10.537", "b 13–17 μ 15.59", "c 8–12 μ 10", "Inspection · Stage 1 · Parallel"]);
  const [stage] = b.sequence.stages;
  // a and b take their Rework Costs with them (C30); the Stage keeps its own Scrap Cost, on its first Feature (C29).
  assert.deepEqual(stage.costs,
    { processing: 50, rework_per_feature: { a: 15, b: 12, c: 1 }, scrap_per_feature: { a: 2, b: 0, c: 0 } });
  assert.deepEqual(stage.variation, { type: "normal", sigmas: [1, 1, 1], corr: 0 });
  assert.deepEqual(stage.inspection, { per_stage: 0.5, per_feature: 0 });
  assert.deepEqual(b.sequence.means.values, [{ a: 10.537, b: 15.59, c: 10 }]);
});

test("deleting an Inspection is refused if the merged Stage would have more than 4 Operations", () => {
  const b = twoStages();
  b.addOperation();
  b.addOperation();
  b.addInspection();  // Stage 3: f1 f2
  b.moveInspection(0, -1);  // b into Stage 2: b c
  b.addOperation();
  b.moveOperation(3, 0, -1);  // f3 into Stage 3: f1 f2 f3
  const before = b.document;
  assert.throws(() => b.deleteInspection(1), /Stage 2 would have 5 Operations; a Stage can have at most 4/);
  assert.equal(b.document, before);
  b.deleteInspection(0);  // a b c
  assert.deepEqual(b.problems, []);
});

test("deleting the last Inspection leaves its Operations unclosed; an empty Stage's just goes", () => {
  const b = twoStages();
  b.deleteInspection(1);
  assert.deepEqual(b.rows.map(describe).slice(2), ["Inspection · Stage 1 · Parallel", "c 8–12 μ 10"]);
  b.addInspection();
  assert.deepEqual(b.sequence.stages[1].costs, serialStage("c").costs);  // closed again, as it was

  const empty = Builder.blank();
  empty.addInspection();
  empty.deleteInspection(1);
  assert.deepEqual(empty.rows.map(describe), ["f1 8–12 μ 10", "Inspection · Stage 1 · Serial"]);
  assert.deepEqual(empty.problems, []);
});

// Each row as name or "insp", then 1 or 0 for up and down, then an Inspection's canDelete.
const flags = (b) => b.rows.map((r) => `${r.name ?? "insp"} ${+r.canMoveUp}${+r.canMoveDown}${r.canDelete ?? ""}`);

test("rows say which moves and deletes are open, the ends of the list aside", () => {
  const b = twoStages();
  assert.deepEqual(flags(b), ["a 01", "b 11", "insp 11true", "c 11", "insp 10true"]);
  b.addOperation();
  assert.deepEqual(flags(b).slice(-2), ["insp 11true", "f1 10"]);
  b.deleteOperation(1, 0);
  assert.deepEqual(flags(b).slice(2), ["insp 10true", "insp 01true", "f1 10"]);  // nothing between the two Inspections
});

test("a Stage with preset-only variation locks its Operations and Inspection, and moves into it", () => {
  const seq = twoStages().sequence;
  seq.stages[0].variation.corr = [[1, 0.5], [0.5, 1]];
  const b = new Builder(seq);
  assert.deepEqual(flags(b), ["a 00", "b 00", "insp 00false", "c 01", "insp 10true"]);
  assert.throws(() => b.moveOperation(0, 1, +1), /preset-only/);
  assert.throws(() => b.moveOperation(1, 0, -1), /preset-only/);
  assert.throws(() => b.moveInspection(0, -1), /preset-only/);
  assert.throws(() => b.moveInspection(0, +1), /preset-only/);
  assert.throws(() => b.deleteInspection(0), /preset-only/);
  b.deleteInspection(1);  // Stage 2 isn't locked

  const grouped = new Builder({ ...twoStages().sequence,
    means: { scheme: "per_group_size", values: [{ 1: 10, 2: 10 }, { 1: 10 }] } });
  assert.ok(grouped.rows.every((r) => !r.canMoveUp && !r.canMoveDown && !r.canDelete));
  assert.throws(() => grouped.moveOperation(1, 0, -1), /read-only/);
  assert.throws(() => grouped.moveInspection(0, -1), /read-only/);
  assert.throws(() => grouped.deleteInspection(0), /read-only/);
});

test("rows say how the sequence chain draws them: each Stage's shape and which Operations are unclosed", () => {
  const b = r4();
  b.addInspection();
  b.addOperation("drill");
  assert.deepEqual(b.rows.map((r) => (r.kind === "operation" ? `${r.name} ${r.closed}` : `${r.stage} ${r.shape}`)),
    ["a true", "b true", "0 Parallel", "1 no Operations", "drill false"]);
  b.addInspection();
  assert.deepEqual(b.rows.filter((r) => r.kind === "inspection").map((r) => r.shape), ["Parallel", "no Operations", "Serial"]);
});

test("a new Operation's Rework Cost is half its Processing Cost, following it until a Rework Cost is typed", () => {
  const b = Builder.blank();  // f1, Processing Cost 1
  const rework = (i) => b.document.stages[i].costs.rework_per_feature;
  assert.deepEqual(rework(0), { f1: 0.5 });
  assert.ok(b.isAutoRework(0, "f1"));
  b.setFeature(0, 0, "name", "grind");  // Processing Cost 5
  assert.deepEqual(rework(0), { grind: 2.5 });
  b.setFeature(0, 0, "processing", 6);
  assert.deepEqual(rework(0), { grind: 3 });
  b.setCost(0, "rework", "grind", 4);
  assert.equal(b.isAutoRework(0, "grind"), false);
  b.setFeature(0, 0, "processing", 8);
  assert.deepEqual(rework(0), { grind: 4 });

  b.addOperation("drill");
  b.addOperation("bore");
  b.addInspection();  // a Parallel Stage: each Feature's own, summed for a part needing both
  assert.deepEqual(rework(1), { drill: 1, bore: 1.5 });
  b.setFeature(1, 1, "rework_side", "none");
  assert.deepEqual(rework(1), { drill: 1 });
  b.setFeature(1, 1, "rework_side", "upper");  // still following its Processing Cost
  assert.deepEqual(rework(1), { drill: 1, bore: 1.5 });
});

test("a preset's Rework Costs are kept; a full table stops following", () => {
  assert.equal(r4().isAutoRework(0, "a"), false);
  const b = Builder.blank();
  b.setCostMode(0, "full");
  assert.deepEqual(b.document.stages[0].costs.rework, { f1: 0.5 });
  assert.equal(b.isAutoRework(0, "f1"), false);
  b.setFeature(0, 0, "processing", 4);
  assert.deepEqual(b.document.stages[0].costs.rework, { f1: 0.5 });
});

test("an Operation moved to another Stage takes its Rework Cost, nominal or typed", () => {
  const b = Builder.blank();  // f1
  b.addOperation("drill");
  b.addInspection();
  b.setCost(1, "rework", "drill", 4);
  b.moveOperation(1, 0, -1);
  assert.deepEqual(b.document.stages[0].costs.rework_per_feature, { f1: 0.5, drill: 4 });
  b.moveOperation(0, 0, +1);  // f1 below drill
  b.moveOperation(0, 1, +1);  // and into Stage 2, still nominal
  assert.deepEqual(b.document.stages[1].costs.rework_per_feature, { f1: 0.5 });
  b.setFeature(1, 0, "processing", 3);
  assert.deepEqual(b.document.stages[1].costs.rework_per_feature, { f1: 1.5 });
});

test("the cost shortcut has one Scrap Cost per Stage, nominally 0, which stays with the Stage", () => {
  const b = Builder.blank();  // f1
  b.addOperation("drill");
  b.addOperation("bore");
  b.addInspection();
  assert.deepEqual([b.stageScrap(0), b.stageScrap(1)], [0, 0]);
  b.setStageScrap(0, 2);
  b.setStageScrap(1, "3");
  assert.deepEqual(b.document.stages[1].costs.scrap_per_feature, { drill: 3, bore: 0 });  // on the first Feature
  b.moveOperation(1, 0, -1);  // drill into Stage 1
  assert.deepEqual(b.document.stages.map((s) => s.costs.scrap_per_feature), [{ f1: 2, drill: 0 }, { bore: 3 }]);
  b.moveOperation(0, 0, +1);  // f1 down within Stage 1: drill is now first
  assert.deepEqual(b.document.stages[0].costs.scrap_per_feature, { drill: 2, f1: 0 });
  assert.equal(b.stageScrap(0), 2);
  assert.throws(() => b.setStageScrap(0, ""), /Scrap Cost must be a number/);
  // A preset's per-Feature Scrap Costs show as their sum: what a scrapped part costs.
  const shortcut = new Builder({ ...r4().sequence,
    stages: [{ ...r4().sequence.stages[0], costs: { processing: 45, rework_per_feature: { a: 15, b: 12 },
                                                    scrap_per_feature: { a: 10, b: 17 } } }] });
  assert.equal(shortcut.stageScrap(0), 27);
});

test("a Material Value is paid for every part, and a Scrap Cost may recover it but no more", () => {
  const b = Builder.blank();
  assert.equal(b.materialValue, 0);
  b.setMaterialValue("5");
  assert.equal(b.sequence.material_value, 5);
  assert.throws(() => b.setMaterialValue(-1), /Material Value can't be negative/);
  b.setStageScrap(0, -5);
  assert.throws(() => b.setStageScrap(0, -5.5), /Scrap Cost can recover at most the Material Value, 5/);
  b.setCostMode(0, "full");
  b.setCost(0, "scrap", "f1", -4);
  assert.throws(() => b.setCost(0, "scrap", "initial", -6), /at most the Material Value/);
  assert.throws(() => b.setCost(0, "rework", "f1", -1), /Rework Cost can't be negative/);
  b.setMaterialValue(2);  // now Stage 1's Scrap Costs recover more than the material
  assert.deepEqual(b.problems, [{ row: 1, message: "Stage 1's Scrap Cost recovers more than the Material Value, 2." }]);
  assert.equal(b.sequence, null);
});

test("a scrapped part has already lost its Material Value and the Processing Costs to date", () => {
  const b = Builder.blank();  // f1: 1
  b.setMaterialValue(5);
  b.addOperation("drill");
  b.addOperation("bore");
  b.addInspection();
  assert.deepEqual(b.lostOnScrap(0), { material: 5, processing: [1], total: 6 });
  assert.deepEqual(b.lostOnScrap(1), { material: 5, processing: [1, 5], total: 11 });
  assert.deepEqual(r4().lostOnScrap(0), { material: 0, processing: [45], total: 45 });
});

test("an Operation joining a full table stops following, as switching to one does", () => {
  const b = Builder.blank();  // f1
  b.setCostMode(0, "full");
  b.addOperation("drill");
  b.addInspection();
  b.moveOperation(1, 0, -1);  // drill, nominal, into Stage 1's full table
  assert.deepEqual(b.document.stages[0].costs.rework, { f1: 0.5, drill: 1, "f1+drill": 1.5 });
  b.setCostMode(0, "shortcut");
  assert.equal(b.isAutoRework(0, "drill"), false);
  b.setFeature(0, 1, "processing", 6);
  assert.equal(b.document.stages[0].costs.rework_per_feature.drill, 1);
});

test("a Stage with no Operations has no Scrap Cost to set", () => {
  const b = Builder.blank();
  b.deleteOperation(0, 0);
  assert.throws(() => b.setStageScrap(0, 2), /Stage 1 has no Operations/);
});
