# OMS case studies

Reproducible applications of OMS to public manufacturing datasets, chosen from
[docs/agents/oms_public_manufacturing_datasets.md](../docs/agents/oms_public_manufacturing_datasets.md).
They show *when and why* an OMS recommendation differs from centring, not verified savings: none of these
datasets carries real cost, scrap or rework records, so every cost is a labelled hypothesis.

| Case study | Data | Status |
|---|---|---|
| [piston_rings](piston_rings/) | qcc `pistonrings`: 200 inside diameters, one Feature | first |

## Layout of a case study

Each folder has the same parts, so a report, an article and the web app can all draw on one run:

- `data/`: the original file, unchanged, and `PROVENANCE.md` (source, licence, checksum, what is real and what is assumed).
- `run_case_study.py`: the whole analysis, deterministic (fixed seeds). It writes:
  - `output/results.json`: every number the report or an article quotes. Quote from here, never retype.
  - `output/figures/*.png`: the figures, in a fixed light palette, sized for an article column.
  - `output/report.md`: the technical write-up, generated from `results.json`.
  - `manufacturing_oms/presets/cs-*.json`: the web app presets, so a reader can load the case study and press Optimise.
    Their reference values come from the case study's closed form, so the web app's ✓ checks the engine against it.

## Running

From `case_studies/`:

```
uv run python piston_rings/run_case_study.py
uv run pytest
```
