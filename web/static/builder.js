// The builder's edits to a Sequence list (web_app_plan.md §4, §7, §7.1). No DOM here: the page calls these and
// redraws; the tests drive them through node. Every edit bumps `revision`, so the page can tell that the list
// changed while a request was in flight.
//
// The list is held as the sequence file's Stages (C19): each Stage's Operations, then its Inspection. It may be
// invalid while it is being built (C21): the last Stage may be open (Operations after the last Inspection) and a
// Stage may be empty (an Inspection with no Operations before it). `problems` says what is wrong, and `sequence`
// is only handed out when nothing is.

const FEATURE_NAME = /^[A-Za-z0-9_]{1,16}$/;
const INITIAL = "initial";
export const DEFAULT_FEATURE = { lower: 8, upper: 12, rework_side: "upper", sigma: 1 };  // C17
export const REWORK_SIDES = ["upper", "lower", "none"];
export const OPERATION_NAMES = ["turn", "drill", "mill", "bore", "grind"];  // C20
// A new Operation's Processing Cost by name, numbered names too (drill2); any other name costs 1 (C23).
const NOMINAL_PROCESSING = { turn: 3, drill: 2, mill: 4, bore: 3, grind: 5 };
const MAX_OPERATIONS = 4;  // per Stage (C21, §6)
const MAX_INSPECTIONS = 6;

export class Builder {
  #doc;  // the sequence file's fields, with the Stages as above
  #open = false;  // the last Stage has no Inspection yet
  #revision = 0;
  #autoMeans = new Set();  // names of Features whose Mean Setting still follows L and U (C17)
  #autoProcessing = new Set();  // names of Operations whose Processing Cost still follows their name (C23)
  #splitStages = new Set();  // indices of Stages whose Processing Cost was split evenly on loading (C24)
  #checkScrap = new Set();  // indices of Stages whose Scrap Costs to check: earlier Processing Costs changed (C25)

