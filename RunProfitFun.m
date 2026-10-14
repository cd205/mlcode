% test the profit by variying the mean
clear all
close all
clc
format short
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');

Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;
[XPLOT YPLOT] = meshgrid(Xplot,Xplot);
%% Means standard production
% MU = [0.4654 0.5390]; % ---------- eta = 0.77345 ------------
% MU_rw = [MU(1)];
% z1l = 0.090; z1u = z1l; z2 = 0.2232

%% Means OMS
% MU = [0.4121 0.5245]; % ---------- eta = 0.77345 ------------
% MU_rw = [0.3811];
% z1l = 0.099; z1u = 9.6017; z2 = 0.5592

MU = [0.4213 0.5353]; % ---------- eta = 0.7728 ------------
MU_rw = [0.4477];
z1l = .2260; z1u = 9.9546; z2 = 1.3290

sig11 = 0.109687; sig22 = 0.102564;
rho = 0.0;%  0.7052



npnts = 1e6
MinEff = 0.77336

[Profit,NC,Eff,ProdCost,TOTCrnd] = funNCProfitDiaAng_DETAIL([MU(1) MU(2)],MU_rw,sig11,sig22,...
    rho,z1l,z1u,z2,npnts,Xplot,Eff35,MinEff(1));
Profit
ProdCost

FUN1 = @(INPUT) -1*funNCProfitDiaAng_DETAIL([INPUT(1) INPUT(2)],INPUT(1),sig11,sig22,rho,...
    INPUT(3),INPUT(3),INPUT(4),npnts,Xplot,Eff35,MinEff);


figure;
contourf(XPLOT, YPLOT,Eff35,100); hold on
plot(TOTCrnd(:,1),TOTCrnd(:,2),'+')