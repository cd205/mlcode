function [f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s, P2s] = KandBMarkov_DualChars(MU,SIGMA,Lx,Ly,Ux,Uy)
% example
% clear all
% close all
% clc
% MU = [6 6]
% sig11 = 1;
% sig22 = 1;
% SIGMA = [sig11^2 0.0;0.0 sig22^2]
% Lx = 3
% Ly = 3
% Ux = 7
% Uy = 7

sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));

p12 = mvncdf([Ux,Ly],[inf,Uy],MU,SIGMA);
p13 = mvncdf([Lx,Uy],[Ux,inf],MU,SIGMA);
p14 = mvncdf([Ux,Uy],[inf,inf],MU,SIGMA);
p15 = mvncdf([Lx,Ly],[Ux,Uy],MU,SIGMA);
p16 = mvncdf([-inf,-inf],[Lx,inf],MU,SIGMA) + ...
      mvncdf([-inf,-inf],[inf,Ly],MU,SIGMA) - ...
      mvncdf([-inf,-inf],[Lx,Ly],MU,SIGMA);
  
p22 = 1 - normcdf(Ux,MU(1),sig11);
p25 = normcdf(Ux,MU(1),sig11) - normcdf(Lx,MU(1),sig11);
p26 = normcdf(Lx,MU(1),sig11);
p33 = 1 - normcdf(Uy,MU(2),sig22);
p35 = normcdf(Uy,MU(2),sig22) - normcdf(Ly,MU(2),sig22);
p36 = normcdf(Ly,MU(2),sig22);
%p41 = p11;
p42 = p12;
p43 = p13;
p44 = p14;
p45 = p15;
p46 = p16;
p55 = 1;
p56 = 0;

P1s = [p12,p13,p14,p15,p16];
P2s = [p22];

m12 = p12/((1-p22)*(1-p44));
m13 = p13/((1-p33)*(1-p44));
m14 = p14/(1-p44);

%% Acceptance parts
% NOTE: p12, p13 and p14 that multiply f25, f35 and f45 account for the
% number of parts flowing through into these rework stages,  this could be
% done in the cost model rather than here
% Sum_15 = p35*p13 + p45*p14 + p55*p15;
% Prod_15 = (1-p22)*(1-p33)*(1-p44);
% f15 = (p25*p12*(1-p33)+(Sum_15*Prod_15))/Prod_15;
f15 = p15 + p12*p25/((1-p22)*(1-p44)) + p13*p35/((1-p33)*(1-p44)) + p14*p45/(1-p44);
f25 = (p25/(1-p22));%*p12;
f35 = (p35/(1-p33));%*p13;
%Sum_45 = p25*p12/((1-p22)*(1-p14)) + p35*p13/((1-p33)*(1-p14));
%f45 = (p15/(1-p14)) + Sum_45;
f45 = (p42*p25/((1-p22)*(1-p44)) + p43*p35/((1-p33)*(1-p44)) + p45/(1-p44));%*p14;

%% Scrap parts
% NOTE: p12, p13 and p14 that multiply f26, f36 and f46 account for the
% number of parts flowing through into these rework stages,  this could be
% done in the cost model rather than here
% Sum_16 = p35*p13 + p46*p14 + p56*p15;
% Prod_16 = (1-p22)*(1-p33)*(1-p44);
% f16 = (p26*p12*(1-p33) + (Sum_16*Prod_16))/Prod_16;
f16 = p16 + p12*p26/((1-p22)*(1-p44)) + p13*p36/((1-p33)*(1-p44)) + p14*p46/(1-p44);
f26 = (p26/(1-p22));%*p12;
f36 = (p36/(1-p33));%*p13;
%Sum_46 = p26*p16/((1-p22)*(1-p14)) + p36*p13/((1-p33)*(1-p14));
%f46 = (p16/(1-p14)) + Sum_46;
f46 = (p42*p26/((1-p22)*(1-p44)) + p43*p36/((1-p33)*(1-p44)) + p46/(1-p44));%*p14;



TotalAccpt = f15;
TotalScrap = (1-f15) + (1-f25) + (1-f35) + (1-f45);
TotalRWork = m12 + m13 + m14;