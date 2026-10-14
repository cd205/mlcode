function [EP,Scrap,Rwork] = D1_D2_CostModel(MU,SIGMA,Lx,Ly,Ux,Uy)
SP = 100;
PC = 10;
RC = [0 5 5 10];
SC = [80 85 85 90];

[f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s] = Fun_Norm_Markov_DualChars(MU,SIGMA,Lx,Ly,Ux,Uy);
f1s = [f15, f25*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
    f35*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2))...
    P1s(3)*(P1s(4)/(1-P1s(3)))];
f2s = [f16, f26*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
    f36*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2)),...
    P1s(3)*(P1s(5)/(1-P1s(3)))];
ms = [m12,m13,m14];

Scrap = SC(1)*P1s(5) + SC(2)*f2s(2) + SC(3)*f2s(3) + SC(4)*f2s(4);
Rwork = RC(2)*m12 + RC(3)*m13 + RC(4)*m14;
EP = SP*f15 - PC - Scrap - Rwork;