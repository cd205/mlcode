// The page (web_app_plan.md §7): build a sequence or start from a preset, Evaluate it or Optimise its Mean Settings
// on the server, draw the diagram and the results table.

import { Builder, REWORK_SIDES } from "./builder.js";
import { attachTooltip, drawDiagram, fmtProb } from "./diagram.js";

const $ = (id) => document.getElementById(id);
let builder = null;
let undoMeans = null;  // the means before the last Optimise: one undo slot (C16)

// Calls the API; a failed call throws an Error carrying the server's readable message (C18).
async function api(path, options) {
  let response;
  try {
    response = await fetch(path, options);
  } catch {
    throw new Error("Could not reach the server. Is it running?");
  }
  const body = await response.json().catch(() => null);
  if (!response.ok) throw new Error(body?.detail ?? `${response.status} ${response.statusText}`);
  return body;
}

function showError(message) {
  $("error").textContent = message ?? "";
  $("error").hidden = !message;
}

function row(table, label, value, cls = "num", sub = false) {
  const tr = table.insertRow();
  const th = document.createElement("th");
  th.textContent = label;
  if (sub) th.className = "sub";
  tr.appendChild(th);
  const td = tr.insertCell();
  td.className = cls;
  if (value instanceof Node) td.appendChild(value); else td.textContent = value;
  return tr;
}

const money = (x) => x.toFixed(2);
const fmtMean = (x) => String(Number(x.toFixed(4)));  // optimised means are unrounded; round for display only (C12)

// The editor (§7 left panel). Typed values go through `bind`, so an edit only refreshes values and keeps the
// focus; changes to the shape of the Stages, Features or cost tables redraw the panel.
let bindings = [];

function el(tag, props = {}, ...children) {
  const node = Object.assign(document.createElement(tag), props);
  node.append(...children);
  return node;
}

// An input showing `get()`; a change calls `set(value)` on the builder, or shows why not and puts the value back.
function bind(input, get, set, { redraw = false } = {}) {
  bindings.push(() => { if (input.value !== String(get())) input.value = get(); });
  input.addEventListener("change", () => edit(() => set(input.value), redraw));
  return input;
}

function numberInput(get, set, className = "") {
  return bind(el("input", { type: "number", step: "any", className }), get, set);
}

// Text that follows the sequence, e.g. a hint.
function live(node, get) {
  bindings.push(() => { node.textContent = get(); });
  return node;
}

function editButton(label, title, onClick, disabled = false, className = "secondary") {
  const button = el("button", { type: "button", className, title, disabled }, label);
  button.setAttribute("aria-label", title);
  button.addEventListener("click", () => edit(onClick, true));
  return button;
}

const iconButton = (label, title, onClick, disabled) => editButton(label, title, onClick, disabled, "icon");

function edit(change, redraw) {
  showError(null);
  const before = builder.sequence;
  try {
    change();
    if (builder.sequence !== before) {  // e.g. renaming a Feature to its own name changes nothing
      setUndo(null);  // the undo slot is for the last Optimise only (C16)
      $("outputs").classList.add("stale");
    }
  } catch (e) {
    showError(e.message);
  }
  if (redraw) renderEditor(); else refresh();
}

function refresh() {
  for (const update of bindings) update();
}

function renderEditor() {
  bindings = [];
  const b = builder;
  const seq = b.sequence;
  const wrap = $("sequence-editor");
  wrap.replaceChildren(
    el("label", {}, "Name", bind(el("input", { type: "text" }), () => b.sequence.name ?? "", (v) => b.setName(v))),
    el("label", {}, "Selling Price", numberInput(() => b.sequence.selling_price, (v) => b.setSellingPrice(v))),
  );
  if (!b.meansEditable) {
    wrap.append(el("p", { className: "muted" }, `Mean Settings use the ${seq.means.scheme} scheme and are read-only ` +
      "here; Optimise still works. Stages and Features can't be added, removed or moved."));
  }
  seq.stages.forEach((_, i) => wrap.append(stageEditor(i)));
  wrap.append(el("div", { className: "actions" },
    editButton("Add Stage", "Add a Stage at the end", () => b.addStage(), !b.meansEditable)));
  refresh();
}

