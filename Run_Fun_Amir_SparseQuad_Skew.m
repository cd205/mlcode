% Delete this
% This is just a test mfile for 'Fun_Amir_SpareseQuad_Skew'
clear all
clc
close all
A = [3 3 3]
B = [7 7 7]
Xi = [5 5 5]
Omega = [1 0 0; 0 1 0; 0 0 1]
Alpha = [5 5 5];
tic
[PL PU]=Fun_Amir_SparseQuad_Skew(A,B,Xi,Omega,Alpha)
toc
ExactNorm = mvncdf(A,B,Xi,Omega)
