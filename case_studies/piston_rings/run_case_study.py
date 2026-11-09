"""Case study: Optimal Mean Setting for the inside diameter of forged piston rings (qcc `pistonrings`).

Headline (agreed 2026-11-07): at the published limits the process is so capable that OMS recommends almost
exactly the centring target, for a negligible gain; a sweep over limit width finds the Cp below which OMS
starts to pay. Tighter limits are exploration around the real baseline, never the lead result. Every cost,
the Rework Side and the rework model are hypothetical (data/PROVENANCE.md).

Run from case_studies/ with:  uv run python piston_rings/run_case_study.py
It writes piston_rings/output/ (results.json, report.md, figures/) and the web app presets
manufacturing_oms/presets/cs-piston-rings*.json.
"""

from __future__ import annotations

import gzip
import hashlib
import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

import numpy as np
from scipy.stats import norm, shapiro, t

from oms import (
    CostTable,
    Feature,
    GaussianCopula,
    MeanSettings,
    MultivariateNormal,
    ReworkSide,
    Sequence,
    Stage,
    evaluate_sequence,
    optimise_means,
)

HERE = Path(__file__).resolve().parent
DATA = HERE / "data" / "pistonrings.txt.gz"
DATA_SHA256 = "e83ac298f6344e4cbc86d134b823d3603a193ebc0acc8daa775738aa2f43ce95"
OUTPUT = HERE / "output"
PRESETS = HERE.parents[1] / "manufacturing_oms" / "presets"

NAME = "diameter"
INITIAL, REWORK = frozenset(), frozenset({NAME})
NOMINAL = 74.0  # mm
PUBLISHED_HALF = 0.05  # 73.95-74.05 mm, Montgomery's capability example (to be checked against the book)
TIGHT_HALF = 0.02  # hypothetical: the web app's second preset, where OMS clearly pays
PAYS_FRACTION = 0.001  # OMS "pays" once it gains 0.1 % of the Selling Price per part started
CP_GRID = np.round(np.arange(0.40, 1.801, 0.05), 2)
N_BOOTSTRAP = 400
N_SIMULATED = 2_000_000
SEED = 20261107

# Model parameters are rounded to what the data supports (σ to 0.01 µm, the mean to 0.1 µm), so the report,
# the article and the web presets all use the same numbers.
SIGMA_DP, MEAN_DP = 5, 4


@dataclass(frozen=True)
class Costs:
    """Hypothetical economics, read as in the web app (ADR 0006): Scrap Cost is extra to what is already charged."""

    selling_price: float
    material_value: float  # the forged blank, paid for every ring started
    processing: float  # machining and inspection of the bore
    rework: float  # one re-machining pass of an undersize bore
    scrap: float  # disposal, on top of the material and processing already lost


BASE = Costs(selling_price=100.0, material_value=20.0, processing=30.0, rework=10.0, scrap=0.0)
REWORK_SCENARIOS = {"cheap rework (2)": 2.0, "base (10)": 10.0, "dear rework (30)": 30.0}


# --- data and fit ----------------------------------------------------------------------------------------

@dataclass(frozen=True)
class Ring:
    diameter: float
    sample: int
    phase_one: bool


def load_rings(path: Path = DATA) -> list[Ring]:
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != DATA_SHA256:
        raise ValueError(f"{path} does not match the checksum in PROVENANCE.md")
    lines = gzip.decompress(raw).decode().split("\n")
    assert lines[0].split() == ["diameter", "sample", "trial"], lines[0]
    rows = [line.split() for line in lines[1:] if line.strip()]
    return [Ring(float(d), int(s), trial == "TRUE") for d, s, trial in rows]


def by_sample(rings: list[Ring]) -> dict[int, np.ndarray]:
    samples: dict[int, list[float]] = {}
    for r in rings:
        samples.setdefault(r.sample, []).append(r.diameter)
    return {s: np.array(v) for s, v in sorted(samples.items())}


def pooled_sigma(samples: list[np.ndarray]) -> float:
    """Within-sample standard deviation, pooled over equal-sized samples: short-term variation only."""
    return float(np.sqrt(np.mean([np.var(x, ddof=1) for x in samples])))


