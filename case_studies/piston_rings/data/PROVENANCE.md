# Provenance: piston-ring inside diameters

| | |
|---|---|
| File | `pistonrings.txt.gz` (unchanged) |
| Source | R package **qcc** 2.7 (2017-07-09), `data/pistonrings.txt.gz` |
| URL | https://raw.githubusercontent.com/cran/qcc/master/data/pistonrings.txt.gz (CRAN mirror commit `11b6ecef027c315ed547e4749949ee3a7eed502c`) |
| Documentation | https://raw.githubusercontent.com/cran/qcc/master/man/pistonrings.Rd |
| Original source | Montgomery, D.C. (1991) *Introduction to Statistical Quality Control*, 2nd ed., Wiley, pp. 206–213 |
| Licence | qcc is GPL (>= 2) |
| Downloaded | 2026-11-07 |
| SHA-256 | `e83ac298f6344e4cbc86d134b823d3603a193ebc0acc8daa775738aa2f43ce95` |

## Contents

200 rows, whitespace-separated, header `diameter sample trial`. In qcc's words: "Piston rings for an automotive
engine are produced by a forging process. The inside diameter of the rings manufactured by the process is
measured on 25 samples, each of size 5, for the control phase I [...]. Then, further 15 samples, again each of
size 5, are obtained for phase II." `trial` is TRUE for samples 1–25 (phase I). Diameters are in mm, to 0.001 mm.

## What is real and what is assumed

| Item | Status |
|---|---|
| Diameters, samples, phase I / II split | Real (the data) |
| Specification Limits 73.95–74.05 mm (74.000 ± 0.05) | From Montgomery's capability example for this process; qcc does not state them. **Check against the book before calling them real**; until then they are labelled "published" in outputs. |
| Rework Side LOWER (undersize bore re-machined, oversize scrapped) | Assumed from the geometry of an inside diameter; the source says nothing about rework |
| Rework as a fresh draw at a Mean Setting | Assumed (the OMS Markov model); a real re-machining pass depends on the previous size |
| Selling Price, Material Value, Processing, Rework and Scrap Costs | Hypothetical |
| Tighter limits (e.g. ±0.02 mm) | Hypothetical, used only to find where OMS starts to pay |