  // A Stage whose Operations carry no Processing Costs (a preset) has its total split evenly across them, which
  // keeps the total, and so every result, unchanged (C24).
  constructor(sequence) {
    this.#doc = structuredClone(sequence);
    this.#doc.stages.forEach((stage, i) => {
      const { features, costs } = stage;
      if (!features.length) return;
      if (features.every((f) => f.processing === undefined)) {
        for (const f of features) f.processing = costs.processing / features.length;
        this.#splitStages.add(i);
      } else if (costs.processing === undefined) {
        syncProcessing(stage);
      }
    });
  }

  // One Operation and its Inspection; Selling Price and costs 0.
  static blank() {
    const b = new Builder({ format_version: 1, name: "New sequence", selling_price: 0, stages: [],
                            means: { scheme: "per_feature", values: [] } });
    b.addOperation();
    b.addInspection();
    return b;
  }

  // The sequence file the page downloads, and a Builder over an uploaded one. The server checks the rest.
  download() {
    const { sequence } = this;
    if (!sequence) throw new Error("Fix the warnings in the Sequence list first.");
    return `${JSON.stringify(sequence, null, 2)}\n`;
  }

  static upload(text) {
    let doc;
    try {
      doc = JSON.parse(text);
    } catch {
      throw new Error("That file is not JSON.");
    }
    if (!doc || typeof doc !== "object" || !Array.isArray(doc.stages) || typeof doc.means !== "object") {
      throw new Error("That file is not a sequence: it needs stages and means.");
    }
    return new Builder(doc);
  }

  // The sequence to Evaluate, Optimise or download, or null while the list has problems (C21).
  get sequence() { return this.problems.length ? null : this.#doc; }

  // The list's fields as they stand, valid or not, for the page to show. Read-only: edit through the methods.
  get document() { return this.#doc; }

  get revision() { return this.#revision; }

  // The Sequence list (C19): each Stage's Operations, then the Inspection that closes it. An Operation can move up
  // or down only within its Stage.
  get rows() {
    const { stages, means } = this.#doc;
    return stages.flatMap((stage, i) => {
      const n = stage.features.length;
      const operations = stage.features.map((f, j) => ({
        kind: "operation", stage: i, index: j, name: f.name, lower: f.lower, upper: f.upper,
        mean: means.values[i]?.[f.name], canMoveUp: j > 0, canMoveDown: j < n - 1,
      }));
      if (this.#isOpen(i)) return operations;
      const shape = n === 0 ? "no Operations" : n === 1 ? "Serial" : "Parallel";
      return [...operations, { kind: "inspection", stage: i, label: `Inspection · Stage ${i + 1} · ${shape}` }];
    });
  }

  // What makes the list not a valid Sequence (C21), each with the row its warning shows by.
  get problems() {
    const problems = [];
    let row = 0;
    this.#doc.stages.forEach((stage, i) => {
      const n = stage.features.length;
      if (this.#isOpen(i)) {
        problems.push({ row, message: `Operations after the last Inspection: add an Inspection to close Stage ${i + 1}.` });
        return;
      }
      row += n;  // the Inspection's row
      if (n === 0) {
        problems.push({ row, message: i === 0
          ? "The list starts with an Inspection: Stage 1 has no Operations."
          : `Two Inspections in a row: Stage ${i + 1} has no Operations.` });
      } else if (n > MAX_OPERATIONS) {
        problems.push({ row, message: `Stage ${i + 1} has ${n} Operations; a Stage can have at most ${MAX_OPERATIONS}.` });
      }
      if (i === MAX_INSPECTIONS) {
        problems.push({ row, message: `A Sequence can have at most ${MAX_INSPECTIONS} Inspections.` });
      }
      row += 1;
    });
    if (row === 0 && !this.#open) problems.push({ row: 0, message: "The list is empty: add an Operation." });
    return problems;
  }

  // Preset-only settings are shown read-only (C10, C11): Mean Settings in another scheme, and a correlation matrix
  // or copula. While either applies, the Features they describe can't be added, removed or moved (C10, C11).
  get meansEditable() { return this.#doc.means.scheme === "per_feature"; }

  variationEditable(i) {
    const v = this.#doc.stages[i].variation;
    return v.type === "normal" && !Array.isArray(v.corr);
  }

  isAutoMean(name) { return this.#autoMeans.has(name); }

  isAutoProcessing(name) { return this.#autoProcessing.has(name); }

  // The note on Stage i's Processing Cost while it is still the preset's total split evenly (C24), else null.
  processingNote(i) { return this.#splitStages.has(i) ? "split evenly from the preset's Stage total" : null; }

  // The earlier Stages' Processing Costs: the hint beside a cumulative Scrap Cost (C9).
  earlierProcessing(i) { return this.#doc.stages.slice(0, i).map((s) => s.costs.processing); }

  // True from when the earlier Stages' Processing Costs change until one of Stage i's Scrap Costs is edited (C25).
  scrapNeedsCheck(i) { return this.#checkScrap.has(i); }

  // A full table can become the per-Feature shortcut only when it is additive, so nothing is lost (C8).
  canUseShortcut(i) {
    const { costs } = this.#doc.stages[i];
    return "rework_per_feature" in costs || isAdditive(costs);
  }

  // After Optimise or Undo (C16): new values, not an edit, so the reference stays.
  setMeans(means) {
    this.#doc = { ...this.#doc, means: structuredClone(means) };
    this.#revision += 1;
    this.#autoMeans.clear();
  }

  setName(name) { this.#edit((seq) => { seq.name = String(name); }); }

  setSellingPrice(value) { this.#edit((seq) => { seq.selling_price = cost(value, "Selling Price"); }); }

  setFeature(i, j, field, value) {
    if (field === "name") return this.#rename(i, j, value);
    this.#edit((seq) => {
      const f = seq.stages[i].features[j];
      if (field === "rework_side") {
        this.#requireMeans();  // it changes the Stage's Rework States, which other schemes may key on
        if (!REWORK_SIDES.includes(value)) throw new Error(`Rework Side must be one of ${REWORK_SIDES.join(", ")}.`);
        f.rework_side = value;
        syncCosts(seq.stages[i]);
        return;
      }
      if (field === "processing") {
        f.processing = cost(value, "Processing Cost");
        this.#autoProcessing.delete(f.name);
        this.#splitStages.delete(i);
        syncProcessing(seq.stages[i]);
        return;
      }
      if (field !== "lower" && field !== "upper") throw new Error(`Unknown Feature field ${field}.`);
      f[field] = number(value, field === "lower" ? "L" : "U");
      if (this.#autoMeans.has(f.name)) seq.means.values[i][f.name] = midpoint(f);
    });
  }

  setMean(i, name, value) {
    this.#requireMeans();
    this.#edit((seq) => {
      seq.means.values[i][name] = number(value, "Mean Setting");
      this.#autoMeans.delete(name);
    });
  }

  setSigma(i, j, value) {
    this.#requireVariation(i);
    this.#edit((seq) => {
      const sigma = number(value, "σ");
      if (sigma <= 0) throw new Error("σ must be positive.");
      seq.stages[i].variation.sigmas[j] = sigma;
    });
  }

  setCorr(i, value) {
    this.#requireVariation(i);
    this.#edit((seq) => { seq.stages[i].variation.corr = number(value, "Correlation"); });
  }

  // `field` is per_stage or per_feature: an inspected part costs per_stage + per_feature × its Stage's Features.
  setInspection(i, field, value) {
    if (field !== "per_stage" && field !== "per_feature") throw new Error(`Unknown Inspection Cost ${field}.`);
    this.#edit((seq) => {
      seq.stages[i].inspection = { per_stage: 0, per_feature: 0, ...seq.stages[i].inspection,
                                   [field]: cost(value, "Inspection Cost") };
    });
  }

  // `kind` is rework or scrap; `key` is a state key (full table) or a Feature name (per-Feature shortcut).
  setCost(i, kind, key, value) {
    this.#edit((seq) => {
      const { costs } = seq.stages[i];
      const table = costs[`${kind}_per_feature`] ?? costs[kind];
      if (!table || !(key in table)) throw new Error(`No ${kind} cost for ${key}.`);
      table[key] = cost(value, kind === "rework" ? "Rework Cost" : "Scrap Cost");
    });
    if (kind === "scrap") this.#checkScrap.delete(i);
  }

  setCostMode(i, mode) {
    this.#edit((seq) => {
      const stage = seq.stages[i];
      const { costs, features } = stage;
      if (mode === "full" && "rework_per_feature" in costs) {
        const total = Object.values(costs.scrap_per_feature).reduce((a, b) => a + b, 0);
        stage.costs = { processing: costs.processing, rework: { ...costs.rework_per_feature }, scrap: { [INITIAL]: total } };
        syncCosts(stage);  // fills the multi-Feature states additively, and every Scrap Cost with the total
      } else if (mode === "shortcut" && !("rework_per_feature" in costs)) {
        if (!isAdditive(costs)) throw new Error("This cost table is not additive, so it can only be edited in full.");
        // A scrapped part costs the Stage's total, so the first Feature carries it all.
        const scrap = Object.fromEntries(features.map((f, j) => [f.name, j === 0 ? costs.scrap[INITIAL] : 0]));
        const rework = Object.fromEntries(reworkStateKeys(features).filter((k) => !k.includes("+"))
          .map((k) => [k, costs.rework[k]]));
        stage.costs = { processing: costs.processing, rework_per_feature: rework, scrap_per_feature: scrap };
      }
    });
  }

  // Appends an Operation (C20), named `name` if one is given, numbered if that is taken (`drill2`); otherwise the
  // next unused `f1`, `f2`, … (C17). It stays after the last Inspection until an Inspection is added.
  addOperation(name) {
    this.#requireMeans();
    const given = String(name ?? "").trim();
    const chosen = given ? numberedName(this.#doc, checkName(given)) : nextName(this.#doc);
    this.#edit((seq) => {
      if (!this.#open) this.#pushStage(seq);
      const i = seq.stages.length - 1;
      const stage = seq.stages[i];
      stage.features.push(newFeature(chosen));
      stage.variation.sigmas.push(DEFAULT_FEATURE.sigma);
      syncCosts(stage);
      syncProcessing(stage);
      seq.means.values[i][chosen] = midpoint(DEFAULT_FEATURE);
      this.#autoMeans.add(chosen);
      this.#autoProcessing.add(chosen);
    }, true);
  }

  // Appends an Inspection, closing the Operations after the last one into a Stage; with none, the Stage is empty.
  addInspection() {
    this.#requireMeans();
    this.#edit((seq) => { if (!this.#open) this.#pushStage(seq); }, false);
  }

  // Deleting a Stage's only Operation leaves its Inspection, which `problems` then reports.
  deleteOperation(i, j) {
    this.#requireStructure(i);
    const closesOpen = this.#isOpen(i) && this.#doc.stages[i].features.length === 1;
    this.#edit((seq) => {
      this.#takeFeature(seq, i, j);
      if (closesOpen) {
        seq.stages.pop();
        seq.means.values.pop();
        this.#checkScrap.delete(i);  // not to be inherited by the next Stage added
      }
    }, this.#open && !closesOpen);
  }

  // Up (-1) or down (+1) within the Stage.
  moveOperation(i, j, delta) {
    const target = j + delta;
    if (target < 0 || target >= this.#doc.stages[i].features.length) {
      throw new Error("An Operation can't be moved past an Inspection.");
    }
    this.#requireStructure(i);
    this.#edit((seq) => {
      const stage = seq.stages[i];
      for (const list of [stage.features, stage.variation.sigmas]) [list[j], list[target]] = [list[target], list[j]];
      syncCosts(stage);  // state keys in the new Feature order (C7)
      orderMeans(seq, i);
    });
  }

  #isOpen(i) { return this.#open && i === this.#doc.stages.length - 1; }

  #pushStage(seq) {
    seq.stages.push({
      features: [],
      variation: { type: "normal", sigmas: [], corr: 0 },
      costs: { processing: 0, rework_per_feature: {}, scrap_per_feature: {} },
      inspection: { per_stage: 0, per_feature: 0 },
    });
    seq.means.values.push({});
  }

  // Removes Feature j from Stage i, with its sigma, costs and Mean Setting.
  #takeFeature(seq, i, j) {
    const stage = seq.stages[i];
    const [feature] = stage.features.splice(j, 1);
    stage.variation.sigmas.splice(j, 1);
    syncCosts(stage);
    syncProcessing(stage);
    this.#splitStages.delete(i);
    delete seq.means.values[i][feature.name];
    this.#autoMeans.delete(feature.name);
    this.#autoProcessing.delete(feature.name);
  }

  #rename(i, j, value) {
    this.#requireMeans();
    const name = String(value).trim();
    const old = this.#doc.stages[i].features[j].name;
    if (name === old) return;
    checkName(name);
    if (usedNames(this.#doc).has(name)) throw new Error(`There is already a Feature called ${name}.`);
    this.#edit((seq) => {
      const stage = seq.stages[i];
      stage.features[j].name = name;
      const renameKeys = (table) => Object.fromEntries(Object.entries(table).map(([key, v]) =>
        [key.split("+").map((n) => (n === old ? name : n)).join("+"), v]));
      for (const kind of ["rework", "scrap", "rework_per_feature", "scrap_per_feature"]) {
        if (kind in stage.costs) stage.costs[kind] = renameKeys(stage.costs[kind]);
      }
      seq.means.values[i] = renameKeys(seq.means.values[i]);
      if (this.#autoMeans.delete(old)) this.#autoMeans.add(name);
      if (this.#autoProcessing.delete(old)) {
        this.#autoProcessing.add(name);
        stage.features[j].processing = nominalProcessing(name);
        syncProcessing(stage);
      }
    });
  }

  #requireMeans() {
    if (!this.meansEditable) {
      throw new Error(`These Mean Settings use the ${this.#doc.means.scheme} scheme, so they are read-only here.`);
    }
  }

  // Adding, removing or moving Features in Stage i.
  #requireStructure(i) {
    this.#requireMeans();
    if (!this.variationEditable(i)) {
      throw new Error(`Stage ${i + 1}'s Process Variation is preset-only, so its Features can't be changed here.`);
    }
  }

  #requireVariation(i) {
    if (!this.variationEditable(i)) throw new Error(`Stage ${i + 1}'s Process Variation is read-only here.`);
  }

  // Applies `change` to a copy, which becomes the list, with `open` saying whether its last Stage is now open. An
  // edited preset is no longer the thesis case, so its reference goes. A Stage whose earlier Stages' Processing
  // Costs now total differently has its Scrap Costs flagged for checking (C25).
  #edit(change, open = this.#open) {
    const seq = structuredClone(this.#doc);
    const before = earlierProcessingTotals(this.#doc);
    change(seq);
    delete seq.reference;
    earlierProcessingTotals(seq).forEach((total, i) => {
      if (i < before.length && total !== before[i]) this.#checkScrap.add(i);
    });
    this.#doc = seq;
    this.#open = open;
    this.#revision += 1;
  }
}