function stageEditor(i) {
  const b = builder;
  const stage = b.sequence.stages[i];
  const n = b.sequence.stages.length;
  const structure = b.meansEditable && b.variationEditable(i);
  const card = el("section", { className: "stage" });
  card.append(el("div", { className: "stage-head" }, el("h3", {}, `Stage ${i + 1}`),
    iconButton("↑", `Move Stage ${i + 1} up`, () => b.moveStage(i, -1), !b.meansEditable || i === 0),
    iconButton("↓", `Move Stage ${i + 1} down`, () => b.moveStage(i, +1), !b.meansEditable || i === n - 1),
    iconButton("✕", `Delete Stage ${i + 1}`, () => b.deleteStage(i), !b.meansEditable || n === 1)));

  const table = el("table", { className: "features" });
  table.createTHead().innerHTML = "<tr><th>Feature</th><th>L</th><th>U</th><th>Rework Side</th><th>σ</th>" +
    "<th>Mean Setting</th><th></th></tr>";
  const body = table.createTBody();
  stage.features.forEach((f, j) => {
    const name = f.name;
    const feature = () => b.sequence.stages[i].features[j];
    const tr = body.insertRow();
    const cell = (child) => tr.insertCell().append(child);
    cell(b.meansEditable
      ? bind(el("input", { type: "text", className: "name", maxLength: 16 }), () => name,
        (v) => b.setFeature(i, j, "name", v), { redraw: true })
      : name);
    cell(numberInput(() => feature().lower, (v) => b.setFeature(i, j, "lower", v)));
    cell(numberInput(() => feature().upper, (v) => b.setFeature(i, j, "upper", v)));
    const side = el("select", { disabled: !b.meansEditable }, ...REWORK_SIDES.map((s) => new Option(s, s)));
    cell(bind(side, () => feature().rework_side, (v) => b.setFeature(i, j, "rework_side", v), { redraw: true }));
    cell(b.variationEditable(i)
      ? numberInput(() => b.sequence.stages[i].variation.sigmas[j], (v) => b.setSigma(i, j, v))
      : String(stage.variation.sigmas?.[j] ?? "–"));
    if (b.meansEditable) {
      const mean = numberInput(() => fmtMean(b.sequence.means.values[i][name]), (v) => b.setMean(i, name, v), "mean");
      bindings.push(() => {
        mean.classList.toggle("auto", b.isAutoMean(name));
        mean.title = b.isAutoMean(name) ? "Midway between L and U until you type a mean" : "";
      });
      cell(mean);
    } else {
      const mu = b.sequence.means.values[i]?.[name];
      cell(typeof mu === "number" ? fmtMean(mu) : "read-only");
    }
    const last = j === stage.features.length - 1;
    cell(el("span", { className: "row-actions" },
      iconButton("↑", `Move ${name} up`, () => b.moveFeature(i, j, -1), !structure || (i === 0 && j === 0)),
      iconButton("↓", `Move ${name} down`, () => b.moveFeature(i, j, +1), !structure || (i === n - 1 && last)),
      iconButton("✕", `Delete ${name}`, () => b.deleteFeature(i, j), !structure || stage.features.length === 1)));
  });
  card.append(el("div", { className: "scroll" }, table),
    el("div", { className: "actions" },
      editButton("Add Feature", `Add a Feature to Stage ${i + 1}`, () => b.addFeature(i), !structure)));

  const corr = stage.variation.corr ?? 0;
  card.append(b.variationEditable(i)
    ? el("label", { className: "inline" }, "Correlation",
      numberInput(() => b.sequence.stages[i].variation.corr ?? 0, (v) => b.setCorr(i, v)))
    : el("p", { className: "muted" }, `Process Variation: ${stage.variation.type}` +
      (Array.isArray(corr) ? ", correlation matrix" : `, correlation ${corr}`) + " (preset-only, read-only)"));
  const { per_stage: perStage = 0, per_feature: perFeature = 0 } = stage.inspection ?? {};
  if (perStage || perFeature) {
    card.append(el("p", { className: "muted" },
      `Inspection Cost ${perStage} + ${perFeature} per Feature, per part (preset-only, read-only)`));
  }
  card.append(costEditor(i));
  return card;
}

