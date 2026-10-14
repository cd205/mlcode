% Monte Carlo integration of 3D rectangular probability


clear all
close all
clc
flag = 1;
Reverse = 1;
CUT1 = [7 6 4.5];
CUT2 = [5 5 5];
sigma1_D = [0.8 0.8 0.8];
sigma2_D = [0.8 0.8 0.8];
A = [3 3 3];
B = [7 7 7];
range = [0 15] 
num = length(A);
Upper = 9; % lower bound to integrate from
% if Reverse == 1
%     Ar = B;
%     Br = A;
%     A = Ar
%     B = Br
% end


options = spset('GridType','Gauss-Patterson','Vectorized','on','RelTol',1e-6,'AbsTol',1e-9,'MaxPoints',25000,'DimensionAdaptive','on','DimadaptDegree',1);
% Create the input vector for fnorm [x1,x2,...,xn].  The method used here 
% is not very elegent but surfices
[mvd,x,y,z] = mvnCMCdist(CUT1,CUT2,sigma1_D,sigma2_D,A,B,range,flag);
funCMC3d = @(X,par) interp3(x,y,z,mvd,X(1),X(2),X(3));

%% MC int
n = 100000 % more points = more accuracy. Relative error goes as 1/sqrt(n)
opt.maxArray = 1e5;
opt.noerror = 0;
%opt.tol = 2e-4;
opt.time = 60;
opt.warnOff = 0;

h.b = [ [3,10];[3,10];[3,10]];
h.cond = {};
h.funcs = {funCMC3d};
F_A_mc = mcint(h,n,opt);