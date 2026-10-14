% optimal mean setting for the angle and diameter of a cooling hole
clear all
close all
clc
% % 0.773
% MU = [0.58677 0.60649]; % MU(1) = diameter  MU(2) = Angle
% MU_rw = [0.58677];
% L = [0.33987 0.324922]; 
% U = [0.83367 0.888058];  % Upper limit is scrap as these are holes
% sig11 = 0.109687; sig22 = 0.102564;
% rho = 0.0;%  0.705

% % 0.7735
% MU = [0.57369 0.58149]; % MU(1) = diameter  MU(2) = Angle
% MU_rw = [0.57369];
% L = [0.511959 0.38679]; 
% U = [0.635421 0.77619];  % Upper limit is scrap as these are holes
% sig11 = 0.109687; sig22 = 0.102564;
% rho = 0.0;%  0.7052

% 0.7736
MU = [0.58677 0.54988]; % MU(1) = diameter  MU(2) = Angle
MU_rw = [0.5641];
L = [0.486997 0.47881]; 
U = [0.613423 0.62095];  % Upper limit is scrap as these are holes
sig11 = 0.109687; sig22 = 0.102564;
rho = 0.0;%  0.7052




% MU = [7.3  33.8920]; % MU(1) = diameter  MU(2) = Angle
% MU_rw = [7.79 33.8920]
% L = [7.22367 30.93197]; 
% U = [8.44563 36.85205];  % Upper limit is scrap as these are holes
% sig11 = 0.5; sig22 = 2;
% rho = 0;

PC = 0.0321;
SP = 0.03914 ;
SC = [1000 1000 1000 1000];
RC = [0 0.0321 0.0321 0.0642];

MUs = [MU MU_rw]
AngleDiaProfit(MUs,SP,sig11,sig22,rho,L,U,PC,SC,RC)
FUN = @(MUs) -1*AngleDiaProfit(MUs,SP,sig11,sig22,rho,L,U,PC,SC,RC);
x0 = [L(1),L(1)];
LB = [L(1)-5,L(1)-5]
UB = [U(1)+5,U(1)+5]
options = optimset('TolFun',1e-5,'TolX',1e-5,'MaxFunEvals',1000,'Display','iter');
MU_opt_vec = fminsearchcon(FUN,x0,[LB],[UB],[],[],[],options)
Opt_val = -1*FUN(MU_opt_vec)