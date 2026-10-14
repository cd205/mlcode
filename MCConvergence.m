%% Plot MC convergence

clear all
close all
clc
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');

Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;


MU = [0.5 0.5]; % MU(1) = diameter  MU(2) = Angle
sig11 = 0.109687; sig22 = 0.102564;
rho = 0.0;%  0.705
%pnts = linspace(10000,10e6,100);
tic
pnts = [1e8];% [1000 2500 5000 7500 10000 25000 50000 75000 100000 250000 500000 750000,...
    %2500000 5000000 7500000 25000000 50000000 75000000]
MinEff = 0.773
length(pnts)
% tic
%     [NC,Eff35_int] = ProbConform(Xplot,Eff35,MU,sig11,sig22,rho,pnts,MinEff);
%     meanEff35 = mean(Eff35_int(~isnan(Eff35_int)))
%     sdEff35 = std(Eff35_int(~isnan(Eff35_int)))
%     toc
tic
for i = 1:100
    [NC,Eff35_int] = ProbConform(Xplot,Eff35,MU,sig11,sig22,rho,pnts,MinEff);
    meanEff35(i) = mean(Eff35_int(~isnan(Eff35_int)));
    sdEff35(i) = std(Eff35_int(~isnan(Eff35_int)));
end
toc
% plotyy(pnts,meanEff35,pnts,sdEff35)
% grid on
% toc
% tic
% for i=1:length(pnts)
%     NC(i) = ProbConform(Xplot,Eff35,MU,sig11,sig22,rho,pnts(i),MinEff);
% end
% toc
% figure;
% plot(pnts,NC,'.-'); grid on
% %axis([100,1e6 0.035 0.055])