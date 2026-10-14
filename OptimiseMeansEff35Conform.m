
clear all
close all
clc
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');

Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;

pnts = 1e7
MU = [0.58677 0.60649]; % MU(1) = diameter  MU(2) = Angle
%MU_rw = [0.58677];
LSL = [0.33987 0.324922]; 
USL = [0.83367 0.888058];  % Upper limit is scrap as these are holes
sig11 = 0.109687; sig22 = 0.102564;
rho = 0.0;%  0.705

% tic
% [NC,Eff35_int] = ProbConform(Xplot,Eff35,[.5 .5],sig11,sig22,rho,pnts,pnts);
% toc

S = @(MU) ProbConform(Xplot,Eff35,MU,sig11,sig22,rho,pnts,MinEff);
x0 = [.5 .5]
LB = LSL;
UB = USL;
tic
MinEff = linspace(0.7728,0.7736,15)
for i = 1:length(MinEff)
    FUN = @(MU) ProbConform(Xplot,Eff35,MU,sig11,sig22,rho,pnts,MinEff(i));
    options = optimset('TolFun',1e-4,'TolX',1e-4,'MaxFunEvals',300,'Display','iter');
    MU_opt_vec(i,:) = fminsearchcon(FUN,x0,[LB],[UB],[],[],[],options);
    [NC,Eff35_int] = ProbConform(Xplot,Eff35,MU_opt_vec(i,:),sig11,sig22,rho,pnts,MinEff(i));
    NCVec(i) = NC
end
toc
SC = 1000
figure;
plot(MinEff,NCVec*SC,'.-')

figure;
contourf(Xplot,Xplot,Eff35); hold on; grid on
plot(MU_opt_vec(1),MU_opt_vec(2),'g.')
line([MU_opt_vec(1)-3*sig11 MU_opt_vec(1)-3*sig11],[0 1],'Color',[0 0 1])
line([MU_opt_vec(1)+3*sig11 MU_opt_vec(1)+3*sig11],[0 1],'Color',[0 0 1])
line([0 1],[MU_opt_vec(2)-3*sig22 MU_opt_vec(2)-3*sig22],'Color',[0 0 1])
line([0 1],[MU_opt_vec(2)+3*sig22 MU_opt_vec(2)+3*sig22],'Color',[0 0 1])
