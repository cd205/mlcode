# OMS web app (local prototype)

The sequence builder from [web_app_plan.md](../manufacturing_oms/docs/web_app_plan.md). FastAPI serves the API and
the page; the `oms` engine runs only here, never in the browser (ADR 0005).

```
uv run uvicorn app.main:app      # then open http://127.0.0.1:8000
uv run pytest
uv run mypy
```

| Method | Path | Does |
|---|---|---|
| GET | `/api/presets` | `[{id, name, description}]` from `manufacturing_oms/presets/` |
| GET | `/api/presets/{id}` | one preset's sequence JSON |
| POST | `/api/evaluate` | `{"sequence": {...}, "n_parts": 10000}` → results JSON (`oms.formats.run`) |
| GET | `/` | the page (`static/`) |

Pydantic checks the request envelope; the sequence itself is checked by `oms.formats.load_sequence`, whose
errors name the bad field (e.g. `stages[0].features[1].lower`). There is one schema, in `oms.formats`.

Errors (C18): schema errors and engine `ValueError`s are 422 with a readable `detail` string; anything else is a
500 with a generic message, and the traceback goes to the server log only.
