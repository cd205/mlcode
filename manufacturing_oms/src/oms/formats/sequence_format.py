"""The sequence format (web_app_plan.md §4): JSON <-> a Sequence, its Mean Settings and an optional reference.

Loading checks everything and raises `ValueError` naming the bad field, e.g. `stages[0].features[1].lower`.
"""

from __future__ import annotations

import math
import re
from collections.abc import Callable, Collection, Mapping
from dataclasses import dataclass
from typing import Any, Literal, TypeVar, get_args

from oms.distributions.normal import MultivariateNormal
from oms.markov.states import INITIAL_STATE, State
from oms.model.costs import CostTable, InspectionCost
from oms.model.feature import Feature, ReworkSide
from oms.model.means import MeanSettings
from oms.model.sequence import Sequence
from oms.model.stage import Stage

FORMAT_VERSION = 1
FEATURE_NAME = re.compile(r"[A-Za-z0-9_]{1,16}")
Quantity = Literal["expected_profit", "final_conformance", "production_cost"]  # ProfitBreakdown attributes
REFERENCE_QUANTITIES: tuple[Quantity, ...] = get_args(Quantity)
INITIAL_KEY = "initial"

Json = dict[str, Any]
T = TypeVar("T")


@dataclass(frozen=True)
class Reference:
    """A printed thesis result the sequence should reproduce, within `tolerance` (C14)."""

    source: str
    quantity: Quantity
    value: float
    tolerance: float
    note: str | None = None


@dataclass(frozen=True)
class LoadedSequence:
    """A sequence document as `oms` objects. `feature_means` holds the `per_feature` values, one dict per Stage."""

    name: str
    sequence: Sequence
    feature_means: tuple[Mapping[str, float], ...]
    reference: Reference | None = None

    @property
    def means(self) -> tuple[MeanSettings, ...]:
        return tuple(MeanSettings.per_feature(s, mu) for s, mu in zip(self.sequence.stages, self.feature_means))


def load_sequence(data: object) -> LoadedSequence:
    """Parse sequence JSON (already decoded) into `oms` objects."""
    doc = _object(data, "sequence", required={"format_version", "selling_price", "stages", "means"},
                  optional={"name", "reference"})
    if doc["format_version"] != FORMAT_VERSION:
        raise ValueError(f"format_version: only version {FORMAT_VERSION} is supported, got {doc['format_version']!r}")
    stages_data = _list(doc["stages"], "stages")
    if not stages_data:
        raise ValueError("stages: a Sequence needs at least one Stage")
    stages = tuple(_load_stage(s, f"stages[{i}]") for i, s in enumerate(stages_data))
    selling_price = _cost(doc["selling_price"], "selling_price")
    sequence = _at_path(lambda: Sequence(stages=stages, selling_price=selling_price), "stages")
    feature_means = _load_means(doc["means"], stages)
    reference = _load_reference(doc["reference"], "reference") if "reference" in doc else None
    name = _string(doc.get("name", ""), "name")
    return LoadedSequence(name=name, sequence=sequence, feature_means=feature_means, reference=reference)


def dump_sequence(loaded: LoadedSequence) -> Json:
    """Write sequence JSON. Cost tables are always written in full (C8), with state keys in Feature order (C7)."""
    doc: Json = {"format_version": FORMAT_VERSION, "name": loaded.name,
                 "selling_price": loaded.sequence.selling_price,
                 "stages": [_dump_stage(stage) for stage in loaded.sequence.stages],
                 "means": dump_means(loaded)}
    if loaded.reference is not None:
        doc["reference"] = dump_reference(loaded.reference)
    return doc


def dump_means(loaded: LoadedSequence) -> Json:
    """The `means` block: the `per_feature` values, in Feature order."""
    return {"scheme": "per_feature",
            "values": [{n: mu[n] for n in stage.feature_names}
                       for stage, mu in zip(loaded.sequence.stages, loaded.feature_means)]}


def dump_reference(reference: Reference) -> Json:
    doc: Json = {"source": reference.source, "quantity": reference.quantity, "value": reference.value,
                 "tolerance": reference.tolerance}
    if reference.note is not None:
        doc["note"] = reference.note
    return doc


def state_key(state: State, feature_names: tuple[str, ...]) -> str:
    """`"initial"`, or the reworked Feature names joined by `+` in Feature order (C7)."""
    if state == INITIAL_STATE:
        return INITIAL_KEY
    return "+".join(n for n in feature_names if n in state)