def fit(rings: list[Ring]) -> dict[str, Any]:
    samples = list(by_sample(rings).values())
    x = np.array([r.diameter for r in rings])
    rbar = float(np.mean([s.max() - s.min() for s in samples]))
    return {
        "n_rings": len(x),
        "n_samples": len(samples),
        "mean": float(x.mean()),
        "sigma_pooled": pooled_sigma(samples),
        "sigma_rbar": rbar / 2.326,  # R̄/d₂, d₂ = 2.326 for samples of 5
        "sd_total": float(x.std(ddof=1)),
        "min": float(x.min()),
        "max": float(x.max()),
        "shapiro_p": float(shapiro(x).pvalue),
        "sample_means": [float(s.mean()) for s in samples],
    }


# --- the OMS model ---------------------------------------------------------------------------------------

def sequence_for(half: float, variation: Any, costs: Costs = BASE) -> Sequence:
    """One Stage, one Feature: the bore, reworked when undersize and scrapped when oversize."""
    stage = Stage(
        features=(Feature(NAME, lower=NOMINAL - half, upper=NOMINAL + half, rework_side=ReworkSide.LOWER),),
        variation=variation,
        costs=CostTable(processing=costs.processing, rework={REWORK: costs.rework},
                        scrap={INITIAL: costs.scrap, REWORK: costs.scrap}),
    )
    return Sequence(stages=(stage,), selling_price=costs.selling_price, material_value=costs.material_value)


def outcome(sequence: Sequence, means: MeanSettings) -> dict[str, float]:
    """The per-ring numbers the report quotes, at given Mean Settings."""
    b = evaluate_sequence(sequence, [means])
    stage = b.stages[0]
    return {
        "mean_setting": means.by_state[INITIAL][NAME],
        "rework_mean_setting": means.by_state[REWORK][NAME],
        "expected_profit": b.expected_profit,
        "final_conformance": b.final_conformance,
        "scrap_probability": stage.scrap_probability,
        "expected_reworks": stage.visits[REWORK],
        "production_cost": b.production_cost,
        "cost_per_conforming_part": b.production_cost / b.final_conformance,
    }


def at(sequence: Sequence, mu: float) -> dict[str, float]:
    return outcome(sequence, MeanSettings.per_feature(sequence.stages[0], {NAME: mu}))


def optimum(sequence: Sequence, scheme: str = "per_feature") -> dict[str, float]:
    """The engine's default search (bounds L − 3σ to U + 3σ, 8 starts), the same one the web app's Optimise runs."""
    return outcome(sequence, optimise_means(sequence, scheme).means[0])  # type: ignore[arg-type]


def closed_form(mu: float, sigma: float, half: float, costs: Costs = BASE) -> float:
    """Expected Profit for one Normal Feature with rework below L as fresh draws: an independent check of the engine.

    A ring is redrawn until it lands in [L, U] or above U, so f_C = p_C / (1 − p_R), the scrap probability is
    p_X / (1 − p_R) and the expected number of reworks is p_R / (1 − p_R).
    """
    p_r = norm.cdf(NOMINAL - half, mu, sigma)
    p_x = norm.sf(NOMINAL + half, mu, sigma)
    p_c = 1.0 - p_r - p_x
    f_c, scrap, reworks = p_c / (1 - p_r), p_x / (1 - p_r), p_r / (1 - p_r)
    return float(costs.selling_price * f_c - costs.material_value - costs.processing
                 - costs.scrap * scrap - costs.rework * reworks)


def simulate(mu: float, sigma: float, half: float, n: int, seed: int, costs: Costs = BASE) -> dict[str, float]:
    """Monte Carlo of the same chain, ring by ring: mean profit per ring started and its standard error."""
    rng = np.random.default_rng(seed)
    lower, upper = NOMINAL - half, NOMINAL + half
    profit = np.full(n, -(costs.material_value + costs.processing))
    active = np.arange(n)
    while active.size:
        x = rng.normal(mu, sigma, active.size)
        over, under = x > upper, x < lower
        profit[active[~over & ~under]] += costs.selling_price
        profit[active[over]] -= costs.scrap
        profit[active[under]] -= costs.rework
        active = active[under]
    return {"expected_profit": float(profit.mean()), "standard_error": float(profit.std() / np.sqrt(n))}


# --- the analysis ----------------------------------------------------------------------------------------

def compare(half: float, sigma: float, current: float) -> dict[str, Any]:
    """Centring, the current process and the OMS optimum, at one pair of limits."""
    seq = sequence_for(half, MultivariateNormal([sigma]))
    nominal, now, best = at(seq, NOMINAL), at(seq, current), optimum(seq)
    return {
        "lower": NOMINAL - half,
        "upper": NOMINAL + half,
        "cp": 2 * half / (6 * sigma),
        "cpk_current": (half - abs(current - NOMINAL)) / (3 * sigma),
        "nominal": nominal,
        "current": now,
        "oms": best,
        "oms_per_state": optimum(seq, "per_state"),
        "gain_vs_nominal": best["expected_profit"] - nominal["expected_profit"],
        "gain_vs_current": best["expected_profit"] - now["expected_profit"],
        "shift_sigmas": (best["mean_setting"] - NOMINAL) / sigma,
    }