// One row per Feature (shortcut) or per state (full table), C8. Scrap Cost is cumulative and never summed for the
// user; the earlier Stages' Processing Costs are shown beside it as a hint (C9).
function costEditor(i) {
  const b = builder;
  const { costs } = b.sequence.stages[i];
  const shortcut = "rework_per_feature" in costs;
  const wrap = el("div", { className: "costs" });
  wrap.append(el("label", { className: "inline" }, "Processing Cost",
    numberInput(() => b.sequence.stages[i].costs.processing, (v) => b.setProcessing(i, v))));
  const mode = el("select", {}, new Option("per Feature", "shortcut"), new Option("full table, by state", "full"));
  if (!b.canUseShortcut(i)) {
    mode.options[0].disabled = true;
    mode.title = "This table is not additive, so it can only be edited in full";
  }
  wrap.append(el("label", { className: "inline" }, "Costs",
    bind(mode, () => (shortcut ? "shortcut" : "full"), (v) => b.setCostMode(i, v), { redraw: true })));

  const [reworkTable, scrapTable] = shortcut ? ["rework_per_feature", "scrap_per_feature"] : ["rework", "scrap"];
  const table = el("table", { className: "cost-table" });
  table.createTHead().innerHTML = `<tr><th>${shortcut ? "Feature" : "State"}</th><th>Rework Cost</th>` +
    "<th>Scrap Cost (includes value added in earlier Stages)</th></tr>";
  const body = table.createTBody();
  for (const key of Object.keys(costs[scrapTable])) {
    const tr = body.insertRow();
    tr.insertCell().textContent = key;
    tr.insertCell().append(key in costs[reworkTable]
      ? numberInput(() => b.sequence.stages[i].costs[reworkTable][key], (v) => b.setCost(i, "rework", key, v))
      : "–");
    tr.insertCell().append(numberInput(() => b.sequence.stages[i].costs[scrapTable][key],
      (v) => b.setCost(i, "scrap", key, v)));
  }
  wrap.append(el("div", { className: "scroll" }, table));
  if (shortcut) {
    wrap.append(el("p", { className: "muted" },
      "A scrapped part costs the sum of these Scrap Costs; a Rework State, the sum of its Features' Rework Costs."));
  }
  if (i > 0) {
    wrap.append(live(el("p", { className: "muted" }), () => "Earlier Stages' Processing Costs: " +
      b.earlierProcessing(i).map((c, k) => `${c} (Stage ${k + 1})`).join(", ")));
  }
  return wrap;
}

function showResults(results) {
  const table = $("results");
  table.replaceChildren();
  const t = results.totals;
  row(table, "Expected Profit", money(t.expected_profit));
  row(table, "Revenue", money(t.revenue));
  row(table, "Production cost", money(t.production_cost));
  row(table, "processing", money(t.processing_cost), "num", true);
  row(table, "rework", money(t.rework_cost), "num", true);
  row(table, "scrap", money(t.scrap_cost), "num", true);
  row(table, "inspection", money(t.inspection_cost), "num", true);
  row(table, "Final Conformance", fmtProb(t.final_conformance));
  results.means.values.forEach((mu, i) => {
    row(table, `Mean Settings, Stage ${i + 1}`, Object.entries(mu).map(([n, v]) => `${n} = ${fmtMean(v)}`).join(", "));
  });

  const ref = results.reference;
  if (ref) {
    const cell = document.createElement("span");
    const verdict = document.createElement("span");
    verdict.className = ref.within_tolerance ? "ok" : "gap";
    verdict.textContent = ref.within_tolerance ? " ✓" : ` ✗ gap ${ref.difference >= 0 ? "+" : ""}${ref.difference.toPrecision(3)}`;
    cell.append(`${ref.quantity} ${ref.computed.toFixed(5)} vs ${ref.value} ± ${ref.tolerance}`, verdict);
    row(table, `Engine vs thesis (${ref.source})`, cell);
    if (ref.note) row(table, "Note", ref.note, "");
  }
  const o = results.optimisation;
  if (o) {
    const objective = o.objective === "expected_profit" ? "maximum Expected Profit" : "minimum production cost";
    row(table, "Optimised for", `${objective} (${money(o.objective_value)})`, "");
    row(table, "Optimiser", `${o.method}, ${o.n_starts} starts (seed ${o.seed}), ${o.n_evaluations} evaluations, ` +
      (o.success ? "converged" : "did not converge"), "");
    row(table, "Bounds", Object.entries(o.bounds).map(([n, [lo, hi]]) => `${n} ∈ [${lo}, ${hi}]`).join(", "), "");
  }
  table.hidden = false;
}

