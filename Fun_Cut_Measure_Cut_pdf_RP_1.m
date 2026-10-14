function [df,PRwork,PScrap] = Fun_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL)

PScrap = normcdf(LSL,cut1,sigma1) + normcdf(LSL,cut2,sigma2);
PRwork = 1-normcdf(USL,cut1,sigma1);


% Cdodd (11/06/13) think the PScrap calc is wrong, get scrap from 
% integrating final distirbution form -inf to LSL

for i = 1:length(x)
    if x(i) <= USL  % Conformance from first cut
        df(i) = normpdf(x(i),cut1,sigma1) + PRwork.*normpdf(x(i),cut2,sigma1);
    elseif x(i) > USL
        df(i) = PRwork.*normpdf(x(i),cut2,sigma1);
    end
end
