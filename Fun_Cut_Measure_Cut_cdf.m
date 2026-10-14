function [df,PRwork] = Fun_Cut_Measure_Cut_cdf(x)
cut1 = 7;
cut2 = 5;
sigma1 = 1;
sigma2 = sigma1;
LSL = 3;
USL = 7;
PRwork = 1-normcdf(USL,cut1,sigma1);
 
for i = 1:length(x)
    if x(i) <= USL  % Conformance from first cut
        df(i) = normcdf(x(i),cut1,sigma1) + PRwork.*normcdf(x(i),cut2,sigma1);
    elseif x(i) > USL
        df(i) = normcdf(x(i),cut1,sigma1)+PRwork.*normcdf(x(i),cut2,sigma1);
    end
end

