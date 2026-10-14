% Delete this
% This is just a test mfile for 'Fun_Amir_SpareseQuad'
clear all
clc
close all
A = [3 3 3 3]
 B = [7 7 7 7]
 Mu = [5 5 5 5]
Sigma = [0.5 0.5 0.5 0.5]
tic
[PL PU]=Fun_Amir_SparseQuad(A,B,Mu,Sigma)
toc
Exact = mvncdf(A,B,Mu,Sigma)
