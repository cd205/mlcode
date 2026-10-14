 % check 3D CMC copula integrates to 1
 clear all
 clc
cuts = [7 7 7 6 6 5];
CUT1 = [cuts(1) cuts(2) cuts(3)];
CUT2 = [cuts(4) cuts(5) cuts(6)];

tic
q = triplequad(@fun_3D_Copula_dist,0,10,0,10,0,10,0.000001)
toc
% 
% tic
% q = triplequad(@fun_3D_Copula_dist_V2,0,10,0,10,0,10,0.000001)
% toc