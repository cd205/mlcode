// The sequence chain (web_app_plan.md C26, §7.1): the Sequence list as a process diagram, Operation boxes and
// Inspection diamonds joined by arrows, with a "Stage n · Serial/Parallel" bracket under each Stage. Drawn from the
// Builder's rows on every edit, without the server. Unclosed Operations and Stages with a problem are drawn as they
// are, in the warning colour, so the list's warnings have a visible cause.

import { el, text } from "./diagram.js";

const GAP = 30;                         // arrow between items
const OP = { h: 36, minW: 60, charW: 7.5, padW: 20 };
const DIAMOND = 44;
const TOP = 14, MID = TOP + DIAMOND / 2;
const BRACKET = { y: TOP + DIAMOND + 10, tick: 6, label: 16, charW: 6.4 };  // charW: of an 11px label
const HEIGHT = BRACKET.y + BRACKET.label + 10;
const MIN_SCALE = 0.75;                 // as the OMS diagram: below this the chain scrolls sideways

// A group that selects its row when clicked, or on Enter or Space.
function selectable(svg, key, label, onSelect) {
  const g = el("g", { class: "chain-item", tabindex: 0, role: "button", "aria-label": label, "data-key": key }, svg);
  el("title", {}, g).textContent = label;
  g.addEventListener("click", () => onSelect(key));
  g.addEventListener("keydown", (event) => {
    if (event.key !== "Enter" && event.key !== " ") return;
    event.preventDefault();
    onSelect(key);
  });
  return g;
}

const itemWidth = (r) => (r.kind === "operation" ? Math.max(OP.minW, r.name.length * OP.charW + OP.padW) : DIAMOND);

function arrow(svg, from, to) {
  el("line", { x1: from + 2, y1: MID, x2: to - 2, y2: MID, stroke: "var(--ink)", "stroke-width": 1.5,
    "marker-end": "url(#chain-head)" }, svg);
}

// An Operation box, dashed while unclosed, or an Inspection diamond.
function drawItem(svg, r, x, w, { warn, selected, keyOf, onSelect }) {
  const key = keyOf(r);
  const cls = `shape${selected === key ? " selected" : ""}${warn ? " warn" : ""}`;
  if (r.kind === "operation") {
    const g = selectable(svg, key, r.closed ? `Operation ${r.name}, Stage ${r.stage + 1}`
      : `Operation ${r.name}, unclosed: no Inspection after it`, onSelect);
    el("rect", { x, y: MID - OP.h / 2, width: w, height: OP.h, rx: 5, class: cls, fill: "var(--processing)",
      ...(r.closed ? {} : { "stroke-dasharray": "5 3" }) }, g);
    text(g, x + w / 2, MID + 4, r.name, { "text-anchor": "middle" });
  } else {
    const half = DIAMOND / 2;
    const g = selectable(svg, key, r.label, onSelect);
    el("path", { d: `M${x},${MID} L${x + half},${TOP} L${x + w},${MID} L${x + half},${TOP + DIAMOND} z`,
      class: cls, fill: "var(--bg)" }, g);
  }
}

// `keyOf(row)` names a row as the list does; `onSelect(key)` opens it there. `selected` is the open row's key.
export function drawChain(svg, rows, { problems, selected, keyOf, onSelect }) {
  svg.replaceChildren();
  const defs = el("defs", {}, svg);
  const marker = el("marker", { id: "chain-head", viewBox: "0 0 10 10", refX: 9, refY: 5,
    markerWidth: 6, markerHeight: 6, orient: "auto" }, defs);
  el("path", { d: "M0,0 L10,5 L0,10 z", fill: "var(--ink)" }, marker);

  // A Stage with a problem is marked, all its items and its bracket: its warning shows by one of its rows (an
  // unclosed Stage's, by its first).
  const warned = new Set(problems.map((p) => rows[p.row]?.stage).filter((i) => i !== undefined));
  const groups = [];  // each Stage's rows, in order; the list keeps a Stage's rows together
  for (const r of rows) {
    if (groups.at(-1)?.stage !== r.stage) groups.push({ stage: r.stage, rows: [] });
    groups.at(-1).rows.push(r);
  }
  if (!rows.length) text(svg, 10, MID + 4, "Add an Operation to start the chain.", { class: "label" });

  // Each Stage is a block at least as wide as its bracket's label, its items centred in it.
  let x = 10;
  let previousEnd = null;  // where the previous Stage's last item ends
  groups.forEach((group) => {
    const { stage: i } = group;
    const inspection = group.rows.find((r) => r.kind === "inspection");
    const label = inspection ? `Stage ${i + 1} · ${inspection.shape}` : "unclosed: add an Inspection";
    const widths = group.rows.map(itemWidth);
    const span = widths.reduce((a, b) => a + b, 0) + GAP * (widths.length - 1);
    const block = Math.max(span, label.length * BRACKET.charW);
    const left = x + (block - span) / 2, end = left + span;
    if (previousEnd !== null) arrow(svg, previousEnd, left);
    let itemX = left;
    group.rows.forEach((r, k) => {
      if (k > 0) arrow(svg, itemX - GAP, itemX);
      drawItem(svg, r, itemX, widths[k], { warn: warned.has(i), selected, keyOf, onSelect });
      itemX += widths[k] + GAP;
    });
    previousEnd = end;

    const bracket = el("g", { class: `bracket${warned.has(i) ? " warn" : ""}` }, svg);
    const { y, tick } = BRACKET;
    el("path", { d: `M${left},${y - tick} L${left},${y} L${end},${y} L${end},${y - tick}`, fill: "none",
      ...(inspection ? {} : { "stroke-dasharray": "5 3" }) }, bracket);
    text(bracket, x + block / 2, y + BRACKET.label - 2, label, { "text-anchor": "middle", class: "label" });
    x += block + GAP;
  });

  const width = Math.ceil(Math.max(x - GAP + 10, 200));
  svg.setAttribute("viewBox", `0 0 ${width} ${HEIGHT}`);
  svg.style.maxWidth = `${width}px`;
  svg.style.minWidth = `${Math.round(width * MIN_SCALE)}px`;
}