def sweep(sigma: float) -> dict[str, list[dict[str, float]]]:
    """For each rework-cost scenario: the OMS optimum against centring as the limits narrow (Cp falls)."""
    curves = {}
    for label, rework in REWORK_SCENARIOS.items():
        costs = Costs(**{**asdict(BASE), "rework": rework})
        rows = []
        for cp in CP_GRID:
            half = 3 * cp * sigma
            seq = sequence_for(half, MultivariateNormal([sigma]), costs)
            best, centred = optimum(seq), at(seq, NOMINAL)
            rows.append({"cp": float(cp), "half_width": half, "mean_setting": best["mean_setting"],
                         "shift_sigmas": (best["mean_setting"] - NOMINAL) / sigma,
                         "gain_vs_nominal": best["expected_profit"] - centred["expected_profit"]})
        curves[label] = rows
    return curves


def pays_below(rows: list[dict[str, float]], threshold: float) -> float | None:
    """The Cp at which the gain first reaches `threshold`, interpolated between grid points, coming down from high Cp."""
    for hi, lo in zip(rows[::-1], rows[-2::-1]):
        if hi["gain_vs_nominal"] < threshold <= lo["gain_vs_nominal"]:
            w = (threshold - hi["gain_vs_nominal"]) / (lo["gain_vs_nominal"] - hi["gain_vs_nominal"])
            return hi["cp"] + w * (lo["cp"] - hi["cp"])
    return None


def bootstrap(phase_one: list[np.ndarray], seed: int) -> dict[str, Any]:
    """Resample whole samples of 5 (not single rings): σ, Cp at the published limits, and the optimum at ±0.02 mm."""
    rng = np.random.default_rng(seed)
    sigmas, shifts, gains = [], [], []
    for _ in range(N_BOOTSTRAP):
        pick = [phase_one[i] for i in rng.integers(0, len(phase_one), len(phase_one))]
        s = pooled_sigma(pick)
        seq = sequence_for(TIGHT_HALF, MultivariateNormal([s]))
        best = optimum(seq)
        sigmas.append(s)
        shifts.append(best["mean_setting"] - NOMINAL)
        gains.append(best["expected_profit"] - at(seq, NOMINAL)["expected_profit"])

    def interval(v: list[float]) -> list[float]:
        return [float(q) for q in np.percentile(v, [2.5, 50, 97.5])]

    return {
        "n": N_BOOTSTRAP,
        "sigma": interval(sigmas),
        "cp_published": interval([2 * PUBLISHED_HALF / (6 * s) for s in sigmas]),
        "tight_shift_mm": interval(shifts),
        "tight_gain_vs_nominal": interval(gains),
    }


def heavy_tails(phase_one: list[np.ndarray], sigma: float) -> dict[str, Any]:
    """Refit the short-term variation as a t distribution and redo the ±0.02 mm optimum, to see if tails matter."""
    residuals = np.concatenate([(x - x.mean()) * np.sqrt(len(x) / (len(x) - 1)) for x in phase_one])
    df, _, scale = t.fit(residuals, floc=0.0)
    t_seq = sequence_for(TIGHT_HALF, GaussianCopula([t(df, 0.0, scale)]))
    normal_seq = sequence_for(TIGHT_HALF, MultivariateNormal([sigma]))
    return {"df": float(df), "scale": float(scale), "tight_oms_t": optimum(t_seq),
            "tight_oms_normal": optimum(normal_seq)}


def drift(phase_two_means: list[float], sigma: float, best: dict[str, dict[str, float]]) -> dict[str, Any]:
    """What phase II's upward drift (towards the scrap side) would cost, against running at the optimum."""
    phase_mean, worst = float(np.mean(phase_two_means)), float(max(phase_two_means))
    out: dict[str, Any] = {"phase_two_mean": phase_mean, "highest_sample_mean": worst}
    for label, half in (("published", PUBLISHED_HALF), ("tight", TIGHT_HALF)):
        seq = sequence_for(half, MultivariateNormal([sigma]))
        out[label] = {"at_phase_two_mean": at(seq, phase_mean), "at_highest_sample_mean": at(seq, worst),
                      "at_oms": best[label]}
    return out


