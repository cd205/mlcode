"""The OMS web API and page (web_app_plan.md §6). The engine runs here only, never in the browser (ADR 0005).

Run from web/ with:  uv run uvicorn app.main:app
"""

from __future__ import annotations

import json
import logging
from pathlib import Path
from typing import Any

from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, StrictFloat

from oms.formats import run

PRESETS = Path(__file__).resolve().parents[2] / "manufacturing_oms" / "presets"
STATIC = Path(__file__).resolve().parents[1] / "static"

log = logging.getLogger(__name__)
app = FastAPI(title="OMS sequence builder")


# Errors (C18): schema errors and engine ValueErrors are 422 with a readable message; anything else is a
# generic 500, with the traceback only in the server log. No response ever carries a traceback (ADR 0005).

@app.exception_handler(RequestValidationError)
def _schema_error(request: Request, error: RequestValidationError) -> JSONResponse:
    messages = []
    for e in error.errors():
        if e["type"] == "json_invalid":
            messages.append("the request body is not valid JSON")
            continue
        path = ".".join(str(part) for part in e["loc"] if part != "body")
        messages.append(f"{path}: {e['msg']}" if path else e["msg"])
    return JSONResponse({"detail": "; ".join(messages)}, status_code=422)


@app.exception_handler(Exception)
def _unexpected_error(request: Request, error: Exception) -> JSONResponse:
    log.error("unexpected error on %s %s", request.method, request.url.path, exc_info=error)
    return JSONResponse({"detail": "Something went wrong on the server."}, status_code=500)


class EvaluateRequest(BaseModel):
    """The request envelope. The sequence itself is checked by `oms.formats.load_sequence`, which names the bad field."""

    sequence: dict[str, Any]
    n_parts: StrictFloat = 10_000  # strict: ints are fine, but no true -> 1 or "500" -> 500


def _presets() -> dict[str, Path]:
    return {path.stem: path for path in sorted(PRESETS.glob("*.json"))}


def _read(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))  # type: ignore[no-any-return]


def _describe(preset: dict[str, Any]) -> str:
    """A one-line description from the preset's reference, e.g. "Fig 3.12: final_conformance 0.97672"."""
    reference = preset.get("reference")
    if reference is None:
        return ""
    return f"{reference['source']}: {reference['quantity']} {reference['value']}"


@app.get("/api/presets")
def list_presets() -> list[dict[str, str]]:
    presets = ((preset_id, _read(path)) for preset_id, path in _presets().items())
    return [{"id": preset_id, "name": p.get("name", preset_id), "description": _describe(p)}
            for preset_id, p in presets]


@app.get("/api/presets/{preset_id}")
def get_preset(preset_id: str) -> dict[str, Any]:
    path = _presets().get(preset_id)
    if path is None:
        raise HTTPException(404, f"no preset {preset_id!r}")
    return _read(path)


@app.post("/api/evaluate")
def evaluate(request: EvaluateRequest) -> dict[str, Any]:
    try:
        return run(request.sequence, action="evaluate", n_parts=request.n_parts)
    except ValueError as error:  # only the engine's ValueErrors are the user's to fix
        raise HTTPException(422, str(error)) from error


app.mount("/", StaticFiles(directory=STATIC, html=True), name="page")  # last, so /api/* routes match first