function setUndo(means) {
  undoMeans = means;
  $("undo").hidden = !means;
}

// Shows `next` in the editor; if it can't be drawn (a malformed upload), keeps the current sequence.
function showBuilder(next) {
  const previous = builder;
  builder = next;
  try {
    renderEditor();
  } catch {
    builder = previous;
    if (previous) renderEditor();
    throw new Error("That sequence could not be shown in the editor.");
  }
  setUndo(null);
}

async function loadPreset(id) {
  showError(null);
  try {
    showBuilder(new Builder(await api(`/api/presets/${encodeURIComponent(id)}`)));
  } catch (e) {
    showError(e.message);
  }
}

// A sequence that isn't a preset: the preset choice goes blank.
function openOwn(next) {
  showBuilder(next);
  $("preset").value = "";
  $("preset-description").textContent = "";
}

function download() {
  const blob = new Blob([builder.download()], { type: "application/json" });
  const slug = (builder.sequence.name ?? "").replace(/[^A-Za-z0-9_-]+/g, "-").replace(/^-+|-+$/g, "");
  const link = el("a", { href: URL.createObjectURL(blob), download: `${slug || "sequence"}.json`, hidden: true });
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(link.href), 60_000);  // revoking at once can cancel the download
}

async function upload(file) {
  showError(null);
  try {
    openOwn(Builder.upload(await file.text()));
    await submit("evaluate");  // the server checks the rest of the file and says what's wrong
  } catch (e) {
    showError(e.message);
  }
}

const BUTTONS = ["evaluate", "optimise", "undo"];

// Evaluate, or Optimise and replace the sequence's means with the optimum (C16).
async function submit(action) {
  const submitted = builder?.sequence;  // the sequence may change while the request is in flight
  if (!submitted) return;
  showError(null);
  for (const id of BUTTONS) $(id).disabled = true;
  try {
    const body = { sequence: submitted, n_parts: Number($("n-parts").value) };
    if (action === "optimise") body.objective = $("objective").value;
    const results = await api(`/api/${action}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    if (builder.sequence !== submitted) return;
    if (action === "optimise") {
      builder.setMeans(results.means);
      setUndo(submitted.means);
      renderEditor();
    }
    drawDiagram($("diagram"), builder.sequence, results);
    showResults(results);
    $("outputs").classList.remove("stale");
  } catch (e) {
    showError(e.message);
  } finally {
    for (const id of BUTTONS) $(id).disabled = false;
  }
}

function undo() {
  if (!builder || !undoMeans) return;
  builder.setMeans(undoMeans);
  setUndo(null);
  renderEditor();
  submit("evaluate");  // redraw at the restored means
}

async function init() {
  attachTooltip($("diagram"), $("tooltip"));
  $("evaluate").addEventListener("click", () => submit("evaluate"));
  $("optimise").addEventListener("click", () => submit("optimise"));
  $("undo").addEventListener("click", undo);
  $("new").addEventListener("click", () => openOwn(Builder.blank()));
  $("download").addEventListener("click", download);
  $("upload").addEventListener("click", () => $("upload-file").click());
  $("upload-file").addEventListener("change", (e) => {
    const [file] = e.target.files;
    e.target.value = "";  // so choosing the same file again still uploads it
    if (file) upload(file);
  });
  $("preset").addEventListener("change", (e) => {
    const option = e.target.selectedOptions[0];
    $("preset-description").textContent = option?.dataset.description ?? "";
    loadPreset(e.target.value);
  });
  try {
    const presets = await api("/api/presets");
    for (const p of presets) {
      const option = new Option(p.name, p.id);
      option.dataset.description = p.description;
      $("preset").add(option);
    }
    if (presets.length) $("preset").dispatchEvent(new Event("change"));
    else openOwn(Builder.blank());
  } catch (e) {
    showError(e.message);
  }
}

init();