def validate(sigma: float, tight_best: float) -> dict[str, Any]:
    """The engine against the closed form over a grid, and against a ring-by-ring simulation at the ±0.02 optimum."""
    worst = 0.0
    for half in (PUBLISHED_HALF, 0.03, TIGHT_HALF, 0.015):
        seq = sequence_for(half, MultivariateNormal([sigma]))
        for mu in np.linspace(NOMINAL - 0.02, NOMINAL + 0.02, 21):
            worst = max(worst, abs(at(seq, float(mu))["expected_profit"] - closed_form(float(mu), sigma, half)))
    sim = simulate(tight_best, sigma, TIGHT_HALF, N_SIMULATED, SEED)
    engine = at(sequence_for(TIGHT_HALF, MultivariateNormal([sigma])), tight_best)["expected_profit"]
    return {
        "closed_form_max_abs_difference": worst,
        "simulation": {**sim, "n_rings": N_SIMULATED, "seed": SEED, "engine": engine,
                       "z": (sim["expected_profit"] - engine) / sim["standard_error"]},
    }


# --- web app presets -------------------------------------------------------------------------------------

def preset(half: float, sigma: float, mean: float, name: str, note: str) -> dict[str, Any]:
    """A web app preset at the current process mean, with the closed form's Expected Profit as its reference."""
    return {
        "format_version": 1,
        "name": name,
        "selling_price": BASE.selling_price,
        "material_value": BASE.material_value,
        "stages": [{
            "features": [{"name": NAME, "lower": round(NOMINAL - half, 6), "upper": round(NOMINAL + half, 6),
                          "rework_side": "lower"}],
            "variation": {"type": "normal", "sigmas": [sigma], "corr": 0},
            "costs": {"processing": BASE.processing, "rework": {NAME: BASE.rework},
                      "scrap": {"initial": BASE.scrap, NAME: BASE.scrap}},
            "inspection": {"per_stage": 0, "per_feature": 0},
        }],
        "means": {"scheme": "per_feature", "values": [{NAME: mean}]},
        "reference": {
            "source": "Piston-ring case study, closed form",
            "quantity": "expected_profit",
            "value": round(closed_form(mean, sigma, half), 7),
            "tolerance": 1e-6,
            "note": note,
        },
    }


def presets(sigma: float, mean: float) -> dict[str, dict[str, Any]]:
    common = (f"Inside diameter of forged piston rings (qcc pistonrings, Montgomery 1991), mm. σ = {sigma} is the "
              f"pooled within-sample sd of samples 1–25; the Mean Setting {mean} is their mean, the current process. "
              "Costs, the Rework Side (undersize bore re-machined) and the rework model are hypothetical. "
              "See case_studies/piston_rings.")
    return {
        "cs-piston-rings": preset(
            PUBLISHED_HALF, sigma, mean, "Case study: piston rings, published limits 74 ± 0.05 mm",
            "Published limits: the process is very capable (Cp ≈ 1.7), so Optimise barely moves the mean. " + common),
        "cs-piston-rings-tight": preset(
            TIGHT_HALF, sigma, mean, "Case study: piston rings, hypothetical limits 74 ± 0.02 mm",
            "Hypothetical tighter limits (Cp ≈ 0.68), where Optimise moves the mean towards the reworkable "
            "undersize side. " + common),
    }


# --- figures ---------------------------------------------------------------------------------------------

# Light reference palette (dataviz skill): categorical slots in fixed order, text and grid in neutral ink.
SURFACE, INK, INK_2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3de"
SERIES = ["#2a78d6", "#eb6834", "#1baf7a"]


def _style() -> None:
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    plt.rcParams.update({
        "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
        "axes.edgecolor": GRID, "axes.labelcolor": INK_2, "axes.titlecolor": INK, "axes.titlesize": 11,
        "axes.titleweight": "bold", "axes.titlelocation": "left", "axes.spines.top": False,
        "axes.spines.right": False, "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.6,
        "xtick.color": INK_2, "ytick.color": INK_2, "font.size": 9, "legend.frameon": False,
        "lines.linewidth": 2,
    })


def _limits(ax: Any, half: float, label: str, style: str) -> None:
    for x in (NOMINAL - half, NOMINAL + half):
        ax.axvline(x, color=INK_2, linestyle=style, linewidth=1)
    ax.annotate(label, (NOMINAL + half, 1), xycoords=("data", "axes fraction"), xytext=(3, -3),
                textcoords="offset points", va="top", color=INK_2, fontsize=8)


