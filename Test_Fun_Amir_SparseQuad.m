%test fun amir spareQuad
clear all
clc
close all

% A = [3 3];
% B = [7 7];
% Mu = [4 4.5];
% Sigma = [1 1];
% 
% start2d=tic
% [PL PU]=Fun_Amir_SparseQuad(A,B,Mu,Sigma)
% Time_2D = toc(start2d)
% 
% 
% A = [0.3 0.3];
% B = [0.7 0.7];
% Mu = [0.4 0.45];
% Sigma = [0.1 0.1];
% 
% start2db = tic 
% [PL PU]=Fun_Amir_SparseQuad(A,B,Mu,Sigma)
% Time_2Db = toc(start2db)
% 
% 
% A = [3 3 3 3];
% B = [7 7 7 7];
% Mu = [4 5 5 3.7];
% Sigma = [1 0.9 0.8 1];
% 
% start4d = tic 
% [PL PU]=Fun_Amir_SparseQuad(A,B,Mu,Sigma)
% Time_4D = toc(start4d)


A = [3 3 3];
B = [7 7 7];
CUT1 = [5 5 5];
CUT2 = [5 5 5];
NOM = [5 5 5];
sigma1_D = [0.1 0.1 0.1];
sigma2_D = sigma1_D;
%[PL PU]=Fun_Amir_SparseQuad_CMC(CUT1,CUT2,sigma1_D,sigma2_D,A,B,NOM)

funCMC3d =  @(X,Y,Z) cmc_triplequad(X,Y,Z,CUT1,CUT2,sigma1_D,sigma2_D,A,B)
nf = @(X,Y,Z) mvnpdf([X,Y,Z],CUT1,sigma1_D)

X = 5
Y = X;
Z = X;

f1 = Fun_Cut_Measure_Cut_Dist(5,CUT1(1),CUT2(1),sigma1_D(1),sigma2_D(2),A(1),B(1))
n1 = normpdf(5,5,sigma1_D(1))
m = mvnpdf([5,5,5],[5 5 5],sigma1_D)

p = funCMC3d(X,Y,Z)
p2 = nf(X',Y',Z')

plot(Y,p,'b+'), hold on
plot(X,p2,'r.')
