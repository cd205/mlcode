% CMC 3D exact solution 
clear all
close all
clc
tic
CUT1 = [7 6 4.5];
CUT2 = [5 5 5];
sigma1_D = [0.8 0.8 0.8];
sigma2_D = [0.8 0.8 0.8];
A = [3 3 3];
B = [7 7 7];
range = [-5 10]
flag = 1
num = length(A);

Lower = 0; % lower bound to integrate from

options = spset('GridType','Clenshaw-Curtis','Vectorized','on','RelTol',1e-6,'AbsTol',1e-9,'MaxPoints',100000,'DimensionAdaptive','on','DimadaptDegree',1);
% Create the input vector for fnorm [x1,x2,...,xn].  The method used here 
% is not very elegent but surfices

[mvd,x,y,z] = mvnCMCdist(CUT1,CUT2,sigma1_D,sigma2_D,A,B,range,flag);
funCMC3d = @(x1,x2,x3) interp3(x,y,z,mvd,x1,x2,x3)
z1 = spvals(funCMC3d,num,[Lower A(1);Lower A(2);Lower A(3)],options)
z2 = spvals(funCMC3d,num,[Lower A(1);Lower A(2);Lower B(3)],options)
z3 = spvals(funCMC3d,num,[Lower A(1);Lower B(2);Lower A(3)],options)
z4 = spvals(funCMC3d,num,[Lower A(1);Lower B(2);Lower B(3)],options)
z5 = spvals(funCMC3d,num,[Lower B(1);Lower A(2);Lower A(3)],options)
z6 = spvals(funCMC3d,num,[Lower B(1);Lower A(2);Lower B(3)],options)
z7 = spvals(funCMC3d,num,[Lower B(1);Lower B(2);Lower A(3)],options)
z8 = spvals(funCMC3d,num,[Lower B(1);Lower B(2);Lower B(3)],options)

Fa1a2a3 = spquad(z1)
Fa1a2b3 = spquad(z2)
Fa1b2a3 = spquad(z3)
Fa1b2b3 = spquad(z4)
Fb1a2a3 = spquad(z5)
Fb1a2b3 = spquad(z6)
Fb1b2a3 = spquad(z7)
Fb1b2b3 = spquad(z8)

Conform = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
    + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3
toc

