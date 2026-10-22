"""Faithful ports of the legacy MATLAB, used only as test oracles (ADR 0002). Never import these from `oms`."""

from oracles.costs_multi_stage_multi_feature import (
    TWO_STAGE_DUAL_FEATURE,
    TWO_STAGE_SINGLE_FEATURE,
    CostsMultiStageMultiFeatureOutput,
    SequenceLoopOutput,
    costs_multi_stage_multi_feature,
)
from oracles.fun_cmc_markov import FunCMCMarkovOutput, fun_cmc_markov
from oracles.kandb_markov_dual_chars import (
    KAndB2008ExampleOutput,
    KandBMarkovDualCharsOutput,
    k_and_b_2008_example,
    kandb_markov_dual_chars,
)
from oracles.markov_process_1_var import MarkovProcess1VarOutput, markov_process_1_var
from oracles.markov_process_2_var import MarkovProcess2VarOutput, markov_process_2_var
from oracles.markov_tri_chars import MarkovTriCharsOutput, markov_tri_chars
from oracles.probs_1var import probs_1var
from oracles.probs_2var import probs_2var
from oracles.probs_3var import probs_3var
from oracles.stage_cost_fun import (
    per_group_size_from_mu_rows,
    probs_n_vars,
    probs_n_vars_multi_mu,
    s_matrix_cell,
    stage_cost_fun,
    stage_cost_fun_multi_mu,
)
from oracles.stage_cost_fun_old import StageCostFunOldOutput, stage_cost_fun_old

__all__ = [
    "TWO_STAGE_DUAL_FEATURE",
    "TWO_STAGE_SINGLE_FEATURE",
    "CostsMultiStageMultiFeatureOutput",
    "FunCMCMarkovOutput",
    "KAndB2008ExampleOutput",
    "KandBMarkovDualCharsOutput",
    "MarkovProcess1VarOutput",
    "MarkovProcess2VarOutput",
    "MarkovTriCharsOutput",
    "SequenceLoopOutput",
    "StageCostFunOldOutput",
    "costs_multi_stage_multi_feature",
    "fun_cmc_markov",
    "k_and_b_2008_example",
    "kandb_markov_dual_chars",
    "markov_process_1_var",
    "markov_process_2_var",
    "markov_tri_chars",
    "per_group_size_from_mu_rows",
    "probs_1var",
    "probs_2var",
    "probs_3var",
    "probs_n_vars",
    "probs_n_vars_multi_mu",
    "s_matrix_cell",
    "stage_cost_fun",
    "stage_cost_fun_multi_mu",
    "stage_cost_fun_old",
]
