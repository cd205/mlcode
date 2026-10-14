
% This is just a test mfile for 'Fun_Amir_SpareseQuad_Skew'
clear all
clc
%close all
A = [3 3];
B = [7 7];
Xi = [5 5];
Omega = [1 0;0 1];
Alpha = [1.8 1.8];
[PL PU]=Fun_Amir_SparseQuad_Skew(A,B,Xi,Omega,Alpha);
BoundRange = PU-PL;
clear Variability

x = linspace(0,10,50);
pdf1 = dsn(x,Xi(1),Omega(1,1),Alpha(1));
pdf2 = dsn(x,Xi(2),Omega(2,2),Alpha(2));

figure(3)
subplot(1,2,1)
plot(x,pdf1,'.-')
line([A(1) A(1)],[0 max(pdf1)],'color','r')
line([B(1) B(1)],[0 max(pdf1)],'color','r')
line([Xi(1) Xi(1)],[0 max(pdf1)],'color','k')
grid on

subplot(1,2,2)
plot(x,pdf1,'.-')
line([A(2) A(2)],[0 max(pdf2)],'color','r')
line([B(2) B(2)],[0 max(pdf2)],'color','r')
line([Xi(1) Xi(1)],[0 max(pdf2)],'color','k')
grid on