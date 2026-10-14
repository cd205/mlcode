function EP = EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
% expected profit from Dodd [2014] 
[F_stageC,pIC,Rwi,Sri] = StageCostFun([MU(1) MU(2)],SIGMA,[Ux Uy],[Lx Ly],RC,SC);
EP = SP*F_stageC - (PC + Sri + Rwi);
