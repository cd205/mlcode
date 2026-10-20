# Pre-implementation checks

These throwaway scripts were written on 2026-10-17/18 while checking the thesis reference cases (spec §6), before any engine code existed. They are **not** part of the `oms` package or the test suite. Keep them as independent cross-checks while building Stages 1–7: if the engine and one of these scripts disagree, find out why before trusting either.

Each script hard-codes one case and prints its results next to the printed thesis values. Run any of them from this folder with:

```
uv run --no-project --with numpy --with scipy python -I <script>.py
```

| Script | Case | Reproduces |
|---|---|---|
| `r2_table_3_3.py` | R2, 1 Feature | max profit μ = 10.6144; min production cost μ = 10.0875 (U2) |
| `r4_table_3_7.py` | R4, 2 Features in parallel | 71.1723 @ [10.537, 15.590]; min cost 46.7530 @ [10.128, 15.181] |
| `r6_r7_tables_3_11_3_13.py` | R6/R7, `per_feature` vs `per_group_size`, ρ = 0, ±0.8 | every profit, mean, f_C and Sr + Rw value in Tables 3.11 and 3.13 (needs SP = 400, σ = 2; D11) |
| `r9_conrod_table_4_3.py` | R9, connecting rod, Gaussian copula with a t marginal | 44.4708 at exactly the printed means (D6) |
| `extract_thesis_text.py` | Utility | dumps the thesis PDF text, page by page: `uv run --no-project --with pypdf python -I extract_thesis_text.py <pdf> <out.txt>` |

They use the closed-form absorbing chain for N ≤ 2 only. Scrap uses the exact form (ADR 0001), which matches Eq 3.59 at N ≤ 2.