def figures(rings: list[Ring], fits: dict[str, Any], results: dict[str, Any]) -> list[str]:
    _style()
    import matplotlib.pyplot as plt

    folder = OUTPUT / "figures"
    folder.mkdir(parents=True, exist_ok=True)
    sigma, current = results["model"]["sigma"], results["model"]["current_mean"]
    written = []

    def save(fig: Any, name: str) -> None:
        fig.tight_layout()
        fig.savefig(folder / name, dpi=200)
        plt.close(fig)
        written.append(f"figures/{name}")

    # 1. The data against both pairs of limits.
    fig, ax = plt.subplots(figsize=(7, 3.6))
    x = np.array([r.diameter for r in rings if r.phase_one])
    width = 0.004
    ax.hist(x, bins=np.arange(73.962, 74.040, width), color=SERIES[0], edgecolor=SURFACE, linewidth=2,
            label="samples 1–25 (125 rings)")
    grid = np.linspace(73.94, 74.06, 400)
    ax.plot(grid, norm.pdf(grid, current, sigma) * len(x) * width, color=INK, linewidth=1.5,
            label=f"Normal fit, σ = {sigma * 1000:.2f} µm")
    _limits(ax, PUBLISHED_HALF, "published limit", "-")
    _limits(ax, TIGHT_HALF, "hypothetical ±0.02", "--")
    ax.set(title="Inside diameters sit far inside the published limits", xlabel="inside diameter (mm)",
           ylabel="rings", xlim=(73.94, 74.06))
    ax.legend(loc="upper left")
    save(fig, "1_distribution.png")

    # 2. Sample means: stable in phase I, drifting up (towards the scrap side) in phase II.
    fig, ax = plt.subplots(figsize=(7, 3.4))
    means = fits["all"]["sample_means"]
    ax.axhline(current, color=INK_2, linewidth=1)
    for k in (-3, 3):
        ax.axhline(current + k * sigma / np.sqrt(5), color=INK_2, linestyle="--", linewidth=1)
    ax.annotate("x̄-chart limits", (40.5, current + 3 * sigma / np.sqrt(5)), va="bottom", ha="right",
                color=INK_2, fontsize=8)
    ax.plot(range(1, 26), means[:25], "o-", color=SERIES[0], markersize=4, linewidth=1, label="samples 1–25 (fitted)")
    ax.plot(range(26, 41), means[25:], "o-", color=SERIES[1], markersize=4, linewidth=1, label="samples 26–40 (later)")
    ax.set(title="Later samples drift towards the oversize, scrap side", xlabel="sample", ylabel="sample mean (mm)")
    ax.legend(loc="upper left")
    save(fig, "2_sample_means.png")

    # 3. Expected Profit against the Mean Setting: flat at the published limits, peaked at ±0.02. One y scale,
    # so the flat curve looks flat.
    fig, axes = plt.subplots(1, 2, figsize=(7, 3.4), sharex=True, sharey=True)
    mus = np.linspace(NOMINAL - 0.025, NOMINAL + 0.02, 181)
    for ax, key, half, title in ((axes[0], "published", PUBLISHED_HALF, "Published limits ±0.05 mm"),
                                 (axes[1], "tight", TIGHT_HALF, "Hypothetical limits ±0.02 mm")):
        seq = sequence_for(half, MultivariateNormal([sigma]))
        ax.plot(mus, [at(seq, float(m))["expected_profit"] for m in mus], color=SERIES[0])
        best = results["comparison"][key]["oms"]
        ax.plot(best["mean_setting"], best["expected_profit"], "o", color=SERIES[0], markersize=8,
                markeredgecolor=SURFACE, markeredgewidth=2)
        ax.annotate(f"OMS {best['mean_setting']:.4f}", (best["mean_setting"], best["expected_profit"]),
                    xytext=(0, 8), textcoords="offset points", ha="center", color=INK, fontsize=8)
        ax.axvline(NOMINAL, color=INK_2, linestyle=":", linewidth=1)
        ax.annotate("nominal", (NOMINAL, 0.02), xycoords=("data", "axes fraction"), xytext=(3, 0),
                    textcoords="offset points", color=INK_2, fontsize=8)
        ax.set(title=title, xlabel="Mean Setting (mm)")
        ax.ticklabel_format(useOffset=False)
    axes[0].set_ylabel("Expected Profit per ring started")
    axes[0].set_ylim(top=BASE.selling_price - BASE.material_value - BASE.processing + 6)  # room for the labels
    save(fig, "3_profit_curves.png")

    # 4. The headline: where OMS starts to pay, and how far it moves the mean.
    fig, (top, bottom) = plt.subplots(2, 1, figsize=(7, 5.6), sharex=True)
    published_cp = results["comparison"]["published"]["cp"]
    for colour, (label, rows) in zip(SERIES, results["sweep"].items()):
        cps = [r["cp"] for r in rows]
        top.plot(cps, [r["gain_vs_nominal"] for r in rows], color=colour, label=label)
        bottom.plot(cps, [r["shift_sigmas"] for r in rows], color=colour, label=label)
    threshold = PAYS_FRACTION * BASE.selling_price
    top.axhline(threshold, color=INK_2, linestyle="--", linewidth=1)
    top.annotate(f"pays: {threshold:g} per ring", (1.8, threshold), va="bottom", ha="right", color=INK_2,
                 fontsize=8)
    for ax in (top, bottom):
        ax.axvline(published_cp, color=INK_2, linewidth=1)
    top.annotate(f"published limits, Cp {published_cp:.2f}", (published_cp, 1), xycoords=("data", "axes fraction"),
                 xytext=(-3, -3), textcoords="offset points", ha="right", va="top", color=INK_2, fontsize=8)
    top.set(title="OMS only pays once the process is marginally capable",
            ylabel="Expected Profit gain over centring")
    bottom.set(title="…by moving the mean towards the reworkable side", xlabel="Cp (limits narrowed, σ fixed)",
               ylabel="OMS mean − nominal (σ)")
    top.legend(title="Rework Cost", loc="upper center")
    save(fig, "4_gain_vs_cp.png")
    return written


