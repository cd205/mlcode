% Speed comparisons
% 1. Calcuating from CDF
% 2. Calculating from univarite PDFs
% 3. Multipling precacluated terms
clear all 
close all
clc
nums = 10000
A = [3 3 3];
B = [8 8 8];
MU = [3 3 3];
sig1 = 0.7;
sig2 = 0.7;
sig3 = 0.7;
rho1 = 0.1
rho2 = 0
rho3 = 0
SIGMA = [sig1^2 rho1*sig1*sig2 rho2*sig1*sig3;...
         rho1*sig2*sig1 sig2^2 rho3*sig2*sig3;
         rho2*sig3*sig1 rho3*sig3*sig2 sig3^2]
Fa1a2a3 = mvncdf(A,MU,SIGMA)

time1 = tic;
for i = 1:nums
    Fa1a2b3P = mvncdf([A(1) A(2) B(3)],MU,SIGMA) - Fa1a2a3;
end
Fa1a2b3P
toc(time1)

time2 = tic;
for i = 1:nums
    Fa1a2b3P = normcdf(A(1),MU(1),sig1)*...
               normcdf(A(2),MU(2),sig2)*...
               normcdf(B(3),MU(3),sig3)-Fa1a2a3;
end
Fa1a2b3P
toc(time2)/nums

time3 = tic;
for i = 1:nums
    Fa1a2b3P = Fa1a2a3 *0.5;
end
Fa1a2b3P
toc(time3)/nums