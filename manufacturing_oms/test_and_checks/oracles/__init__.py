"""Faithful ports of the legacy MATLAB, used only as test oracles (ADR 0002). Never import these from `oms`."""

from oracles.fun_cmc_markov import FunCMCMarkovOutput, fun_cmc_markov
from oracles.kandb_markov_dual_chars import (
    KAndB2008ExampleOutput,
    KandBMarkovDualCharsOutput,
    k_and_b_2008_example,
    kandb_markov_dual_chars,
)
from oracles.markov_process_1_var import MarkovProcess1VarOutput, markov_process_1_var
from oracles.probs_1var import probs_1var
from oracles.stage_cost_fun import probs_n_vars, stage_cost_fun

__all__ = [
    "FunCMCMarkovOutput",
    "KAndB2008ExampleOutput",
    "KandBMarkovDualCharsOutput",
    "MarkovProcess1VarOutput",
    "fun_cmc_markov",
    "k_and_b_2008_example",
    "kandb_markov_dual_chars",
    "markov_process_1_var",
    "probs_1var",
    "probs_n_vars",
    "stage_cost_fun",
]
