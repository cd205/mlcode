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

test("a new Feature takes the next unused name and the C17 defaults", () => {
  const b = Builder.blank();  // Stage 1: f1
  b.addStage();  // Stage 2: f2
  b.setFeature(0, 0, "name", "g");
  b.addFeature(1);
  const stage = b.sequence.stages[1];
  assert.deepEqual(stage.features.map((f) => f.name), ["f2", "f1"]);
  assert.deepEqual(stage.features[1], { name: "f1", lower: 8, upper: 12, rework_side: "upper" });
  assert.deepEqual(stage.variation, { type: "normal", sigmas: [1, 1], corr: 0 });
  assert.deepEqual(stage.costs, { processing: 0, rework_per_feature: { f2: 0, f1: 0 }, scrap_per_feature: { f2: 0, f1: 0 } });
  assert.deepEqual(b.sequence.means.values[1], { f2: 10, f1: 10 });
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

test("a Feature moved past the end of its Stage goes into the next one, with its mean and costs", () => {
  const b = r4();
  b.addStage();  // Stage 2: f1
  b.moveFeature(0, 1, +1);
  const [first, second] = b.sequence.stages;
  assert.deepEqual(first.features.map((f) => f.name), ["a"]);
  assert.deepEqual(first.costs.rework, { a: 15 });
  assert.deepEqual(second.features.map((f) => f.name), ["b", "f1"]);
  assert.deepEqual(second.costs.rework_per_feature, { b: 12, f1: 0 });
  assert.deepEqual(b.sequence.means.values, [{ a: 10.537 }, { b: 15.59, f1: 10 }]);
  assert.throws(() => b.moveFeature(0, 0, +1), /at least one Feature/);
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
  assert.throws(() => b.deleteStage(0), /at least one Stage/);
  b.deleteFeature(0, 0);
  assert.throws(() => b.deleteFeature(0, 0), /at least one Feature/);
  assert.equal(before.stages[0].features.length, 2);
});

test("preset-only settings stay read-only", () => {
  const seq = r4().sequence;
  seq.stages[0].variation.corr = [[1, 0.5], [0.5, 1]];
  const matrix = new Builder(seq);
  assert.equal(matrix.variationEditable(0), false);
  assert.throws(() => matrix.setCorr(0, 0), /read-only/);
  assert.throws(() => matrix.addFeature(0), /preset-only/);
  matrix.setCost(0, "scrap", "initial", 30);  // the costs are still the builder's

  const grouped = new Builder({ ...r4().sequence, means: { scheme: "per_group_size", values: [{ 1: 10 }] } });
  assert.equal(grouped.meansEditable, false);
  assert.throws(() => grouped.setMean(0, "a", 10), /per_group_size scheme/);
  assert.throws(() => grouped.addStage(), /read-only/);
  assert.throws(() => grouped.setFeature(0, 0, "rework_side", "none"), /read-only/);  // it changes the Rework States
});

test("an upload that is not a sequence is refused", () => {
  assert.throws(() => Builder.upload("{not json"), /not JSON/);
  assert.throws(() => Builder.upload('{"stages": 3}'), /not a sequence/);
});
