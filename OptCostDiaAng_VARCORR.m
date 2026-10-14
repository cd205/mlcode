% Study effect of correlation on cooling hole profit

clear all
close all
clc
format short
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');

Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;

npnts = 1e6
MU = [0.53 0.5]; % MU(1) = diameter  MU(2) = Angle
MU_rw = [0.4];
sig11 = 0.109687; sig22 = 0.102564;
rho = -0.8%[-0.8 -0.6 -0.4 -0.2 0.2 0.4 0.6 0.8];
MinEff = 0.773357142857143

%% Standard production
tic
for i = 1:length(rho)
FUN1 = @(INPUT) -1*funNCProfitDiaAng([INPUT(1) INPUT(2)],INPUT(1),sig11,sig22,rho(i),...
    INPUT(3),INPUT(3),INPUT(4),npnts,Xplot,Eff35,MinEff);
LB = [sig11*3 sig22*3 0.001 0.001];
UB = [1-sig11*3 1-sig22*3 10 10];
x0 = [0.53 0.6 1 1];
[bestvar1(i,:),bestobj1(i),history,eval_count]=ga(FUN1,x0,[],[],[],[],LB,UB);
options = optimset('TolFun',1e-4,'TolX',1e-4,'MaxFunEvals',800,'Display','iter')
[OPTVALSA_CorrsP8rr(i,:), fvalA_CorrsP8rr(i)] = fminsearchcon(FUN1,x0,[LB],[UB],[],[],[],options);

%[ProfitA(i),Eff35A] = funNCProfitDiaAng([OPTVALSA(1) OPTVALSA(2)],OPTVALSA(3),...
%    sig11,sig22,rho,OPTVALSA(4),OPTVALSA(4),OPTVALSA(5),npnts,Xplot,Eff35,MinEff(i));
end
OPTVALSA_CorrsP8rr
fvalA_CorrsP8rr

save('OPTVALSA_CorrsP8rr')
save('fvalA_CorrsP8rr')

%% Optimal mean setting
for i = 1:length(rho)
FUN2 = @(INPUT) -1*funNCProfitDiaAng([INPUT(1) INPUT(2)],INPUT(3),sig11,sig22,rho,...
    INPUT(4),INPUT(5),INPUT(6),npnts,Xplot,Eff35,MinEff(i));

LB = [sig11*3 sig22*3 sig11*3 0.001 0.001 0.001];
UB = [1-sig11*3 1-sig22*3 1-sig11*3 10 10 10];
x0 = [0.45 0.52 0.4 1 1 1];
[bestvar2(i,:),bestobj2(i),history,eval_count]=ga(FUN2,x0,[],[],[],[],LB,UB);
options = optimset('TolFun',1e-4,'TolX',1e-4,'MaxFunEvals',800,'Display','iter');
[OPTVALSB_CorrsP8rr(i,:) fvalB_CorrsP8rr(i)] = fminsearchcon(FUN2,bestvar2(i,:),[LB],[UB],[],[],[],options);

%[ProfitB(i),Eff35B] = funNCProfitDiaAng([OPTVALSB(1) OPTVALSB(2)],OPTVALSB(3),...
%    sig11,sig22,rho,OPTVALSB(4),OPTVALSB(5),OPTVALSB(6),npnts,Xplot,Eff35,MinEff(i));
end
toc
OPTVALSB_CorrsP8rr
fvalB_CorrsP8rr
save('OPTVALSB_CorrsP8rr')
save('fvalB_CorrsP8rr')