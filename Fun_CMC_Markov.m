function [Profit] = Fun_CMC_Markov(cut)
% clear all
% close all
% clc
LSL = 2; USL = 8; sigma = 1;
SP = 21; PC = 7; SC = 15; RC = 7;

% cut = [4 4 4 4]

p1r = (1 - normcdf(USL,cut,sigma));                         % Rework
p1a = (normcdf(USL,cut,sigma) - normcdf(LSL,cut,sigma)); % Conformance
p1s = (normcdf(LSL,cut,sigma));                             % scrap
TOT_Scrap = p1s/(1-p1r);
TOT_Confm = p1a/(1-p1r);
TOT_Rwork = 1/(1-p1r)-1;

TOT = TOT_Confm + TOT_Scrap;
ProdCost = PC + SC*(TOT_Scrap) + RC*(TOT_Rwork);
Profit = SP*TOT_Confm - PC - SC*(TOT_Scrap) - RC*(TOT_Rwork);