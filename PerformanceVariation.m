% Performance vairation 
% plot the mean and standard deviation of performance using a Monte-Carlo
% method
clear all
close all
clc
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');

Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;

npnts = 1e6
MU = [0.53 0.5]; % MU(1) = diameter  MU(2) = Angle
MU_rw = [0.4];
sig11 = 0.109687; sig22 = 0.102564;
rho = 0.0;%  0.7052
z1l = .5; z1u = 0.5; z2 = .5;
%MinEff = linspace(0.7728,0.77345,8)
%MinEff = [0.7735429,  0.7736357]
MinEff = [0.7728]
tic
[Profit,Eff35A,Eff35] = funNCProfitDiaAng([MU(1) MU(2)],MU_rw,sig11,sig22,...
    rho,z1l,z1u,z2,npnts,Xplot,Eff35,MinEff(1));
toc

hist(Eff35(:),30); grid on