function de = extra_CMC(x,d,pRW,cut1,cut2,simga1,sigma2,LSL,USL)

        
for i = 1:length(x)
    if x(i) <= USL
        de(i) = d(i) + pRW.*normpdf(x(i),cut1,1);
    elseif x(i) > USL
        de(i) = pRW.*normpdf(x(i),cut1,1);
    end
end