def _load_stage(data: object, path: str) -> Stage:
    doc = _object(data, path, required={"features", "variation", "costs"}, optional={"inspection"})
    features_data = _list(doc["features"], f"{path}.features")
    features = tuple(_load_feature(f, f"{path}.features[{i}]") for i, f in enumerate(features_data))
    names = tuple(f.name for f in features)
    variation = _load_variation(doc["variation"], f"{path}.variation", len(features))
    costs = _load_costs(doc["costs"], f"{path}.costs", names)
    inspection = _load_inspection(doc.get("inspection", {}), f"{path}.inspection")
    return _at_path(lambda: Stage(features=features, variation=variation, costs=costs, inspection=inspection), path)


def _load_feature(data: object, path: str) -> Feature:
    doc = _object(data, path, required={"name", "lower", "upper", "rework_side"})
    name = _string(doc["name"], f"{path}.name")
    if not FEATURE_NAME.fullmatch(name):
        raise ValueError(f"{path}.name: Feature names are 1 to 16 letters, digits or underscores, got {name!r}")
    sides = [s.value for s in ReworkSide]
    if doc["rework_side"] not in sides:
        raise ValueError(f"{path}.rework_side: must be one of {sides}, got {doc['rework_side']!r}")
    return _at_path(lambda: Feature(name, lower=_number(doc["lower"], f"{path}.lower"),
                                 upper=_number(doc["upper"], f"{path}.upper"),
                                 rework_side=ReworkSide(doc["rework_side"])), path)


def _load_variation(data: object, path: str, n_features: int) -> MultivariateNormal:
    doc = _object(data, path, required={"type", "sigmas"}, optional={"corr"})
    if doc["type"] != "normal":
        raise ValueError(f"{path}.type: only 'normal' is supported, got {doc['type']!r}")
    sigmas = [_number(s, f"{path}.sigmas[{i}]") for i, s in enumerate(_list(doc["sigmas"], f"{path}.sigmas"))]
    if len(sigmas) != n_features:
        raise ValueError(f"{path}.sigmas: need one per Feature ({n_features}), got {len(sigmas)}")
    corr = doc.get("corr", 0)
    if isinstance(corr, list):
        raise ValueError(f"{path}.corr: only a scalar correlation is supported, not a matrix")
    corr = _number(corr, f"{path}.corr")
    return _at_path(lambda: MultivariateNormal(sigmas, corr), path)


def _load_costs(data: object, path: str, names: tuple[str, ...]) -> CostTable:
    doc = _object(data, path, required={"processing", "rework", "scrap"})
    return _at_path(lambda: CostTable(processing=_cost(doc["processing"], f"{path}.processing"),
                                   rework=_state_table(doc["rework"], f"{path}.rework", names),
                                   scrap=_state_table(doc["scrap"], f"{path}.scrap", names)), path)


def _state_table(data: object, path: str, names: tuple[str, ...]) -> dict[State, float]:
    table: dict[State, float] = {}
    for key, value in _object(data, path).items():
        state = _parse_state(key, path, names)
        if state in table:
            raise ValueError(f"{path}: state {key!r} is given twice")
        table[state] = _cost(value, f"{path}.{key}")
    return table


def _parse_state(key: str, path: str, names: tuple[str, ...]) -> State:
    if key == INITIAL_KEY:
        return INITIAL_STATE
    parts = key.split("+")
    unknown = [p for p in parts if p not in names]
    if unknown or len(set(parts)) != len(parts):
        raise ValueError(f"{path}: state key {key!r} must be 'initial' or distinct Feature names "
                         f"of this Stage {list(names)} joined by '+'")
    return frozenset(parts)


def _load_inspection(data: object, path: str) -> InspectionCost:
    doc = _object(data, path, optional={"per_stage", "per_feature"})
    return InspectionCost(per_stage=_cost(doc.get("per_stage", 0), f"{path}.per_stage"),
                          per_feature=_cost(doc.get("per_feature", 0), f"{path}.per_feature"))