# --- report ----------------------------------------------------------------------------------------------

def _row(label: str, o: dict[str, float]) -> str:
    return (f"| {label} | {o['mean_setting']:.4f} | {o['expected_profit']:.4f} | {o['final_conformance']:.6f} | "
            f"{o['scrap_probability']:.2e} | {o['expected_reworks']:.2e} | {o['cost_per_conforming_part']:.4f} |")


def report(results: dict[str, Any]) -> str:
    m, comp, val = results["model"], results["comparison"], results["validation"]
    pub, tight = comp["published"], comp["tight"]
    boot, tails, d = results["bootstrap"], results["heavy_tails"], results["drift"]
    pays = results["pays_below_cp"]
    tails_text = (f"A t fit to the within-sample residuals goes to ν → ∞ (ν > 1000): the data show no heavier tails "
                  f"than a Normal" if tails["df"] > 1000 else
                  f"A t fit to the within-sample residuals has ν = {tails['df']:.1f}")
    head =["| Mean Setting | mm | E(PR) per ring started | Final Conformance | Scrap probability | Expected reworks "
            "| Cost per conforming ring |", "|---|---|---|---|---|---|---|"]

    def table(c: dict[str, Any]) -> str:
        return "\n".join(head + [_row("Nominal 74.000", c["nominal"]), _row("Current process", c["current"]),
                                 _row("OMS optimum", c["oms"])])

    lines = [
        "# Piston-ring inside diameter: an OMS case study",
        "",
        "_Generated by `run_case_study.py`; every number is in `results.json`. Costs, the Rework Side and the rework "
        "model are hypothetical (see [PROVENANCE](../data/PROVENANCE.md))._",
        "",
        "## Headline",
        "",
        f"At the published limits (74 ± 0.05 mm) the process has Cp {pub['cp']:.2f}. OMS recommends "
        f"{pub['oms']['mean_setting']:.4f} mm, and gains {pub['gain_vs_nominal']:.2e} per ring started over centring at "
        "74.000: nothing worth acting on. Narrowing the limits with σ fixed, the gain reaches "
        f"{PAYS_FRACTION * BASE.selling_price:g} per ring (0.1 % of the Selling Price) at Cp ≈ "
        f"{pays['base (10)']:.2f} under the base costs. At hypothetical limits of ±0.02 mm (Cp {tight['cp']:.2f}) OMS "
        f"moves the mean {tight['oms']['mean_setting'] - NOMINAL:+.4f} mm ({tight['shift_sigmas']:+.2f} σ), towards "
        f"the reworkable undersize side, and gains {tight['gain_vs_nominal']:.2f} per ring over centring.",
        "",
        "![Where OMS starts to pay](figures/4_gain_vs_cp.png)",
        "",
        "## Data",
        "",
        f"200 inside diameters (mm, to 0.001) of forged piston rings in 40 samples of 5. Samples 1–25 are the "
        f"in-control preliminary samples and are the fit; samples 26–40 are later production and are used as a "
        f"drift scenario. Samples 1–25: mean {m['current_mean']:.4f} mm, pooled within-sample σ "
        f"{m['sigma'] * 1000:.2f} µm (R̄/d₂ gives {results['fit']['phase_one']['sigma_rbar'] * 1000:.2f} µm), "
        f"Shapiro–Wilk p = {results['fit']['phase_one']['shapiro_p']:.2f}. No ring is outside 73.95–74.05.",
        "",
        "![Distribution](figures/1_distribution.png)",
        "",
        "![Sample means](figures/2_sample_means.png)",
        "",
        "## Model",
        "",
        "One Stage with one Feature, the bore, Normal with the fitted σ. An undersize bore is re-machined (Rework "
        "Side LOWER) and an oversize one is scrapped; a re-machined ring is a fresh draw at the Mean Setting. "
        f"Hypothetical economics per ring: Selling Price {BASE.selling_price:g}, Material Value "
        f"{BASE.material_value:g}, Processing {BASE.processing:g}, Rework {BASE.rework:g} per pass, Scrap "
        f"{BASE.scrap:g} extra (a scrapped ring loses its material and processing, ADR 0006). The optimiser is the "
        "engine default, as in the web app.",
        "",
        "## Results",
        "",
        f"### Published limits 73.95–74.05 mm (Cp {pub['cp']:.2f}, current Cpk {pub['cpk_current']:.2f})",
        "",
        table(pub),
        "",
        f"### Hypothetical limits 73.98–74.02 mm (Cp {tight['cp']:.2f}, current Cpk {tight['cpk_current']:.2f})",
        "",
        table(tight),
        "",
        "![Expected Profit against Mean Setting](figures/3_profit_curves.png)",
        "",
        "## Sensitivity",
        "",
        "- **Rework Cost.** Cp at which OMS gains 0.1 % of the Selling Price over centring: "
        + ", ".join(f"{k}: {v:.2f}" if v is not None else f"{k}: not reached" for k, v in pays.items()) + ".",
        f"- **σ uncertainty** ({boot['n']} bootstrap resamples of whole samples): σ {boot['sigma'][0] * 1000:.2f}–"
        f"{boot['sigma'][2] * 1000:.2f} µm, so Cp at the published limits {boot['cp_published'][0]:.2f}–"
        f"{boot['cp_published'][2]:.2f}. At ±0.02 mm the OMS shift is {boot['tight_shift_mm'][0]:+.4f} to "
        f"{boot['tight_shift_mm'][2]:+.4f} mm and its gain {boot['tight_gain_vs_nominal'][0]:.2f}–"
        f"{boot['tight_gain_vs_nominal'][2]:.2f} (95 % intervals).",
        f"- **Tails.** {tails_text}. At ±0.02 mm the t model's optimum is "
        f"{tails['tight_oms_t']['mean_setting']:.4f} mm (Normal {tails['tight_oms_normal']['mean_setting']:.4f}).",
        f"- **Separate rework target** (`per_state`). At ±0.02 mm: first pass {tight['oms_per_state']['mean_setting']:.4f}, "
        f"re-machining {tight['oms_per_state']['rework_mean_setting']:.4f} mm, Expected Profit "
        f"{tight['oms_per_state']['expected_profit']:.4f} (one target: {tight['oms']['expected_profit']:.4f}). "
        "With rework as a fresh draw, a re-machined ring faces the same trade-off as a new one, so a separate "
        "target can add little.",
        "",
        "## Drift",
        "",
        f"Samples 26–40 average {d['phase_two_mean']:.4f} mm, the highest sample {d['highest_sample_mean']:.4f}. "
        f"At the published limits Expected Profit there is {d['published']['at_phase_two_mean']['expected_profit']:.4f} "
        f"and {d['published']['at_highest_sample_mean']['expected_profit']:.4f}, against "
        f"{d['published']['at_oms']['expected_profit']:.4f} at the optimum: only the worst sample costs anything. At "
        f"±0.02 mm it would be {d['tight']['at_phase_two_mean']['expected_profit']:.4f} and "
        f"{d['tight']['at_highest_sample_mean']['expected_profit']:.4f}, against "
        f"{d['tight']['at_oms']['expected_profit']:.4f} at the optimum. With tight limits, holding the mean where it "
        f"is set is worth far more than the {tight['gain_vs_nominal']:.2f} that OMS gains by choosing it.",
        "",
        "## Validation",
        "",
        f"- Engine against the closed form f_C = p_C / (1 − p_R) etc., over 4 limit widths × 21 means: largest "
        f"difference in Expected Profit {val['closed_form_max_abs_difference']:.1e}.",
        f"- Ring-by-ring simulation of {val['simulation']['n_rings']:,} rings at the ±0.02 optimum: "
        f"{val['simulation']['expected_profit']:.4f} ± {val['simulation']['standard_error']:.4f} against the "
        f"engine's {val['simulation']['engine']:.4f} (z = {val['simulation']['z']:+.2f}).",
        "",
        "## Limitations",
        "",
        "- The costs, the Rework Side and rework itself are hypothetical: the rings are forged, and nothing in the "
        "source says an undersize bore is re-machined.",
        "- A re-machined ring is modelled as a fresh draw at the Mean Setting; a real pass depends on the previous size.",
        "- OMS moves only the mean, keeping σ. That a forging process can be re-targeted by a few µm is assumed.",
        "- The published limits come from Montgomery's capability example and still need checking against the book.",
        "- All money is per ring started; there is no production volume, so no annual figure.",
        "",
        "## Reproduce",
        "",
        "From `case_studies/`: `uv run python piston_rings/run_case_study.py`. The web app presets "
        "`cs-piston-rings` and `cs-piston-rings-tight` load this model at the current mean; press Optimise.",
        "",
    ]
    return "\n".join(lines)


