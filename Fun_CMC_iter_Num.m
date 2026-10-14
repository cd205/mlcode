function [Profit] = Fun_CMC_iter_Num(cut)
% liited iteration cost 
% Determine the cost after n number of iterations
n = length(cut);
SP = 21; SC = 15; RC = 7; PC = 7;
USL = 6; LSL = 4;
sig = 1;

% cut = 5.5*ones(1,20);
i = 1;
Rwork = 1;
TOT = 0;
for i = 1:n
    Probs(i,1) = Rwork*(normcdf(LSL,cut(i),sig)); % scrap 
    Probs(i,2) = Rwork*(normcdf(USL,cut(i),sig) - normcdf(LSL,cut(i),sig)); % conformance
    Probs(i,3) = Rwork*(1 - normcdf(USL,cut(i),sig));
    confo = (normcdf(USL,cut(i),sig) - normcdf(LSL,cut(i),sig));
    Rwork = Probs(i,3);
    Umu= normcdf(USL,cut(i),sig);

    TOT_Scrap = sum(Probs(:,1));
    TOT_Confm = sum(Probs(:,2));
    totsp = TOT_Confm*SP;
    TOT_Rwork = sum(Probs(:,3));
    Profit = SP*TOT_Confm - PC - SC*(TOT_Scrap) - RC*(TOT_Rwork);
end
    TOT_Scrap = sum(Probs(:,1));
    TOT_Confm = sum(Probs(:,2));
    TOT_Rwork = sum(Probs(:,3));
    TOT = TOT_Confm + TOT_Scrap;
    ProdCost = PC + SC*(TOT_Scrap) + RC*(TOT_Rwork);
    Profit = SP*TOT_Confm - PC - SC*(TOT_Scrap) - RC*(TOT_Rwork); 
    
    RWORK_LEFT = Rwork;
   