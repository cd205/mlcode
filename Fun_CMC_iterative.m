function [Profit] = Fun_CMC_iterative(cut)
% clear all
% close all
% clc
LSL = 4.5; USL = 5.5; sigma = 1;
SP = 21; PC = 7; SC = 15; RC = 7;

% cut = [4 4 4 4]
i = 1;
Rwork = 1;
TOT = 0;
while Rwork > 0.0000000000001
    if i > length(cut)
        cut(i) =   5.0419;
    end
    Probs(i,1) = Rwork*(normcdf(LSL,cut(i),sigma)); % scrap 
    Probs(i,2) = Rwork*(normcdf(USL,cut(i),sigma) - normcdf(LSL,cut(i),sigma)); % conformance
    Probs(i,3) = Rwork*(1 - normcdf(USL,cut(i),sigma));
    Rwork = Probs(i,3);
    i = i + 1;
    Rwork;
    TOT_Scrap = sum(Probs(:,1));
    TOT_Confm = sum(Probs(:,2));
    TOT_Rwork = sum(Probs(:,3));
    Profit = SP*TOT_Confm - PC - SC*(TOT_Scrap) - RC*(TOT_Rwork);
end

    TOT_Scrap = sum(Probs(:,1));
    TOT_Confm = sum(Probs(:,2));
    TOT_Rwork = sum(Probs(:,3));
    TOT = TOT_Confm + TOT_Scrap;
    ProdCost = PC + SC*(TOT_Scrap) + RC*(TOT_Rwork);
    Profit = SP*TOT_Confm - PC - SC*(TOT_Scrap) - RC*(TOT_Rwork);