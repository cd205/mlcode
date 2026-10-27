# OMS Web App: Prototype Plan

Status: **approved 2026-10-27** (W0 done in a grilling session). Nothing in this plan is built yet. Work through
the §8 tickets (#23–#33), blockers first. Each ticket ends with green `uv run pytest` and something you can run.

This plan builds on:
- [GLOSSARY.md](../GLOSSARY.md): use the terms exactly as defined (Stage, Feature, Parallel, Serial, Rework
  State, Mean Settings, Pass, …).
- [spec.md](spec.md): the engine, its reference cases R1–R9 (§6) and the future-extensions rule (§9: each
  extension needs its own spec; this is that spec for the web app).
- [ADR 0005](adr/0005-engine-runs-server-side-only.md): the engine runs on the server only.
- The notebooks in `notebooks/`, which already show the figures the web app should offer.

---

## 1. Goal

A website where anyone can **build their own manufacturing sequence point-and-click** (add Stages, add Features
to a Stage, set limits, variation and costs) or **start from a thesis preset** (R1–R9), then:

- evaluate it at given Mean Settings, or optimise the Mean Settings;
- see a **flow diagram** in the style of thesis Figs 3.3, 3.5, 3.12, 3.14 and 3.16: Stage boxes, rework loops,
  Conform and Scrap sinks, and per-Pass bars (C^I, C^II, …; R^I, …; S^I, …) for N parts started;
- see the Expected Profit, cost breakdown and Final Conformance.

**First milestone: a local prototype** (W1–W4). Hosting comes later (W5) and is out of scope until the
prototype has been used.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| C1 | **The `oms` code stays private.** Python runs only on the server; the browser gets inputs and results, never code. Pyodide is ruled out (ADR 0005). | The user wants others to use the model without exposing the thesis code. |
| C2 | One **JSON sequence format** is the contract between the UI, the API, the presets and the engine. | Changing the UI later doesn't touch the rest. |
| C3 | The UI edits an **ordered list of Stages**, not a free-form graph. | A Sequence is always a straight chain (GLOSSARY: Parallel does not mean branching; spec §9 lists branching as a future extension). |
| C4 | The diagram is drawn **in the browser as SVG** from the results JSON. | Hover shows numbers; no plotting code on the server. |
| C5 | The prototype backend is **FastAPI**, which also serves the page. | Python, so it calls `oms` directly; one process to run locally; easy to put in a container later. |
| C6 | The format lives in **`oms.formats`** (`load_sequence`, `dump_sequence`, `run`); presets in `manufacturing_oms/presets/`; the web app in `web/` as its own uv project. | "spec" already means `docs/spec.md` and Specification Limits. The engine gains no web dependencies. |
| C7 | **State keys** are `"initial"` and Feature names joined by `+` (`"a+b"`). Feature names match `[A-Za-z0-9_]{1,16}`. Parsing ignores order; writing uses Feature order. | Readable, and the name rule means `+` can't clash. |
| C8 | A Stage's `costs` take **either** `rework_per_feature` + `scrap_per_feature` (→ `CostTable.additive`) **or** the full state tables, never both. `dump_sequence` always writes full tables. | Users needn't type a cost for every state; dumped files are explicit. |
| C9 | **Scrap Cost is stored cumulative**, as the glossary defines it. The builder labels the field "Scrap Cost (includes value added in earlier Stages)" and shows the earlier Stages' Processing Costs as a hint; it never adds them up silently. | Keeps the modelling choice visible (ADR 0001, A6). |
| C10 | `means.scheme` is any of `per_feature` / `per_group_size` / `per_state`, and *Optimise* uses it. The builder edits `per_feature` values only. A preset with another scheme shows its means read-only until the user optimises or switches to `per_feature`. | Presets R6, R7 and R9 need the other schemes; the builder stays simple. |
| C11 | The builder offers **Normal variation only**: one σ per Feature and a scalar correlation per Stage. A correlation matrix, or `gaussian_copula` variation, comes only through preset or uploaded JSON and shows read-only. Copula marginals are limited to an allow-list of SciPy names. | R9 still runs; the builder stays simple; no arbitrary SciPy names. |
| C12 | **N parts** scales expected counts: per-Pass counts are N · probabilities, returned as floats and rounded only for display. No Monte Carlo in the results. | Matches Fig 3.14 and keeps results exact. |
| C13 | **One preset per printed result**: `r1`, `r2`, `r3`, `r4`, `r5`, `r6-per-feature`, `r6-per-group-size`, `r7-pos-per-feature`, `r7-pos-per-group-size`, `r7-neg-per-feature`, `r7-neg-per-group-size`, `r8-seq1` … `r8-seq8`, `r9`. | Every preset has one Sequence, one means block and one reference. R8 is a search over 8 Sequences, so it becomes 8 presets; a search endpoint is a W5 follow-up. |
| C14 | **Economics are always required.** R1 (probabilities only) uses Selling Price and costs of 0. `reference` names the quantity it checks (`expected_profit`, `final_conformance`, `production_cost`) and also carries a `tolerance` (from the printed precision) and an optional `note` (e.g. discrepancy D1, D10). The UI and the W1 tests use the same tolerance. | One source of truth for "engine vs thesis". |
| C15 | **Optimise** takes only `objective` (`expected_profit` \| `production_cost`). Bounds, `n_starts` = 8 and seed = 0 are the engine defaults. The response echoes the full optimiser record (method, bounds, starts, evaluations, success). | Small surface for v1; more options can follow W4. |
| C16 | After *Optimise*, the optimised Mean Settings **replace** the sequence's `means` (same scheme). The previous means are kept in one undo slot. | *Evaluate* and *Download* then use what was just found. |
| C17 | **Builder defaults** for a new Feature: next unused name `f1`, `f2`, …; L=8, U=12; Rework Side `upper`; σ=1; rework and scrap cost 0; Mean Setting (L+U)/2, which follows L and U until the user types a mean. | *Evaluate* works straight after *Add Feature*. |
| C18 | Engine `ValueError`s return **422** with their message, the same as schema errors. Any other exception returns a 500 with a generic message, and the traceback goes only to the server log. | Readable errors; no code leaks (ADR 0005). |

Privacy in practice: the GitHub repo `cd205/mlcode` must stay private (or `oms` moves to a private package if the
web code is ever made public); API errors never return Python tracebacks.

## 3. Layout

```
manufacturing_oms/
  src/oms/formats/       NEW (W1): sequence format <-> oms objects, run(), results JSON. No web dependencies.
  presets/               NEW (W1): r1.json, r2.json, ..., r8-seq8.json, r9.json (C13)
  test_and_checks/       + tests for the format, presets and per-Pass counts
web/                     NEW (W2): its own uv project; depends on ../manufacturing_oms by path
  pyproject.toml         fastapi, uvicorn, oms (path dependency)
  app/main.py            API + serves static/
  static/index.html      W3: builder + diagram (plain HTML/JS/SVG, no build step)
  tests/
```

## 4. Sequence format

R4 (one Parallel Stage, two Features), with full cost tables (C8):

```json
{
  "format_version": 1,
  "name": "R4: Table 3.7, two Features in parallel",
  "selling_price": 120,
  "stages": [
    {
      "features": [
        {"name": "a", "lower": 8, "upper": 12, "rework_side": "upper"},
        {"name": "b", "lower": 13, "upper": 17, "rework_side": "upper"}
      ],
      "variation": {"type": "normal", "sigmas": [1, 1], "corr": 0},
      "costs": {
        "processing": 45,
        "rework": {"a": 15, "b": 12, "a+b": 27},
        "scrap": {"initial": 27, "a": 27, "b": 27, "a+b": 27}
      },
      "inspection": {"per_stage": 0, "per_feature": 0}
    }
  ],
  "means": {"scheme": "per_feature", "values": [{"a": 10.537, "b": 15.590}]},
  "reference": {"source": "Table 3.7", "quantity": "expected_profit", "value": 71.17, "tolerance": 0.005}
}
```

R5 (two Serial Stages) is the same shape with two entries in `stages`, one Feature each.

- **Features**: names match `[A-Za-z0-9_]{1,16}` and are unique across the Sequence; `rework_side` is
  `upper`, `lower` or `none` (C7).
- **States**: `"initial"` and `+`-joined Feature names; parsing ignores order (C7).
- **Costs**: full tables as above, or `{"processing", "rework_per_feature", "scrap_per_feature"}`; Scrap Costs
  are cumulative (C8, C9).
- **Variation**: `normal` (sigmas, corr scalar or matrix) or `gaussian_copula` (marginals by allow-listed SciPy
  name and parameters, centred on 0 as in ADR 0004, plus corr) (C11).
- **Means**: `scheme` plus one entry per Stage, in the shape that scheme needs (C10).
- **`reference`**: optional; `source`, `quantity`, `value`, `tolerance`, optional `note` (C14).

## 5. Results format and per-Pass counts

`oms.formats.run(sequence_json, action="evaluate" | "optimise", objective=..., n_parts=10000)` returns JSON with:

- the Mean Settings used (optimised or given), and for *Optimise* the optimiser record (C15);
- the Sequence totals from `ProfitBreakdown`: Expected Profit, revenue, Final Conformance, processing, scrap,
  rework and Inspection Costs, production cost;
- for each Stage: Reach Probability, `final_conformance`, `scrap_probability`, `visits` by state, the
  transition probabilities from each state, and the **per-Pass counts** below;
- the reference check when the sequence has a `reference` (C14).

**Per-Pass counts** (what the thesis bars show; expected counts, C12). For Stage i, start with
v₁ = {initial: N · rᵢ} parts, where rᵢ is the Reach Probability. For Pass k = 1, 2, …:

- conform_k[s] = v_k[s] · p_{s,C} (C^k, split by the state the parts came from)
- scrap_k[s] = v_k[s] · p_{s,X} (S^k)
- v_{k+1}[d] = Σ_s v_k[s] · p_{s→d} (R^k, split by the Rework State entered)

Stop when fewer than 0.5 expected parts remain in Rework States, or after 20 Passes. Anything left at the cap
is reported as `remaining`. The checks: Σ_k conform + Σ_k scrap + remaining = N · rᵢ, and Σ_k conform
→ N · rᵢ · f_C as remaining → 0.

**Acceptance against the thesis (W1):** R1 (μ=5, σ=1, [3, 7], Rework Side above U) with N = 10 000 must give
C = 9545, 217, 5; R = 228, 5; S = 228, 5, as printed in Fig 3.14. Figs 3.15 and 3.16 (two Stages; two Features
with Rework Stations, C^I = 6449) use inputs not yet identified; finding them is W-U1.

## 6. API (W2)

| Method | Path | Does |
|---|---|---|
| GET | `/api/presets` | list of presets: id, name, short description |
| GET | `/api/presets/{id}` | one preset's sequence JSON |
| POST | `/api/evaluate` | sequence (with means) → results |
| POST | `/api/optimise` | sequence + objective → optimised means and results |
| GET | `/` | the builder page |

Request checks, before any engine call: schema validation with clear messages (Pydantic); limits of at most 6
Stages, at most 4 Features per Stage and N ≤ 100 000 (tunable); a time limit per request. Errors as in C18.

## 7. Builder page (W3)

One page, plain HTML + JavaScript modules + SVG, no build tooling (a framework can come later if the page
outgrows it):

- **Left panel**: preset dropdown; the Stage list with *Add Stage*, delete and move up/down; in each Stage, a
  Feature table (name, L, U, Rework Side, σ, Mean Setting) with *Add Feature* (defaults C17), the
  correlation, and the cost table (per-Feature shortcut or full table; Scrap Cost labelled as cumulative, C9);
  selling price; N parts. Preset-only settings (other schemes, matrix correlation, copula) show read-only
  (C10, C11).
- **Main panel**: *Evaluate* and *Optimise* buttons (objective choice; undo after *Optimise*, C16); the flow
  diagram; a results table (Expected Profit, production cost split, Final Conformance, means); "engine vs
  thesis" with ✓ or the gap when a preset has a reference (C14).
- **Diagram**: Stages left to right, joined by the conforming flow; for a multi-Feature Stage, one Rework box per
  Rework State (Fig 3.5); for a single Feature, a rework loop (Fig 3.12); Conform and Scrap sinks; per-Pass bars
  beside each Stage. Colours as in the notebooks: aqua = conform, blue = rework, orange = scrap, grey =
  processing. Hover shows counts and probabilities.
- The edited sequence can be downloaded and uploaded as JSON.

## 8. Staged plan

**W0: Agree the open decisions (no code).** *Done 2026-10-27*: §2 C6–C18, ADR 0005, and the glossary term Pass.

**W1–W4: the prototype, as vertical-slice tickets.** Each ticket cuts through the format, `run()`, the API and
the page, so it can be shown working on its own. The acceptance criteria are in the issues. The format grows
ticket by ticket; together the tickets cover every preset (C13) and every §5–§7 item.

| Issue | Ticket | Blocked by |
|---|---|---|
| #23 | 1a: sequence format, `run()` and per-Pass counts for R1 (tests and an example script, no web) | – |
| #24 | 1b: R1 in the browser: `web/`, presets and evaluate endpoints, page, diagram, errors (C18) | #23 |
| #25 | 2: Serial Sequences (R2, R5); multi-Stage diagram | #24 |
| #26 | 3: Parallel Stages and Rework States (R3, R4); state keys, cost shortcut | #24 |
| #27 | 4: Optimise Mean Settings, with undo | #24 |
| #28 | 5: other tying schemes (R6, R7: 6 presets); read-only means | #26, #27 |
| #29 | 6: R8 Inspection placements (8 presets) | #26 |
| #30 | 7: copula Process Variation (R9) | #28 |
| #31 | 8: builder editing; download and upload | #26 |
| #32 | 9: request limits and timing (W-U4) | #27, #29 |
| #33 | 10: prototype review (human), with W-U1 | #25, #28–#32 |

These replace the earlier layer-by-layer issues #18–#21.

**W5 (later, own plan): hosting.**
- Long jobs (`search_sequences`, copula Monte Carlo) run in a background job queue that the page polls.
- A sequence-search request type and `/api/search` endpoint for the R8 study (C13).
- Container image; a host such as Render, Fly.io or Azure App Service; HTTPS; rate limiting; logging without
  user data.
- Accounts and saved sequences only if needed.

## 9. Open unknowns

- **W-U1 (#33):** the inputs behind Figs 3.15 and 3.16 (the second Stage's Feature, and the two-Feature case with
  C^I = 6449), so those diagrams can also be checked.
- **W-U4 (#32):** request time limit and size limits; measure `optimise_means` on the largest allowed sequence.

Resolved at W0: W-U2 (C10), W-U3 (C11, C13), W-U5 (C7).

## 10. Starting a new session

1. Read `GLOSSARY.md`, `docs/spec.md` §2, §5 and §6, ADR 0005, and this document.
2. Run `uv run pytest` in `manufacturing_oms/` to confirm a green baseline.
3. Pick the next ticket from §8 whose blockers are all closed (#23 first).
