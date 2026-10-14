
% This is just a test mfile for 'Fun_Amir_SpareseQuad_Skew'
clear all
clc
close all
A = [3 3 3]
B = [7 7 7]
Xi = [5 5 5]
Omega = [1 0 0;0 1 0; 0 0 1]
a_vec = linspace(0,2,50)
tic
for i = 1:length(a_vec)
    Alpha = ones(1,(length(A))).*1.*a_vec(i);
    [PL PU]=Fun_Amir_SparseQuad_Skew(A,B,Xi,Omega,Alpha);
    BoundRange(i) = PU-PL;
    %clear Variability
end
toc

plot(a_vec(1:35),BoundRange(1:35),'.-')

