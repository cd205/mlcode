%% check PumpCostDetailed_SNQuad2d function
%clear all
%close all
%clc

ALPHA = [-6 -6];
a = 0.417;
b = 0.583;
c = 0.417;
d = 0.583;
sigma_L = 0.0833; 
sigma_R = 0.0667;
SIGMA = [sigma_L^2 0; 0 sigma_R^2];
MU = [0.575 0.525];

[PumpCost] = PumpCostDetailed_SNQuad2d(MU,SIGMA,ALPHA,a,b,c,d) 


% np = normpdf([0:0.01:1],MU(1),SIGMA(1,1));
% figure(1)
% plot([0:0.01:1],np,'.-')