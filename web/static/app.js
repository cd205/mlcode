// The page (web_app_plan.md §7): pick a preset, Evaluate it or Optimise its Mean Settings on the server, draw the
// diagram and the results table.

import { attachTooltip, drawDiagram, fmtProb } from "./diagram.js";

const $ = (id) => document.getElementById(id);
let sequence = null;
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

function showSequence(seq) {
  const wrap = $("sequence-summary");
  wrap.replaceChildren();
  seq.stages.forEach((stage, i) => {
    const h = document.createElement("h3");
    h.textContent = `Stage ${i + 1}`;
    const table = document.createElement("table");
    table.createTHead().innerHTML = "<tr><th>Feature</th><th>L</th><th>U</th><th>Rework Side</th><th>σ</th><th>Mean Setting</th></tr>";
    const body = table.createTBody();
    stage.features.forEach((f, j) => {
      const tr = body.insertRow();
      const mu = seq.means.values[i]?.[f.name];
      for (const v of [f.name, f.lower, f.upper, f.rework_side, stage.variation.sigmas[j], mu === undefined ? "–" : fmtMean(mu)]) {
        tr.insertCell().textContent = v;
      }
    });
    const corr = document.createElement("p");
    corr.className = "muted";
    corr.textContent = `Correlation ${stage.variation.corr ?? 0} · Processing Cost ${stage.costs.processing}`;
    wrap.append(h, table, corr, costTable(stage.costs));
  });
}

// One row per state, or per Feature for the shortcut (C8). Scrap Costs are cumulative (C9).
function costTable(costs) {
  const [keyLabel, rework, scrap] = "rework_per_feature" in costs
    ? ["Feature", costs.rework_per_feature, costs.scrap_per_feature]
    : ["State", costs.rework, costs.scrap];
  const table = document.createElement("table");
  table.createTHead().innerHTML = `<tr><th>${keyLabel}</th><th>Rework Cost</th>` +
    "<th>Scrap Cost (includes value added in earlier Stages)</th></tr>";
  const body = table.createTBody();
  for (const key of Object.keys(scrap)) {
    const tr = body.insertRow();
    for (const v of [key, rework[key] ?? "–", scrap[key]]) tr.insertCell().textContent = v;
  }
  return table;
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

async function loadPreset(id) {
  showError(null);
  try {
    sequence = await api(`/api/presets/${encodeURIComponent(id)}`);
    setUndo(null);
    showSequence(sequence);
  } catch (e) {
    showError(e.message);
  }
}

const BUTTONS = ["evaluate", "optimise", "undo"];

// Evaluate, or Optimise and replace the sequence's means with the optimum (C16).
async function submit(action) {
  const submitted = sequence;  // the preset may change while the request is in flight
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
    if (sequence !== submitted) return;
    if (action === "optimise") {
      setUndo(submitted.means);
      sequence = { ...submitted, means: results.means };
      showSequence(sequence);
    }
    drawDiagram($("diagram"), sequence, results);
    showResults(results);
  } catch (e) {
    showError(e.message);
  } finally {
    for (const id of BUTTONS) $(id).disabled = false;
  }
}

function undo() {
  if (!sequence || !undoMeans) return;
  sequence = { ...sequence, means: undoMeans };
  setUndo(null);
  showSequence(sequence);
  submit("evaluate");  // redraw at the restored means
}

async function init() {
  attachTooltip($("diagram"), $("tooltip"));
  $("evaluate").addEventListener("click", () => submit("evaluate"));
  $("optimise").addEventListener("click", () => submit("optimise"));
  $("undo").addEventListener("click", undo);
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
  } catch (e) {
    showError(e.message);
  }
}

init();