function newFeature(name) {
  const { lower, upper, rework_side } = DEFAULT_FEATURE;
  return { name, lower, upper, rework_side, processing: nominalProcessing(name) };
}

const nominalProcessing = (name) => NOMINAL_PROCESSING[name.replace(/\d+$/, "")] ?? 1;

// For each Stage, the total Processing Cost of the Stages before it.
function earlierProcessingTotals(seq) {
  let total = 0;
  return seq.stages.map((stage) => {
    const earlier = total;
    total += stage.costs.processing;
    return earlier;
  });
}

// The Stage's Processing Cost is the sum of its Operations' (C22).
function syncProcessing(stage) {
  stage.costs.processing = stage.features.reduce((sum, f) => sum + f.processing, 0);
}

const usedNames = (seq) => new Set(seq.stages.flatMap((s) => s.features.map((f) => f.name)));

function checkName(name) {
  if (!FEATURE_NAME.test(name)) throw new Error(`Feature names are 1 to 16 letters, digits or underscores, not "${name}".`);
  if (name === INITIAL) throw new Error(`"${INITIAL}" is reserved for the Initial State.`);
  return name;
}

// `name`, or if that is taken `name2`, `name3`, … (C20).
function numberedName(seq, name) {
  const used = usedNames(seq);
  let candidate = name;
  for (let k = 2; used.has(candidate); k += 1) candidate = `${name}${k}`;
  return checkName(candidate);
}