# --- main ------------------------------------------------------------------------------------------------

def main() -> None:
    rings = load_rings()
    phase_one = [r for r in rings if r.phase_one]
    fits = {"phase_one": fit(phase_one), "phase_two": fit([r for r in rings if not r.phase_one]), "all": fit(rings)}
    sigma = round(fits["phase_one"]["sigma_pooled"], SIGMA_DP)
    current = round(fits["phase_one"]["mean"], MEAN_DP)
    samples_one = [x for s, x in by_sample(rings).items() if s <= 25]

    comparison = {"published": compare(PUBLISHED_HALF, sigma, current), "tight": compare(TIGHT_HALF, sigma, current)}
    curves = sweep(sigma)
    threshold = PAYS_FRACTION * BASE.selling_price
    results: dict[str, Any] = {
        "case_study": "piston_rings",
        "data": {"file": "data/pistonrings.txt.gz", "sha256": DATA_SHA256},
        "assumptions": {
            "hypothetical": ["costs", "rework side lower", "rework is a fresh draw", "limits other than ±0.05 mm"],
            "to_check": ["published limits 73.95-74.05 mm against Montgomery (1991)"],
        },
        "costs": asdict(BASE),
        "fit": {k: {kk: vv for kk, vv in v.items() if k == "all" or kk != "sample_means"} for k, v in fits.items()},
        "model": {"sigma": sigma, "current_mean": current, "nominal": NOMINAL},
        "comparison": comparison,
        "sweep": curves,
        "pays_threshold": threshold,
        "pays_below_cp": {label: pays_below(rows, threshold) for label, rows in curves.items()},
        "bootstrap": bootstrap(samples_one, SEED),
        "heavy_tails": heavy_tails(samples_one, sigma),
        "drift": drift(fits["phase_two"]["sample_means"], sigma,
                       {k: v["oms"] for k, v in comparison.items()}),
        "validation": validate(sigma, comparison["tight"]["oms"]["mean_setting"]),
    }
    results["figures"] = figures(rings, fits, results)

    OUTPUT.mkdir(exist_ok=True)
    (OUTPUT / "results.json").write_text(json.dumps(results, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (OUTPUT / "report.md").write_text(report(results), encoding="utf-8")
    for preset_id, doc in presets(sigma, current).items():
        (PRESETS / f"{preset_id}.json").write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n",
                                                   encoding="utf-8")
    pub = comparison["published"]
    print(f"Published limits: Cp {pub['cp']:.2f}, OMS {pub['oms']['mean_setting']:.4f} mm, "
          f"gain over centring {pub['gain_vs_nominal']:.2e}")
    print(f"OMS pays (gain >= {threshold:g}) below Cp ~ {results['pays_below_cp']['base (10)']:.2f} (base costs)")
    print(f"Wrote {OUTPUT} and the presets in {PRESETS}")


if __name__ == "__main__":
    main()
