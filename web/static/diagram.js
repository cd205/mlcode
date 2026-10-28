// The flow diagram (web_app_plan.md §7, C4): Stages left to right, a rework loop per Rework State, Conform and
// Scrap sinks, and per-Pass bars (C^I, R^I, S^I, ...) for N parts started, in the style of thesis Figs 3.12 and 3.14.
// Drawn from the results JSON; any element with `data-tip` shows its text on hover.

const NS = "http://www.w3.org/2000/svg";
const COLOUR = { conform: "var(--conform)", rework: "var(--rework)", scrap: "var(--scrap)", processing: "var(--processing)" };
const LETTER = { conform: "C", rework: "R", scrap: "S" };
const KINDS = ["conform", "rework", "scrap"];

const COLUMN = 330;               // horizontal space per Stage
const STAGE = { x: 110, y: 50, w: 140, h: 60 };
const SINK = { dx: 200, w: 100, h: 46 };
const REWORK = { dy: 130, w: 100, h: 40, gap: 54 };
const BARS_H = 130;               // tallest bar

const ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X",
  "XI", "XII", "XIII", "XIV", "XV", "XVI", "XVII", "XVIII", "XIX", "XX"];
const passLabel = (k) => ROMAN[k] ?? String(k + 1);

const fmtCount = (n) => Math.round(n).toLocaleString("en-GB");
export const fmtProb = (p) => p.toFixed(5);

function el(name, attrs = {}, parent = null) {
  const node = document.createElementNS(NS, name);
  for (const [k, v] of Object.entries(attrs)) node.setAttribute(k, v);
  if (parent) parent.appendChild(node);
  return node;
}

function text(parent, x, y, content, attrs = {}) {
  const node = el("text", { x, y, ...attrs }, parent);
  node.textContent = content;
  return node;
}

function sum(values) {
  return Object.values(values).reduce((a, b) => a + b, 0);
}

function arrow(parent, points, kind, tip) {
  const d = "M" + points.map(([x, y]) => `${x},${y}`).join(" L");
  const g = el("g", { "data-tip": tip }, parent);
  el("path", { d, fill: "none", stroke: "transparent", "stroke-width": 12 }, g);  // wider hover target
  el("path", { d, fill: "none", stroke: COLOUR[kind], "stroke-width": 2.5, "marker-end": `url(#head-${kind})` }, g);
  return g;
}

function box(parent, x, y, w, h, fill, lines, tip) {
  const g = el("g", { "data-tip": tip }, parent);
  el("rect", { x, y, width: w, height: h, rx: 6, fill, stroke: "var(--ink)", "stroke-width": 1 }, g);
  lines.forEach((line, i) => {
    text(g, x + w / 2, y + h / 2 + (i - (lines.length - 1) / 2) * 15 + 4, line,
      { "text-anchor": "middle", "font-weight": i === 0 ? 600 : 400 });
  });
  return g;
}

function defs(svg) {
  const d = el("defs", {}, svg);
  for (const name of Object.keys(COLOUR)) {
    const m = el("marker", { id: `head-${name}`, viewBox: "0 0 10 10", refX: 9, refY: 5,
      markerWidth: 6, markerHeight: 6, orient: "auto-start-reverse" }, d);
    el("path", { d: "M0,0 L10,5 L0,10 z", fill: COLOUR[name] }, m);
  }
}

// A title, then "from <state>: p = 0.95450" per source state, then the expected parts over all Passes.
function transitionTip(title, stage, pick, counts) {
  const lines = [title];
  for (const [state, t] of Object.entries(stage.transitions)) {
    const p = pick(t);
    if (p > 0) lines.push(`from ${state}: p = ${fmtProb(p)}`);
  }
  lines.push(`expected parts: ${counts.toFixed(1)}`);
  return lines.join("\n");
}

function totalOver(stage, kind, filter = () => true) {
  return stage.passes.reduce((acc, p) =>
    acc + Object.entries(p[kind]).filter(([s]) => filter(s)).reduce((a, [, n]) => a + n, 0), 0);
}