function nextName(seq) {
  const used = usedNames(seq);
  let k = 1;
  while (used.has(`f${k}`)) k += 1;
  return `f${k}`;
}

const midpoint = (f) => (f.lower + f.upper) / 2;

function number(value, label) {
  const x = typeof value === "string" && value.trim() === "" ? NaN : Number(value);
  if (!Number.isFinite(x)) throw new Error(`${label} must be a number.`);
  return x;
}

function cost(value, label) {
  const x = number(value, label);
  if (x < 0) throw new Error(`${label} can't be negative.`);
  return x;
}

// Means in Feature order, so the downloaded file reads like the Stage.
function orderMeans(seq, i) {
  const mu = seq.means.values[i];
  seq.means.values[i] = Object.fromEntries(seq.stages[i].features.map((f) => [f.name, mu[f.name]]));
}

// True when every Rework State costs the sum of its Features' rework and every state has the same Scrap Cost,
// which is what CostTable.additive builds.
function isAdditive(costs) {
  const close = (a, b) => Math.abs(a - b) <= 1e-9 * Math.max(1, Math.abs(a), Math.abs(b));
  const rework = Object.entries(costs.rework).every(([key, v]) =>
    close(v, key.split("+").reduce((sum, name) => sum + (costs.rework[name] ?? NaN), 0)));
  const scraps = Object.values(costs.scrap);
  return rework && scraps.every((v) => close(v, scraps[0]));
}

