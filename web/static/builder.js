// The builder's edits to a sequence document (web_app_plan.md §4, §7). No DOM here: the page calls these and
// redraws; the tests drive them through node. Every edit replaces `sequence` with a new object, so the page can
// tell that the sequence changed while a request was in flight.

const FEATURE_NAME = /^[A-Za-z0-9_]{1,16}$/;
const INITIAL = "initial";
export const DEFAULT_FEATURE = { lower: 8, upper: 12, rework_side: "upper", sigma: 1 };  // C17
export const REWORK_SIDES = ["upper", "lower", "none"];

export class Builder {
  #sequence;
  #autoMeans;  // names of Features whose Mean Setting still follows L and U (C17)

  constructor(sequence) {
    this.#sequence = structuredClone(sequence);
    this.#autoMeans = new Set();
  }

  // One Stage with one default Feature; Selling Price and costs 0.
  static blank() {
    const b = new Builder({ format_version: 1, name: "New sequence", selling_price: 0, stages: [],
                            means: { scheme: "per_feature", values: [] } });
    b.addStage();
    return b;
  }

  // The sequence file the page downloads, and a Builder over an uploaded one. The server checks the rest.
  download() { return `${JSON.stringify(this.#sequence, null, 2)}\n`; }

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

  get sequence() { return this.#sequence; }

  // Preset-only settings are shown read-only (C10, C11): Mean Settings in another scheme, and a correlation matrix
  // or copula. While either applies, the Features they describe can't be added, removed or moved (C10, C11).
  get meansEditable() { return this.#sequence.means.scheme === "per_feature"; }

  variationEditable(i) {
    const v = this.#sequence.stages[i].variation;
    return v.type === "normal" && !Array.isArray(v.corr);
  }

  isAutoMean(name) { return this.#autoMeans.has(name); }

  // The earlier Stages' Processing Costs: the hint beside a cumulative Scrap Cost (C9).
  earlierProcessing(i) { return this.#sequence.stages.slice(0, i).map((s) => s.costs.processing); }

  // A full table can become the per-Feature shortcut only when it is additive, so nothing is lost (C8).
  canUseShortcut(i) {
    const { costs } = this.#sequence.stages[i];
    return "rework_per_feature" in costs || isAdditive(costs);
  }

  // After Optimise or Undo (C16): new values, not an edit, so the reference stays.
  setMeans(means) {
    this.#sequence = { ...this.#sequence, means: structuredClone(means) };
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

  setProcessing(i, value) { this.#edit((seq) => { seq.stages[i].costs.processing = cost(value, "Processing Cost"); }); }

  // `kind` is rework or scrap; `key` is a state key (full table) or a Feature name (per-Feature shortcut).
  setCost(i, kind, key, value) {
    this.#edit((seq) => {
      const { costs } = seq.stages[i];
      const table = costs[`${kind}_per_feature`] ?? costs[kind];
      if (!table || !(key in table)) throw new Error(`No ${kind} cost for ${key}.`);
      table[key] = cost(value, kind === "rework" ? "Rework Cost" : "Scrap Cost");
    });
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

  addFeature(i) {
    this.#requireStructure(i);
    this.#edit((seq) => {
      const stage = seq.stages[i];
      const name = nextName(seq);
      stage.features.push(newFeature(name));
      stage.variation.sigmas.push(DEFAULT_FEATURE.sigma);
      syncCosts(stage);
      seq.means.values[i][name] = midpoint(DEFAULT_FEATURE);
      this.#autoMeans.add(name);
    });
  }

  addStage() {
    this.#requireMeans();
    this.#edit((seq) => {
      const name = nextName(seq);
      seq.stages.push({
        features: [newFeature(name)],
        variation: { type: "normal", sigmas: [DEFAULT_FEATURE.sigma], corr: 0 },
        costs: { processing: 0, rework_per_feature: { [name]: 0 }, scrap_per_feature: { [name]: 0 } },
        inspection: { per_stage: 0, per_feature: 0 },
      });
      seq.means.values.push({ [name]: midpoint(DEFAULT_FEATURE) });
      this.#autoMeans.add(name);
    });
  }

  deleteFeature(i, j) {
    this.#requireStructure(i);
    if (this.#sequence.stages[i].features.length === 1) {
      throw new Error("A Stage needs at least one Feature: delete the Stage instead.");
    }
    this.#edit((seq) => { this.#takeFeature(seq, i, j); });
  }

  // Up (-1) or down (+1) within the Stage; past either end, into the neighbouring Stage.
  moveFeature(i, j, delta) {
    const { stages } = this.#sequence;
    const n = stages[i].features.length;
    const target = j + delta;
    if (target >= 0 && target < n) {
      this.#requireStructure(i);
      this.#edit((seq) => {
        const stage = seq.stages[i];
        for (const list of [stage.features, stage.variation.sigmas]) [list[j], list[target]] = [list[target], list[j]];
        syncCosts(stage);  // state keys in the new Feature order (C7)
        orderMeans(seq, i);
      });
      return;
    }
    const to = i + delta;
    if (to < 0 || to >= stages.length) throw new Error("There is no Stage to move this Feature into.");
    if (n === 1) throw new Error("A Stage needs at least one Feature: move the Stage, or delete it, instead.");
    this.#requireStructure(i);
    this.#requireStructure(to);
    this.#edit((seq) => {
      const moved = this.#takeFeature(seq, i, j);
      const stage = seq.stages[to];
      const at = delta < 0 ? stage.features.length : 0;
      stage.features.splice(at, 0, moved.feature);
      stage.variation.sigmas.splice(at, 0, moved.sigma);
      const { costs } = stage;
      if ("rework_per_feature" in costs) {
        costs.scrap_per_feature[moved.feature.name] = moved.scrap;
        if (moved.rework !== undefined) costs.rework_per_feature[moved.feature.name] = moved.rework;
      } else if (moved.rework !== undefined) {
        costs.rework[moved.feature.name] = moved.rework;  // full table: the moved Feature's own Rework State
      }
      syncCosts(stage);
      seq.means.values[to][moved.feature.name] = moved.mean;
      orderMeans(seq, to);
    });
  }

  deleteStage(i) {
    this.#requireMeans();
    if (this.#sequence.stages.length === 1) throw new Error("A Sequence needs at least one Stage.");
    this.#edit((seq) => {
      for (const f of seq.stages[i].features) this.#autoMeans.delete(f.name);
      seq.stages.splice(i, 1);
      seq.means.values.splice(i, 1);
    });
  }

  moveStage(i, delta) {
    this.#requireMeans();
    const to = i + delta;
    if (to < 0 || to >= this.#sequence.stages.length) throw new Error("There is no Stage to swap with.");
    this.#edit((seq) => {
      for (const list of [seq.stages, seq.means.values]) [list[i], list[to]] = [list[to], list[i]];
    });
  }

  // Removes Feature j from Stage i, with everything the sequence held for it, and returns that.
  #takeFeature(seq, i, j) {
    const stage = seq.stages[i];
    const [feature] = stage.features.splice(j, 1);
    const [sigma] = stage.variation.sigmas.splice(j, 1);
    const { costs } = stage;
    const shortcut = "rework_per_feature" in costs;
    const rework = shortcut ? costs.rework_per_feature[feature.name] : costs.rework[feature.name];
    const scrap = shortcut ? costs.scrap_per_feature[feature.name] : 0;
    syncCosts(stage);
    const mean = seq.means.values[i][feature.name];
    delete seq.means.values[i][feature.name];
    return { feature, sigma, rework, scrap, mean };
  }

  #rename(i, j, value) {
    this.#requireMeans();
    const name = String(value).trim();
    const old = this.#sequence.stages[i].features[j].name;
    if (name === old) return;
    if (!FEATURE_NAME.test(name)) throw new Error(`Feature names are 1 to 16 letters, digits or underscores, not "${name}".`);
    if (name === INITIAL) throw new Error(`"${INITIAL}" is reserved for the Initial State.`);
    if (this.#sequence.stages.some((s) => s.features.some((f) => f.name === name))) {
      throw new Error(`There is already a Feature called ${name}.`);
    }
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
    });
  }

  #requireMeans() {
    if (!this.meansEditable) {
      throw new Error(`These Mean Settings use the ${this.#sequence.means.scheme} scheme, so they are read-only here.`);
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

  // Applies `change` to a copy, which becomes the sequence. An edited preset is no longer the thesis case, so its
  // reference goes.
  #edit(change) {
    const seq = structuredClone(this.#sequence);
    change(seq);
    delete seq.reference;
    this.#sequence = seq;
  }
}

function newFeature(name) {
  const { lower, upper, rework_side } = DEFAULT_FEATURE;
  return { name, lower, upper, rework_side };
}

function nextName(seq) {
  const used = new Set(seq.stages.flatMap((s) => s.features.map((f) => f.name)));
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