function drawStage(svg, sequence, results, i) {
  const stage = results.stages[i];
  const names = sequence.stages[i].features.map((f) => f.name);
  const last = i === results.stages.length - 1;
  const x = STAGE.x + i * COLUMN;
  const { y, w, h } = STAGE;
  const midY = y + h / 2;
  const entering = results.n_parts * stage.reach_probability;

  if (i === 0) {
    arrow(svg, [[20, midY], [x - 2, midY]], "processing",
      `${fmtCount(entering)} parts start Stage 1\nReach Probability ${fmtProb(stage.reach_probability)}`);
    text(svg, 24, midY - 8, `N = ${fmtCount(results.n_parts)}`, { class: "label" });
  }

  const visits = Object.entries(stage.visits).map(([s, v]) => `visits to ${s}: ${v.toFixed(5)}`).join("\n");
  box(svg, x, y, w, h, COLOUR.processing, [`Stage ${i + 1}`, names.join(", ")],
    `Stage ${i + 1}: ${names.join(", ")}\n` +
    `Reach Probability ${fmtProb(stage.reach_probability)}\n` +
    `Final Conformance ${fmtProb(stage.final_conformance)}\n` +
    `Scrap probability ${fmtProb(stage.scrap_probability)}\n${visits}`);

  // Conform: to the next Stage, or to the Conform sink after the last Stage.
  const conformCount = totalOver(stage, "conform");
  const conformTip = transitionTip(`Conform${last ? "" : ` → Stage ${i + 2}`}`, stage, (t) => t.conform, conformCount);
  const conformEnd = last ? x + SINK.dx : x + COLUMN;
  arrow(svg, [[x + w, midY], [conformEnd - 2, midY]], "conform", conformTip);
  text(svg, x + w + 8, midY - 8, `C ${fmtProb(stage.transitions.initial.conform)}`, { class: "label" });
  if (last) {
    box(svg, conformEnd, y + (h - SINK.h) / 2, SINK.w, SINK.h, COLOUR.conform,
      ["Conform", fmtCount(results.n_parts * results.totals.final_conformance)],
      `Conform: ${fmtCount(results.n_parts * results.totals.final_conformance)} of ${fmtCount(results.n_parts)} parts\n` +
      `Final Conformance ${fmtProb(results.totals.final_conformance)}`);
  }

  // Scrap sink, below and to the right of the Stage.
  const scrapY = y + REWORK.dy - 20;
  const scrapCount = totalOver(stage, "scrap");
  arrow(svg, [[x + w, y + h - 10], [x + SINK.dx - 2, scrapY + SINK.h / 2]], "scrap",
    transitionTip("Scrap", stage, (t) => t.scrap, scrapCount));
  box(svg, x + SINK.dx, scrapY, SINK.w, SINK.h, COLOUR.scrap, ["Scrap", fmtCount(scrapCount)],
    `Scrap: ${scrapCount.toFixed(1)} expected parts\nScrap probability ${fmtProb(stage.scrap_probability)}`);

  // One rework loop per Rework State: down into the Rework box, back up into the Stage.
  const reworkStates = Object.keys(stage.transitions).filter((s) => s !== "initial");
  reworkStates.forEach((state, j) => {
    const by = y + REWORK.dy + j * REWORK.gap;
    const bx = x + (w - REWORK.w) / 2;
    const count = totalOver(stage, "rework", (s) => s === state);
    const tip = transitionTip(`Rework → ${state}`, stage, (t) => t.rework[state] ?? 0, count);
    arrow(svg, [[x + 30, y + h], [x + 30, by - 2]], "rework", tip);
    arrow(svg, [[x + w - 30, by], [x + w - 30, y + h + 2]], "processing", `Reworked ${state} parts return to Stage ${i + 1}`);
    text(svg, x + 36, y + h + 22, `R ${fmtProb(stage.transitions.initial.rework[state] ?? 0)}`, { class: "label" });
    box(svg, bx, by, REWORK.w, REWORK.h, COLOUR.rework, [`Rework ${state}`], tip);
  });
  return y + REWORK.dy + Math.max(reworkStates.length, 1) * REWORK.gap;
}