// The Stage's Rework States as C7 keys: non-empty subsets of the reworkable Features, by size, in Feature order.
export function reworkStateKeys(features) {
  const reworkable = features.filter((f) => f.rework_side !== "none").map((f) => f.name);
  const keys = [];
  const choose = (start, picked, size) => {
    if (picked.length === size) { keys.push(picked.join("+")); return; }
    for (let k = start; k < reworkable.length; k += 1) choose(k + 1, [...picked, reworkable[k]], size);
  };
  for (let size = 1; size <= reworkable.length; size += 1) choose(0, [], size);
  return keys;
}

// The same state whatever order its Feature names are in (C7).
const canonical = (key) => key.split("+").sort().join("+");

// Brings the cost tables in line with the Stage's Features, keeping every cost that still applies. A new Feature
// costs 0 (C17); in a full table a new Rework State costs the sum of its Features' rework, and a new state's Scrap
// Cost is the Initial State's.
function syncCosts(stage) {
  const { costs, features } = stage;
  if ("rework_per_feature" in costs) {
    const reworkable = features.filter((f) => f.rework_side !== "none");
    costs.rework_per_feature = Object.fromEntries(reworkable.map((f) => [f.name, costs.rework_per_feature[f.name] ?? 0]));
    costs.scrap_per_feature = Object.fromEntries(features.map((f) => [f.name, costs.scrap_per_feature[f.name] ?? 0]));
    return;
  }
  const lookup = (table) => new Map(Object.entries(table).map(([k, v]) => [canonical(k), v]));
  const rework = lookup(costs.rework);
  const scrap = lookup(costs.scrap);
  const keys = reworkStateKeys(features);
  const reworkCost = (key) => rework.get(canonical(key)) ??
    key.split("+").reduce((sum, name) => sum + (rework.get(name) ?? 0), 0);
  costs.rework = Object.fromEntries(keys.map((k) => [k, reworkCost(k)]));
  const initialScrap = scrap.get(INITIAL) ?? 0;
  costs.scrap = Object.fromEntries([INITIAL, ...keys].map((k) => [k, scrap.get(canonical(k)) ?? initialScrap]));
}