def _load_means(data: object, stages: tuple[Stage, ...]) -> tuple[dict[str, float], ...]:
    doc = _object(data, "means", required={"scheme", "values"})
    if doc["scheme"] != "per_feature":
        raise ValueError(f"means.scheme: only 'per_feature' is supported, got {doc['scheme']!r}")
    values = _list(doc["values"], "means.values")
    if len(values) != len(stages):
        raise ValueError(f"means.values: need one entry per Stage ({len(stages)}), got {len(values)}")
    result = []
    for i, (entry, stage) in enumerate(zip(values, stages)):
        path = f"means.values[{i}]"
        mu = {name: _number(v, f"{path}.{name}") for name, v in _object(entry, path).items()}
        if set(mu) != set(stage.feature_names):
            raise ValueError(f"{path}: need a mean for exactly {list(stage.feature_names)}, got {sorted(mu)}")
        result.append(mu)
    return tuple(result)


def _load_reference(data: object, path: str) -> Reference:
    doc = _object(data, path, required={"source", "quantity", "value", "tolerance"}, optional={"note"})
    if doc["quantity"] not in REFERENCE_QUANTITIES:
        raise ValueError(f"{path}.quantity: must be one of {list(REFERENCE_QUANTITIES)}, got {doc['quantity']!r}")
    note = _string(doc["note"], f"{path}.note") if "note" in doc else None
    return Reference(source=_string(doc["source"], f"{path}.source"), quantity=doc["quantity"],
                     value=_number(doc["value"], f"{path}.value"),
                     tolerance=_cost(doc["tolerance"], f"{path}.tolerance"), note=note)


def _dump_stage(stage: Stage) -> Json:
    names = stage.feature_names
    variation = stage.variation
    if not isinstance(variation, MultivariateNormal):
        raise ValueError(f"only Normal Process Variation can be written, got {type(variation).__name__}")
    off_diagonal = {variation.corr[i][j] for i in range(len(names)) for j in range(len(names)) if i != j}
    if len(off_diagonal) > 1:
        raise ValueError("only a scalar correlation can be written")
    return {
        "features": [{"name": f.name, "lower": f.lower, "upper": f.upper, "rework_side": f.rework_side.value}
                     for f in stage.features],
        "variation": {"type": "normal", "sigmas": list(variation.sigmas),
                      "corr": off_diagonal.pop() if off_diagonal else 0.0},
        "costs": {"processing": stage.costs.processing,
                  "rework": {state_key(s, names): stage.costs.rework[s] for s in stage.states[1:]},
                  "scrap": {state_key(s, names): stage.costs.scrap[s] for s in stage.states}},
        "inspection": {"per_stage": stage.inspection.per_stage, "per_feature": stage.inspection.per_feature},
    }


def _object(data: object, path: str, *, required: Collection[str] = (),
            optional: Collection[str] | None = None) -> Json:
    """A JSON object; with `optional` given, its keys must be `required` plus some of `optional`."""
    if not isinstance(data, dict) or not all(isinstance(k, str) for k in data):
        raise ValueError(f"{path}: expected an object, got {_kind(data)}")
    missing = sorted(set(required) - set(data))
    if missing:
        raise ValueError(f"{path}: missing {', '.join(missing)}")
    if optional is not None:
        unknown = sorted(set(data) - set(required) - set(optional))
        if unknown:
            raise ValueError(f"{path}: unknown field {', '.join(unknown)}")
    return data


def _list(data: object, path: str) -> list[Any]:
    if not isinstance(data, list):
        raise ValueError(f"{path}: expected a list, got {_kind(data)}")
    return data


def _string(data: object, path: str) -> str:
    if not isinstance(data, str):
        raise ValueError(f"{path}: expected a string, got {_kind(data)}")
    return data


def _number(data: object, path: str) -> float:
    if isinstance(data, bool) or not isinstance(data, (int, float)) or not math.isfinite(data):
        raise ValueError(f"{path}: expected a finite number, got {data!r}")
    return float(data)


def _cost(data: object, path: str) -> float:
    value = _number(data, path)
    if value < 0:
        raise ValueError(f"{path}: must be non-negative, got {value!r}")
    return value


def _kind(data: object) -> str:
    return {dict: "an object", list: "a list", str: "a string", bool: "a boolean", type(None): "null"}.get(
        type(data), repr(data))


def _at_path(build: Callable[[], T], path: str) -> T:
    """Prefix an engine ValueError with the path of the object being built."""
    try:
        return build()
    except ValueError as error:
        if str(error).startswith(path):
            raise
        raise ValueError(f"{path}: {error}") from error
