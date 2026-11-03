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
  assert.deepEqual(stage.costs, { processing: 2, rework_per_feature: { f2: 0, f1: 0 }, scrap_per_feature: { f2: 0, f1: 0 } });
  assert.deepEqual(stage.inspection, { per_stage: 0, per_feature: 0 });
  assert.deepEqual(b.sequence.means.values[1], { f2: 10, f1: 10 });
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

test("an Operation moves up or down within its Stage, with its sigma, but not past an Inspection", () => {
  const b = r4();
  b.setSigma(0, 1, 0.5);
  b.addOperation();
  assert.deepEqual(b.rows.map((r) => [r.canMoveUp, r.canMoveDown]),
    [[false, true], [true, false], [undefined, undefined], [false, false]]);
  b.moveOperation(0, 1, -1);
  const [stage] = b.sequence?.stages ?? [];
  assert.equal(stage, undefined);  // f1 is still after the last Inspection
  b.addInspection();
  const moved = b.sequence.stages[0];
  assert.deepEqual(moved.features.map((f) => f.name), ["b", "a"]);
  assert.deepEqual(moved.variation.sigmas, [0.5, 1]);
  assert.deepEqual(moved.costs.rework, { b: 12, a: 15, "b+a": 27 });
  assert.deepEqual(b.sequence.means.values[0], { b: 15.59, a: 10.537 });
  assert.throws(() => b.moveOperation(0, 1, +1), /past an Inspection/);
  assert.throws(() => b.moveOperation(1, 0, -1), /past an Inspection/);
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
  assert.throws(() => b.setCost(0, "scrap", "a", -1), /can't be negative/);
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
  assert.deepEqual(stage.costs, { processing: 2, rework_per_feature: { f2: 0, f3: 0 }, scrap_per_feature: { f2: 0, f3: 0 } });
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

test("a change to earlier Stages' Processing Costs flags a Stage's Scrap Costs for checking, never changes them", () => {
  const two = () => new Builder({ ...r4().sequence, stages: [r4().sequence.stages[0], serialStage("c")],
                                  means: { scheme: "per_feature", values: [{ a: 10.537, b: 15.59 }, { c: 10 }] } });
  const b = two();
  assert.deepEqual([b.scrapNeedsCheck(0), b.scrapNeedsCheck(1)], [false, false]);
  b.setFeature(1, 0, "processing", 9);  // the last Stage's own cost: nothing after it
  b.setCost(1, "rework", "c", 4);
  assert.equal(b.scrapNeedsCheck(1), false);
  b.setFeature(0, 0, "processing", 30);
  assert.deepEqual([b.scrapNeedsCheck(0), b.scrapNeedsCheck(1)], [false, true]);
  assert.deepEqual(b.sequence.stages[1].costs.scrap_per_feature, { c: 2 });
  b.setCost(1, "rework", "c", 5);  // not a Scrap Cost
  assert.equal(b.scrapNeedsCheck(1), true);
  b.setCost(1, "scrap", "c", 2);  // checked, even if left as it was
  assert.equal(b.scrapNeedsCheck(1), false);

  const deleted = two();
  deleted.addOperation("drill");
  deleted.addInspection();
  deleted.deleteOperation(0, 0);
  assert.deepEqual([1, 2].map((i) => deleted.scrapNeedsCheck(i)), [true, true]);
});

test("a Stage removed with its last unclosed Operation leaves no check marker for the next one", () => {
  const b = Builder.blank();
  b.addOperation();  // Stage 2, unclosed
  b.setFeature(0, 0, "processing", 4);
  assert.equal(b.scrapNeedsCheck(1), true);
  b.deleteOperation(1, 0);
  b.addOperation();
  b.addInspection();
  assert.equal(b.scrapNeedsCheck(1), false);
});
