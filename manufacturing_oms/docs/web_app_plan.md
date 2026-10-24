# OMS Web App: Prototype Plan

Status: **draft 2026-10-24, not yet approved.** Nothing in this plan is built. Start at **W0** (agree the open
decisions), then work through W1–W4 in order. Each stage ends with green `uv run pytest` and something you can
run.

This plan builds on:
- [GLOSSARY.md](../GLOSSARY.md): use the terms exactly as defined (Stage, Feature, Parallel, Serial, Rework
  State, Mean Settings, …).
- [spec.md](spec.md): the engine, its reference cases R1–R9 (§6) and the future-extensions rule (§9: each
  extension needs its own spec; this is that spec for the web app).
- The notebooks in `notebooks/`, which already show the figures the web app should offer.

---

## 1. Goal

A website where anyone can **build their own manufacturing sequence point-and-click** (add Stages, add Features
to a Stage, set limits, variation and costs) or **start from a thesis preset** (R1–R9), then:

- evaluate it at given Mean Settings, or optimise the Mean Settings;
- see a **flow diagram** in the style of thesis Figs 3.3, 3.5, 3.12, 3.14 and 3.16: Stage boxes, rework loops,
  Conform and Scrap sinks, and per-pass bars (C^I, C^II, …; R^I, …; S^I, …) for N parts started;
- see the Expected Profit, cost breakdown and Final Conformance.

**First milestone: a local prototype** (W1–W4). Hosting comes later (W5) and is out of scope until the
prototype has been used.

## 2. Constraints and decisions so far

| # | Decision | Why |
|---|---|---|
| C1 | **The `oms` code stays private.** Python runs only on the server; the browser gets inputs and results, never code. Pyodide (Python in the browser) is ruled out. | The user wants others to use the model without exposing the thesis code. |
| C2 | One **JSON sequence format** is the contract between the UI, the API, the presets and the engine. | Changing the UI later doesn't touch the rest. |
| C3 | The UI edits an **ordered list of Stages**, not a free-form graph. | A Sequence is always a straight chain (GLOSSARY: Parallel does not mean branching; spec §9 lists branching as a future extension). |
| C4 | The diagram is drawn **in the browser as SVG** from the results JSON. | Hover shows numbers; no plotting code on the server. |
| C5 | The prototype backend is **FastAPI**, which also serves the page. | Python, so it calls `oms` directly; one process to run locally; easy to put in a container later. |

Privacy in practice: the GitHub repo `cd205/mlcode` must stay private (or `oms` moves to a private package if the
web code is ever made public); API errors never return Python tracebacks.

## 3. Proposed layout

```
manufacturing_oms/
  src/oms/spec/          NEW (W1): sequence format <-> oms objects, run(), results JSON. No web dependencies.
  presets/               NEW (W1): r1.json ... r9.json
  test_and_checks/       + tests for the format, presets and per-pass counts
web/                     NEW (W2): its own uv project; depends on ../manufacturing_oms by path
  pyproject.toml         fastapi, uvicorn, oms (path dependency)
  app/main.py            API + serves static/
  static/index.html      W3: builder + diagram (plain HTML/JS/SVG, no build step)
  tests/
```

Keeping the format in `oms.spec` means notebooks and tests can use it too; keeping FastAPI in `web/` means the
engine never gains web dependencies. **Confirm at W0.**

## 4. Sequence format (draft, settle at W0)

