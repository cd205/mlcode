// The page (web_app_plan.md §7): build a sequence or start from a preset, Evaluate it or Optimise its Mean Settings
// on the server, draw the diagram and the results table.

import { Builder, OPERATION_NAMES, REWORK_SIDES } from "./builder.js";
import { attachTooltip, drawDiagram, fmtProb } from "./diagram.js";

const $ = (id) => document.getElementById(id);
let builder = null;
let undoMeans = null;  // the means before the last Optimise: one undo slot (C16)
let selected = null;  // the row whose editor is open: "op:<name>" or "insp:<Stage index>" (§7.1)
let busy = false;  // a request is in flight

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

// The editor (§7.1 left panel). Typed values go through `bind`, so an edit only refreshes values and keeps the
// focus; changes to the shape of the list or the cost tables redraw the panel.
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
  const before = builder.revision;
  try {
    change();
    if (builder.revision !== before) {  // e.g. renaming a Feature to its own name changes nothing
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
  updateActions();
}

// Evaluate, Optimise and Download need a valid Sequence list (C21).
function updateActions() {
  const invalid = !builder?.sequence;
  for (const id of ["evaluate", "optimise", "undo"]) $(id).disabled = busy || invalid;
  $("download").disabled = invalid;
  const title = invalid ? "Fix the warnings in the Sequence list first" : "";
  for (const id of ["evaluate", "optimise", "download"]) $(id).title = title;
}

function renderEditor() {
  bindings = [];
  const b = builder;
  const doc = () => b.document;
  const wrap = $("sequence-editor");
  wrap.replaceChildren(
    el("label", {}, "Name", bind(el("input", { type: "text" }), () => doc().name ?? "", (v) => b.setName(v))),
    el("label", {}, "Selling Price", numberInput(() => doc().selling_price, (v) => b.setSellingPrice(v))),
  );
  if (!b.meansEditable) {
    wrap.append(el("p", { className: "muted" }, `Mean Settings use the ${doc().means.scheme} scheme and are ` +
      "read-only here; Optimise still works. Operations and Inspections can't be added, removed or moved."));
  }
  const problems = b.problems;
  const list = el("ol", { className: "seq-list" });
  b.rows.forEach((r, k) => {
    list.append(r.kind === "operation" ? operationRow(r) : inspectionRow(r));
    for (const p of problems.filter((p) => p.row === k)) {
      list.append(el("li", { className: "warning", role: "status" }, p.message));
    }
  });
  const name = el("input", { type: "text", className: "name", maxLength: 16, placeholder: "name (optional)" });
  name.setAttribute("list", "operation-names");
  name.setAttribute("aria-label", "New Operation's name");
  wrap.append(list, el("datalist", { id: "operation-names" }, ...OPERATION_NAMES.map((n) => new Option(n))),
    el("div", { className: "actions add-row" }, name,
      editButton("Add Operation", "Add an Operation at the end", () => {
        b.addOperation(name.value);
        selected = `op:${b.rows.at(-1).name}`;
      }, !b.meansEditable),
      editButton("Add Inspection", "Add an Inspection at the end", () => b.addInspection(), !b.meansEditable)));
  refresh();
}

// A row of the list; clicking its summary opens its editor below it and closes any other (§7.1).
function listRow(key, className, summary, buttons, editor) {
  const open = selected === key;
  const head = el("button", { type: "button", className: "row-summary" }, summary);
  head.setAttribute("aria-expanded", String(open));
  head.addEventListener("click", () => {
    selected = open ? null : key;
    renderEditor();
  });
  const item = el("li", { className: `row ${className}${open ? " open" : ""}` },
    el("div", { className: "row-head" }, head, el("span", { className: "row-actions" }, ...buttons)));
  if (open) item.append(editor());
  return item;
}

function operationRow(r) {
  const b = builder;
  const { stage: i, index: j, name } = r;
  const structure = b.meansEditable && b.variationEditable(i);
  const summary = live(el("span"), () => {
    const f = b.document.stages[i].features[j];
    const mu = b.document.means.values[i]?.[f.name];
    return `${f.name} · ${f.lower}–${f.upper} · μ ${typeof mu === "number" ? fmtMean(mu) : "–"}`;
  });
  return listRow(`op:${name}`, "operation", summary, [
    iconButton("↑", `Move ${name} up`, () => b.moveOperation(i, j, -1), !structure || !r.canMoveUp),
    iconButton("↓", `Move ${name} down`, () => b.moveOperation(i, j, +1), !structure || !r.canMoveDown),
    iconButton("✕", `Delete ${name}`, () => b.deleteOperation(i, j), !structure),
  ], () => operationEditor(i, j, name));
}

function operationEditor(i, j, name) {
  const b = builder;
  const feature = () => b.document.stages[i].features[j];
  const box = el("div", { className: "row-editor" });
  const field = (label, child) => box.append(el("label", { className: "inline" }, label, child));
  if (b.meansEditable) {
    const input = el("input", { type: "text", className: "name", maxLength: 16 });
    input.setAttribute("list", "operation-names");
    field("Name", bind(input, () => name, (v) => {
      b.setFeature(i, j, "name", v);
      selected = `op:${feature().name}`;
    }, { redraw: true }));
  }
  field("L", numberInput(() => feature().lower, (v) => b.setFeature(i, j, "lower", v)));
  field("U", numberInput(() => feature().upper, (v) => b.setFeature(i, j, "upper", v)));
  const side = el("select", { disabled: !b.meansEditable }, ...REWORK_SIDES.map((s) => new Option(s, s)));
  field("Rework Side", bind(side, () => feature().rework_side, (v) => b.setFeature(i, j, "rework_side", v),
    { redraw: true }));
  const sigmas = () => b.document.stages[i].variation.sigmas;
  if (b.variationEditable(i)) field("σ", numberInput(() => sigmas()[j], (v) => b.setSigma(i, j, v)));
  else box.append(el("p", { className: "muted" }, `σ ${sigmas()?.[j] ?? "–"} (preset-only, read-only)`));
  const processing = numberInput(() => feature().processing, (v) => b.setFeature(i, j, "processing", v));
  bindings.push(() => {
    const auto = b.isAutoProcessing(feature().name);
    processing.classList.toggle("auto", auto);
    processing.title = auto ? "A nominal cost for the Operation's name until you type a cost" : "";
  });
  field("Processing Cost", processing);
  const mu = () => b.document.means.values[i]?.[name];
  if (b.meansEditable) {
    const mean = numberInput(() => fmtMean(mu()), (v) => b.setMean(i, name, v), "mean");
    bindings.push(() => {
      mean.classList.toggle("auto", b.isAutoMean(name));
      mean.title = b.isAutoMean(name) ? "Midway between L and U until you type a mean" : "";
    });
    field("Mean Setting", mean);
  } else {
    box.append(el("p", { className: "muted" },
      `Mean Setting ${typeof mu() === "number" ? fmtMean(mu()) : "read-only"} (${b.document.means.scheme} scheme)`));
  }
  return box;
}

function inspectionRow(r) {
  return listRow(`insp:${r.stage}`, "inspection", r.label, [], () => inspectionEditor(r.stage));
}

function inspectionEditor(i) {
  const b = builder;
  const stage = () => b.document.stages[i];
  const box = el("div", { className: "row-editor" });
  const corr = stage().variation.corr ?? 0;
  box.append(b.variationEditable(i)
    ? el("label", { className: "inline" }, "Correlation",
      numberInput(() => stage().variation.corr ?? 0, (v) => b.setCorr(i, v)))
    : el("p", { className: "muted" }, `Process Variation: ${stage().variation.type}` +
      (Array.isArray(corr) ? ", correlation matrix" : `, correlation ${corr}`) + " (preset-only, read-only)"));
  box.append(el("label", { className: "inline" }, "Inspection Cost",
    numberInput(() => stage().inspection?.per_stage ?? 0, (v) => b.setInspection(i, "per_stage", v)),
    "+", numberInput(() => stage().inspection?.per_feature ?? 0, (v) => b.setInspection(i, "per_feature", v)),
    "per Feature"));
  box.append(costEditor(i));
  return box;
}

// One row per Feature (shortcut) or per state (full table), C8. Scrap Cost is cumulative and never summed for the
// user; the earlier Stages' Processing Costs are shown beside it as a hint, and its fields are marked for checking
// when those change (C9, C25). The Stage's Processing Cost is its Operations' sum, edited on the Operations (C22).
function costEditor(i) {
  const b = builder;
  const { costs } = b.document.stages[i];
  const shortcut = "rework_per_feature" in costs;
  const wrap = el("div", { className: "costs" });
  wrap.append(live(el("p"), () => {
    const note = b.processingNote(i);
    return `Processing Cost (this Stage): ${fmtMean(b.document.stages[i].costs.processing)}, the sum of its ` +
      `Operations'${note ? ` (${note})` : ""}`;
  }));
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
      ? numberInput(() => b.document.stages[i].costs[reworkTable][key], (v) => b.setCost(i, "rework", key, v))
      : "–");
    tr.insertCell().append(scrapInput(i, scrapTable, key));
  }
  wrap.append(el("div", { className: "scroll" }, table));
  if (shortcut) {
    wrap.append(el("p", { className: "muted" },
      "A scrapped part costs the sum of these Scrap Costs; a Rework State, the sum of its Features' Rework Costs."));
  }
  if (i > 0) {
    wrap.append(live(el("p", { className: "muted" }), () => "Earlier Stages' Processing Costs: " +
      b.earlierProcessing(i).map((c, k) => `${fmtMean(c)} (Stage ${k + 1})`).join(", ")));
  }
  return wrap;
}

