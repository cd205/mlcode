# Faithful MATLAB/thesis ports are test oracles, not a library mode

The `oms` package has one engine, which implements the model as we now understand it to be correct. Wherever the engine deliberately departs from the MATLAB or the thesis (e.g. ADR 0001), a faithful port of the original behaviour lives only in `test_and_checks` as a reference oracle, and each difference has an entry in the discrepancy log. We rejected a `legacy=True` switch in the library because it would leave two engines to maintain and allow known-defective behaviour to be used in production analyses.
