function [df,PRwork,PScrap] = Fun_Reverse_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL)

cut1R = LSL+(USL-cut1);  % convert cut1 from near to USL to near LSL
cut2R = LSL+(USL-cut2);  % convert cut2 from near to USL to near LSL

PScrap = (1 - normcdf(USL,cut1R,sigma1)) + (1 - normcdf(USL,cut2R,sigma2));
PRwork = normcdf(LSL,cut1R,sigma1);
 
for i = 1:length(x)
    if x(i) >= LSL  % Conformance from first cut
        df(i) = normpdf(x(i),cut1R,sigma1) + PRwork.*normpdf(x(i),cut2R,sigma1);
    elseif x(i) < LSL
        df(i) = PRwork.*normpdf(x(i),cut2R,sigma1);
    end
end

