function [EP FeedIns] = EP_Dodd2014_NonAutomated(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
% expected profit from Dodd [2014] 
[f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s, P2s] = KandBMarkov_DualChars([MU(1) MU(2)],SIGMA,Lx,Ly,Ux,Uy);
fs = [f15,f25,f35,f45];
ms = [m12,m13,m14];



EP = SP*f15 - PC - SC(1)*P1s(5)...
    - SC(2)*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1))*f26...
    - SC(3)*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2))*f36...
    - SC(4)*P1s(3)*(P1s(5)/(1-P1s(3)))...
    - RC(1)*m12 - RC(2)*m13 - RC(3)*m14;

FeedIn1 = (P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1))*f26;
FeedIn2 = (P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2))*f36;
FeedIn3 = P1s(3)*(P1s(5)/(1-P1s(3)));

FeedIn1o = f26;
FeedIn2o = f36;
FeedIn3o = f46;

FeedIns = [FeedIn1 FeedIn2 FeedIn3 FeedIn1o FeedIn2o FeedIn3o];