// A Scrap Cost field, amber with "check" beside it while the earlier Stages' Processing Costs have changed (C25).
function scrapInput(i, table, key) {
  const b = builder;
  const input = numberInput(() => b.document.stages[i].costs[table][key], (v) => b.setCost(i, "scrap", key, v));
  const marker = el("span", { className: "check-marker" }, "check");
  bindings.push(() => {
    const check = b.scrapNeedsCheck(i);
    input.classList.toggle("check", check);
    input.title = check ? "Earlier Stages' Processing Costs changed: check this cumulative Scrap Cost" : "";
    marker.hidden = !check;
  });
  return el("span", { className: "scrap-cell" }, input, marker);
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
  selected = null;
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
  if (!builder?.sequence) return;
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

// Evaluate, or Optimise and replace the sequence's means with the optimum (C16).
async function submit(action) {
  const submitted = builder?.sequence;  // null while the list has problems (C21)
  if (!submitted) return;
  const revision = builder.revision;  // the list may change while the request is in flight
  showError(null);
  busy = true;
  updateActions();
  try {
    const body = { sequence: submitted, n_parts: Number($("n-parts").value) };
    if (action === "optimise") body.objective = $("objective").value;
    const results = await api(`/api/${action}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    if (builder.revision !== revision) return;
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
    busy = false;
    updateActions();
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
