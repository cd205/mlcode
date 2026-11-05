"""Reference case R1 through the sequence format (web_app_plan.md §4-§5): load the `r1` preset and run it.

Prints the per-Pass counts for N = 10 000 parts, as thesis Fig 3.14 draws them.
Run from manufacturing_oms/ with:  uv run python examples/run_preset_r1.py
"""

import json
from pathlib import Path

from oms.formats import run

PRESET = Path(__file__).resolve().parents[1] / "presets" / "r1.json"
ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]

results = run(json.loads(PRESET.read_text()), action="evaluate", n_parts=10_000)
stage = results["stages"][0]

print(f"Final Conformance   {results['totals']['final_conformance']:.5f}")
print(f"Expected visits     {stage['visits']}")
print()
print(f"Per-Pass counts for N = {results['n_parts']:,} (expected parts, rounded)")
print("  Pass    C       R       S")
for k, p in enumerate(stage["passes"]):
    label = ROMAN[k] if k < len(ROMAN) else str(k + 1)
    c, r, s = (sum(p[kind].values()) for kind in ("conform", "rework", "scrap"))
    print(f"  {label:<5} {c:>6.0f}  {r:>6.0f}  {s:>6.0f}")
print(f"  remaining in Rework States: {stage['remaining']:.3f}   (thesis Fig 3.14: C = 9545, 217, 5; R = S = 228, 5)")

ref = results["reference"]
mark = "OK" if ref["within_tolerance"] else "MISMATCH"
print()
print(f"Engine vs thesis ({ref['source']}): {ref['quantity']} {ref['computed']:.5f} vs {ref['value']} "
      f"+/- {ref['tolerance']}  {mark}")
