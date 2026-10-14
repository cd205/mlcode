%function [f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s, P2s] = Markov_TriChars(MU,SIGMA,Lx,Ly,Ux,Uy)
% example
clear all
close all
clc
% MU = [6 6]
% SIGMA = [1 0; 0 1];
% Lx = 3
% Ly = 3
% Ux = 7
% Uy = 7

% sig11 = sqrt(SIGMA(1));
% sig22 = sqrt(SIGMA(2,2));
%% 
cut = [5 5 5]
A = [3 3 3];
B = [7 7 7];
sig11 = 2;
sig22 = 2;
sig33 = 2;
SIGMA = [sig11^2 0 0; 0 sig22^2 0; 0 0 sig33^2]
Fa1a2a3U = mvncdf([A(1) A(2) A(3)],[inf inf inf],cut,SIGMA);
Fa1a2b3U = mvncdf([A(1) A(2) B(3)],[inf inf inf],cut,SIGMA); % top plane
Fb1a2a3U = mvncdf([B(1) A(2) A(3)],[inf inf inf],cut,SIGMA); % right plane
Fa1b2a3U = mvncdf([A(1) B(2) A(3)],[inf inf inf],cut,SIGMA); % back plane
Fa1b2b3U = mvncdf([A(1) B(2) B(3)],[inf inf inf],cut,SIGMA); % top back 
Fb1a2b3U = mvncdf([B(1) A(2) B(3)],[inf inf inf],cut,SIGMA); % top right
Fb1b2a3U = mvncdf([B(1) B(2) A(3)],[inf inf inf],cut,SIGMA); % vertical right corner
Fb1b2b3U = mvncdf([B(1) B(2) B(3)],[inf inf inf],cut,SIGMA);

% Conform
ConformPrt = - Fb1b2b3U + Fb1b2a3U + Fb1a2b3U + Fa1b2b3U - Fa1b2a3U - Fb1a2a3U - Fa1a2b3U + Fa1a2a3U   
conformpartchk = mvncdf([A(1) A(2) A(3)],[B(1) B(2) B(3)],cut,SIGMA)

% Rework
RW1 = Fb1a2a3U - Fb1a2b3U - Fb1b2a3U + Fb1b2b3U
RW2 = Fa1b2a3U - Fa1b2b3U - Fb1b2a3U + Fb1b2b3U
RW3 = Fa1a2b3U - Fa1b2b3U - Fb1a2b3U + Fb1b2b3U
RW12 = Fb1b2a3U - Fb1b2b3U
RW13 = Fb1a2b3U - Fb1b2b3U
RW23 = Fa1b2b3U - Fb1b2b3U
RW123 = Fb1b2b3U

TotRW = RW1 + RW2 + RW3 + RW12 + RW13 + RW23 + RW123

% Scrap 
Scrap = 1 - Fa1a2a3U

ShouldEqOne = Scrap + TotRW + ConformPrt

%%
p2S = normcdf(A(1),cut(1),sig11);
p22 = 1 - normcdf(B(1),cut(1),sig11);
p3S = normcdf(A(2),cut(2),sig22);
p33 = 1 - normcdf(B(2),cut(2),sig22);
p4S = normcdf(A(3),cut(3),sig33);
p44 = 1 - normcdf(B(3),cut(3),sig33);
p5S = mvncdf([-inf,-inf],[A(1),inf],[cut(1) cut(2)],[sig11 0;0 sig22]) + ...
       mvncdf([-inf,-inf],[inf,A(2)],[cut(1) cut(2)],[sig11 0;0 sig22]) - ...
       mvncdf([-inf,-inf],[A(1),A(2)],[cut(1) cut(2)],[sig11 0;0 sig22]);
p55 = mvncdf([B(1),B(2)],[inf,inf],[cut(1) cut(2)],[sig11 0;0 sig22]);
p6S = mvncdf([-inf,-inf],[A(1),inf],[cut(1) cut(3)],[sig11 0;0 sig33]) + ...
       mvncdf([-inf,-inf],[inf,A(3)],[cut(1) cut(3)],[sig11 0;0 sig33]) - ...
       mvncdf([-inf,-inf],[A(1),A(3)],[cut(1) cut(3)],[sig11 0;0 sig33]);
p66 = mvncdf([B(1),B(3)],[inf,inf],[cut(1) cut(3)],[sig11 0;0 sig33]);
p7S = mvncdf([-inf,-inf],[A(2),inf],[cut(2) cut(3)],[sig22 0;0 sig33]) + ...
       mvncdf([-inf,-inf],[inf,A(3)],[cut(2) cut(3)],[sig22 0;0 sig33]) - ...
       mvncdf([-inf,-inf],[A(2),A(3)],[cut(2) cut(3)],[sig22 0;0 sig33]);
p77 = mvncdf([B(2),B(3)],[inf,inf],[cut(2) cut(3)],[sig22 0;0 sig33]); 
p8S = 1 - Fa1a2a3U