function drawPassBars(svg, results, i, top, maxCount) {
  const stage = results.stages[i];
  const x0 = STAGE.x - 70 + i * COLUMN;
  const avail = COLUMN - 20;
  const groupW = avail / Math.max(stage.passes.length, 3);
  const barW = Math.min(30, groupW / 3.6);  // wide enough for a 4-digit count above each bar
  const base = top + BARS_H + 20;
  const scale = BARS_H / Math.max(maxCount, 1);

  text(svg, x0, top, `Stage ${i + 1}: expected parts per Pass`, { "font-weight": 600 });
  el("line", { x1: x0, x2: x0 + avail, y1: base, y2: base, stroke: "var(--grid)" }, svg);

  stage.passes.forEach((pass, k) => {
    const gx = x0 + k * groupW + (groupW - 3 * barW) / 2;
    KINDS.forEach((kind, b) => {
      const count = sum(pass[kind]);
      if (Math.round(count) === 0) return;  // as in Fig 3.14, which draws no bar for under half a part
      const height = Math.max(count * scale, 1);
      const bx = gx + b * barW;
      const split = Object.entries(pass[kind])
        .map(([s, n]) => `  ${kind === "rework" ? "into" : "from"} ${s}: ${n.toFixed(1)} (p = ${fmtProb(n / results.n_parts)} of N)`)
        .join("\n");
      const g = el("g", { "data-tip": `${LETTER[kind]}^${passLabel(k)}:${count.toFixed(1)} expected parts\n${split}` }, svg);
      el("rect", { x: bx + 1, y: base - height, width: barW - 2, height, fill: COLOUR[kind] }, g);
      if (barW >= 12) {
        text(g, bx + barW / 2, base - height - 4, fmtCount(count), { "text-anchor": "middle", class: "label" });
        const label = text(g, bx + barW / 2, base + 14, LETTER[kind], { "text-anchor": "middle" });
        const sup = el("tspan", { "baseline-shift": "super", "font-size": "8" }, label);
        sup.textContent = passLabel(k);
      }
    });
    if (barW < 12) text(svg, gx + 1.5 * barW, base + 14, passLabel(k), { "text-anchor": "middle", class: "label" });
  });
  if (stage.remaining > 0) {
    text(svg, x0, base + 32, `${stage.remaining.toFixed(2)} expected parts still in rework after the last Pass`, { class: "label" });
  }
  return base + 40;
}

function legend(svg, y) {
  const items = [["conform", "Conform"], ["rework", "Rework"], ["scrap", "Scrap"], ["processing", "Processing"]];
  items.forEach(([kind, label], j) => {
    el("rect", { x: 20 + j * 110, y: y - 10, width: 12, height: 12, fill: COLOUR[kind] }, svg);
    text(svg, 38 + j * 110, y, label);
  });
}

export function drawDiagram(svg, sequence, results) {
  svg.replaceChildren();
  defs(svg);
  let flowBottom = 0;
  results.stages.forEach((_, i) => { flowBottom = Math.max(flowBottom, drawStage(svg, sequence, results, i)); });

  const maxCount = Math.max(...results.stages.flatMap((s) => s.passes.flatMap((p) => KINDS.map((k) => sum(p[k])))));
  let bottom = 0;
  results.stages.forEach((_, i) => { bottom = Math.max(bottom, drawPassBars(svg, results, i, flowBottom + 20, maxCount)); });
  legend(svg, bottom + 10);

  const width = STAGE.x + (results.stages.length - 1) * COLUMN + SINK.dx + SINK.w + 20;
  svg.setAttribute("viewBox", `0 0 ${Math.max(width, STAGE.x - 70 + results.stages.length * COLUMN)} ${bottom + 24}`);
}

export function attachTooltip(svg, tooltip) {
  const wrap = tooltip.parentElement;
  svg.addEventListener("mousemove", (event) => {
    const target = event.target.closest("[data-tip]");
    if (!target) { tooltip.hidden = true; return; }
    tooltip.textContent = target.dataset.tip;
    tooltip.hidden = false;
    const r = wrap.getBoundingClientRect();
    const left = Math.min(event.clientX - r.left + 12, r.width - tooltip.offsetWidth - 4);
    tooltip.style.left = `${Math.max(0, left)}px`;
    tooltip.style.top = `${event.clientY - r.top + 12}px`;
  });
  svg.addEventListener("mouseleave", () => { tooltip.hidden = true; });
}
