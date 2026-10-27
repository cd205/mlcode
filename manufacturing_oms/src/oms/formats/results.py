"""run(): evaluate sequence JSON and report results JSON (web_app_plan.md §5)."""

from __future__ import annotations

from collections import defaultdict
import math
from typing import Literal

from oms.economics.sequence import ProfitBreakdown, evaluate_sequence
from oms.economics.stage import StageResult
from oms.formats.sequence_format import (
    Json, LoadedSequence, Reference, dump_means, dump_reference, load_sequence, state_key,
)
from oms.markov.states import INITIAL_STATE, State

Action = Literal["evaluate"]

STOP_BELOW_PARTS = 0.5  # stop the Passes once fewer expected parts than this are left in Rework States
MAX_PASSES = 20


def run(sequence_json: object, action: Action = "evaluate", *, n_parts: float = 10_000) -> Json:
    """Evaluate a sequence at its Mean Settings and report it for `n_parts` parts started.

    Counts are expected counts, N times a probability, left unrounded (C12).
    """
    if action != "evaluate":
        raise ValueError(f"action: only 'evaluate' is supported, got {action!r}")
    if isinstance(n_parts, bool) or not isinstance(n_parts, (int, float)) or not (0 < n_parts < math.inf):
        raise ValueError(f"n_parts: must be a positive finite number, got {n_parts!r}")
    loaded = load_sequence(sequence_json)
    breakdown = evaluate_sequence(loaded.sequence, loaded.means)
    results: Json = {
        "action": action,
        "n_parts": n_parts,
        "means": dump_means(loaded),
        "totals": _totals(breakdown),
        "stages": [_stage(loaded, i, breakdown, n_parts) for i in range(len(breakdown.stages))],
    }
    if loaded.reference is not None:
        results["reference"] = _reference_check(loaded.reference, breakdown)
    return results


def _totals(b: ProfitBreakdown) -> Json:
    return {
        "expected_profit": b.expected_profit,
        "revenue": b.revenue,
        "final_conformance": b.final_conformance,
        "processing_cost": sum(b.processing_costs),
        "scrap_cost": sum(b.scrap_costs),
        "rework_cost": sum(b.rework_costs),
        "production_cost": b.production_cost,
        "inspection_cost": b.inspection_cost,
        "expected_profit_after_inspection": b.expected_profit_after_inspection,
    }


def _stage(loaded: LoadedSequence, i: int, b: ProfitBreakdown, n_parts: float) -> Json:
    result = b.stages[i]
    names = loaded.sequence.stages[i].feature_names

    def keyed(values: dict[State, float]) -> dict[str, float]:
        return {state_key(s, names): v for s, v in values.items()}

    passes, remaining = _pass_counts(result, n_parts * b.reach_probabilities[i])
    return {
        "reach_probability": b.reach_probabilities[i],
        "final_conformance": result.final_conformance,
        "scrap_probability": result.scrap_probability,
        "visits": keyed(dict(result.visits)),
        "transitions": {
            state_key(s, names): {"conform": t.conform, "scrap": t.scrap, "rework": keyed(dict(t.rework))}
            for s, t in result.transitions.items()
        },
        "costs": {  # per part started, as in the totals
            "processing": b.processing_costs[i],
            "scrap": b.scrap_costs[i],
            "rework": b.rework_costs[i],
            "inspection": b.inspection_costs[i],
        },
        "passes": [{kind: keyed(counts) for kind, counts in p.items()} for p in passes],
        "remaining": remaining,
    }


def _pass_counts(result: StageResult, entering: float) -> tuple[list[dict[str, dict[State, float]]], float]:
    """Expected parts leaving each Pass Conforming, Scrapped or into each Rework State (§5).

    Conform and scrap are split by the state the parts came from, rework by the Rework State entered.
    Returns the Passes and the expected parts still in Rework States after the last one.
    """
    in_states: dict[State, float] = {INITIAL_STATE: entering}
    passes = []
    for _ in range(MAX_PASSES):
        rework: dict[State, float] = defaultdict(float)
        for s, n in in_states.items():
            for target, p in result.transitions[s].rework.items():
                rework[target] += n * p
        passes.append({
            "conform": {s: n * result.transitions[s].conform for s, n in in_states.items()},
            "scrap": {s: n * result.transitions[s].scrap for s, n in in_states.items()},
            "rework": dict(rework),
        })
        in_states = dict(rework)
        if sum(in_states.values()) < STOP_BELOW_PARTS:
            break
    return passes, sum(in_states.values())


def _reference_check(reference: Reference, breakdown: ProfitBreakdown) -> Json:
    computed = float(getattr(breakdown, reference.quantity))
    difference = computed - reference.value
    return {**dump_reference(reference), "computed": computed, "difference": difference,
            "within_tolerance": abs(difference) <= reference.tolerance}