S2 = (RW1 + (RW12*(RW1/(1-RW12))) + (RW13*(RW1/(1-RW13))) + (RW123*(RW1/(1-RW123))))*(p210/(1-p22))
S3 = (RW2 + (RW12*(RW2/(1-RW12))) + (RW23*(RW2/(1-RW23))) + (RW123*(RW2/(1-RW123))))*(p310/(1-p33))
S4 = (RW3 + (RW13*(RW3/(1-RW13))) + (RW23*(RW3/(1-RW23))) + (RW123*(RW3/(1-RW123))))*(p410/(1-p44))

S5 = (RW12 + (RW123*(RW12/(1-RW123))))*(p510/(1-p55))
S6 = (RW13 + (RW123*(RW13/(1-RW123))))*(p610/(1-p66))
S7 = (RW23 + (RW123*(RW23/(1-RW123))))*(p710/(1-p77))

S8 = RW123*(p810/(1-RW123))
% p12 = mvncdf([Ux,Ly],[inf,Uy],MU,SIGMA);
% p13 = mvncdf([Lx,Uy],[Ux,inf],MU,SIGMA);
% p14 = mvncdf([Ux,Uy],[inf,inf],MU,SIGMA);
% p15 = mvncdf([Lx,Ly],[Ux,Uy],MU,SIGMA);
% p16 = mvncdf([-inf,-inf],[Lx,inf],MU,SIGMA) + ...
%       mvncdf([-inf,-inf],[inf,Ly],MU,SIGMA) - ...
%       mvncdf([-inf,-inf],[Lx,Ly],MU,SIGMA);
%   
% p22 = 1 - normcdf(Ux,MU(1),sig11);
% p25 = normcdf(Ux,MU(1),sig11) - normcdf(Lx,MU(1),sig11);
% p26 = normcdf(Lx,MU(1),sig11);
% p33 = 1 - normcdf(Uy,MU(2),sig22);
% p35 = normcdf(Uy,MU(2),sig22) - normcdf(Ly,MU(2),sig22);
% p36 = normcdf(Ly,MU(2),sig22);
% %p41 = p11;
% p42 = p12;
% p43 = p13;
% p44 = p14;
% p45 = p15;
% p46 = p16;
% p55 = 1;
% p56 = 0;
% 
% P1s = [p12,p13,p14,p15,p16];
% P2s = [p22];
% 
% m12 = p12/((1-p22)*(1-p44));
% m13 = p13/((1-p33)*(1-p44));
% m14 = p14/(1-p44);
% 
% %% Acceptance parts
% % NOTE: p12, p13 and p14 that multiply f25, f35 and f45 account for the
% % number of parts flowing through into these rework stages,  this could be
% % done in the cost model rather than here
% % Sum_15 = p35*p13 + p45*p14 + p55*p15;
% % Prod_15 = (1-p22)*(1-p33)*(1-p44);
% % f15 = (p25*p12*(1-p33)+(Sum_15*Prod_15))/Prod_15;
% f15 = p15 + p12*p25/((1-p22)*(1-p44)) + p13*p35/((1-p33)*(1-p44)) + p14*p45/(1-p44);
% f25 = (p25/(1-p22));%*p12;
% f35 = (p35/(1-p33));%*p13;
% %Sum_45 = p25*p12/((1-p22)*(1-p14)) + p35*p13/((1-p33)*(1-p14));
% %f45 = (p15/(1-p14)) + Sum_45;
% f45 = (p42*p25/((1-p22)*(1-p44)) + p43*p35/((1-p33)*(1-p44)) + p45/(1-p44));%*p14;
% 
% %% Scrap parts
% % NOTE: p12, p13 and p14 that multiply f26, f36 and f46 account for the
% % number of parts flowing through into these rework stages,  this could be
% % done in the cost model rather than here
% % Sum_16 = p35*p13 + p46*p14 + p56*p15;
% % Prod_16 = (1-p22)*(1-p33)*(1-p44);
% % f16 = (p26*p12*(1-p33) + (Sum_16*Prod_16))/Prod_16;
% f16 = p16 + p12*p26/((1-p22)*(1-p44)) + p13*p36/((1-p33)*(1-p44)) + p14*p46/(1-p44);
% f26 = (p26/(1-p22));%*p12;
% f36 = (p36/(1-p33));%*p13;
% %Sum_46 = p26*p16/((1-p22)*(1-p14)) + p36*p13/((1-p33)*(1-p14));
% %f46 = (p16/(1-p14)) + Sum_46;
% f46 = (p42*p26/((1-p22)*(1-p44)) + p43*p36/((1-p33)*(1-p44)) + p46/(1-p44));%*p14;
% 
% 
% 
% TotalAccpt = f15;
% TotalScrap = (1-f15) + (1-f25) + (1-f35) + (1-f45);
% TotalRWork = m12 + m13 + m14;