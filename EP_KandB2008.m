function EP = EP_KandB2008(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
% expected profit from the K and B [2008] 
[f15,f25,f35,f45, m12,m13,m14] = KandBMarkov_DualChars([MU(1) MU(2)],SIGMA,Lx,Ly,Ux,Uy);
fs = [f15,f25,f35,f45];
ms = [m12,m13,m14];
for j = 1:4
    Scrap(j) = SC(j)*(1-fs(j));
end
for k = 1:3
    Rwork(k) = RC(k)*ms(k);
end

EP = SP*f15 - PC - sum(Scrap) - sum(Rwork);