R4 (one Parallel Stage, two Features):

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
  "reference": {"source": "Table 3.7", "expected_profit": 71.17}
}
```

R5 (two Serial Stages) is the same shape with two entries in `stages`, one Feature each.

Points to settle:
- **State keys**: `"initial"` and Feature names joined by `+`, in Feature order. Alternative: a list of
  `{"features": [...], "cost": x}` entries, which avoids parsing.
- **Cost shortcuts**: allow `"rework_per_feature"` / `"scrap_per_feature"` (maps to `CostTable.additive`) so a
  user doesn't type a cost for every state; the full table stays available.
- **Variation types**: `normal` (sigmas, corr scalar or matrix) and `gaussian_copula` (marginals by SciPy name
  and parameters, plus corr) so R9 fits. Restrict the marginals to a short allow-list, never arbitrary names.
- **Means**: `per_feature` is enough for the builder; `per_group_size` / `per_state` are needed for R6, R7, R9.
- **`reference`**: optional; presets carry the thesis value so the UI and tests can show "engine vs thesis".

## 5. Results format and per-pass counts

`oms.spec.run(spec, action="evaluate" | "optimise", objective=..., n_parts=10000)` returns JSON with:

- the Mean Settings used (optimised or given), and the optimiser record (method, starts, success);
- the Sequence totals from `ProfitBreakdown`: Expected Profit, revenue, Final Conformance, processing, scrap,
  rework and Inspection Costs, production cost;
- for each Stage: reach probability, `final_conformance`, `scrap_probability`, `visits` by state, the
  transition probabilities from each state, and the **per-pass counts** below.

**Per-pass counts** (what the thesis bars show). For Stage i, start with v₁ = {initial: N · rᵢ} parts, where rᵢ
is the reach probability. For pass k = 1, 2, …:

- conform_k[s] = v_k[s] · p_{s,C} (C^k, split by the state the parts came from)
- scrap_k[s] = v_k[s] · p_{s,X} (S^k)
- v_{k+1}[d] = Σ_s v_k[s] · p_{s→d} (R^k, split by the Rework State entered)

Stop when fewer than 0.5 parts remain, or at a maximum pass count. The checks: Σ_k conform equals N · rᵢ · f_C
and Σ_k (conform + scrap) equals N · rᵢ.

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
Stages, at most 4 Features per Stage and N ≤ 100 000 (tunable); a time limit per request; no tracebacks in
responses.

## 7. Builder page (W3)

One page, plain HTML + JavaScript modules + SVG, no build tooling (a framework can come later if the page
outgrows it):

- **Left panel**: preset dropdown; the Stage list with *Add Stage*, delete and move up/down; in each Stage, a
  Feature table (name, L, U, Rework Side, sigma), the correlation, and the cost table (per-Feature shortcut or
  full table); selling price; N parts.
- **Main panel**: *Evaluate* and *Optimise* buttons; the flow diagram; a results table (Expected Profit,
  production cost split, Final Conformance, means); "engine vs thesis" when a preset has a reference value.
- **Diagram**: Stages left to right, joined by the conforming flow; for a multi-Feature Stage, one Rework box per
  Rework State (Fig 3.5); for a single Feature, a rework loop (Fig 3.12); Conform and Scrap sinks; per-pass bars
  beside each Stage. Colours as in the notebooks: aqua = conform, blue = rework, orange = scrap, grey =
  processing. Hover shows counts and probabilities.
- The edited sequence can be downloaded and uploaded as JSON.

## 8. Staged plan

**W0: Agree the open decisions (no code).**
- Settle §3 layout and §4 format, and W-U2 to W-U5 below. A `/grilling` session is a good way to do it.
- *Exit:* this document approved, with the decisions written into §2.

**W1: Sequence format, presets and results (`oms.spec`).**
- Parse and validate the format into `Sequence` + `MeanSettings`; serialise back (round-trip).
- `run()` returning the §5 results, including per-pass counts.
- `presets/r1.json` … `r9.json` with their thesis reference values.
- *Exit:* tests that every preset reproduces its spec §6 value through `run()`; round-trip tests; R1 per-pass
  counts match Fig 3.14; per-pass sums match f_C and the scrap probability on R1–R8.
- *Example:* a notebook cell or script that loads a preset and prints the results.

**W2: FastAPI backend (`web/`).**
- The §6 endpoints, request checks and limits.
- *Exit:* API tests with FastAPI's test client (every preset through `/api/evaluate`; a malformed request gives
  a 422 with a readable message and no traceback). `uv run uvicorn app.main:app` serves it locally.

**W3: Builder page.**
- The §7 page served from `/`.
- *Exit:* in a browser, load each preset, evaluate and optimise it, add and remove Stages and Features, and see
  the diagram update. R1's diagram shows the Fig 3.14 numbers.

**W4: Prototype review.**
- Use it, list what's missing, decide whether to go on to hosting and whether a frontend framework is needed.
- *Exit:* a short list of follow-up issues.

**W5 (later, own plan): hosting.**
- Long jobs (`search_sequences`, copula Monte Carlo) run in a background job queue that the page polls.
- Container image; a host such as Render, Fly.io or Azure App Service; HTTPS; rate limiting; logging without
  user data.
- Accounts and saved sequences only if needed.

## 9. Open unknowns

- **W-U1 (W1):** the inputs behind Figs 3.15 and 3.16 (the second Stage's Feature, and the two-Feature case with
  C^I = 6449), so those diagrams can also be checked.
- **W-U2 (W0):** which tying schemes the builder offers. Proposal: `per_feature` in the builder; presets may
  carry any scheme.
- **W-U3 (W0):** does v1 offer sequence search (R8, `search_sequences`) and copulas (R9)? Proposal: both run as
  presets; the builder offers Normal variation only at first.
- **W-U4 (W2):** request time limit and size limits; measure `optimise_means` on the largest allowed sequence.
- **W-U5 (W0):** the state-key style in §4.

## 10. Starting a new session

1. Read `GLOSSARY.md`, `docs/spec.md` §2, §5 and §6, and this document.
2. Run `uv run pytest` in `manufacturing_oms/` to confirm a green baseline.
3. Begin W0 with the user; do not start W1 code until §2 and §4 are agreed.
