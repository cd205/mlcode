% study link between error box ('a') size and correlation

%% 2D example
clear all
close all
clc
A = [3 3]
B = [7 7]
L = -10
mu1 = 3;
mu2 = 3;
alpha1 = 0;
alpha2 = 0;
Corr_vec = linspace(0,0.9,10)
sigma11 = 1.0;
sigma22 = 1.0;
% sigma12 = 0.9999;
% sigma21 = 0.9999;
MU = [mu1 mu2];
ALPHA = [alpha1 alpha2];
%SIGMA = [sigma11^2 sigma12^2; sigma21^2 sigma22^2]


for i=1:length(Corr_vec)
     SIGMA = [sigma11^2 Corr_vec(i)^2; Corr_vec(i)^2 sigma22^2]
    % Define bivariate skew normal function
    fun2d = @(X,Y) dmsn_quad2d(X,Y,MU,SIGMA,ALPHA) 
    % Integrate bivariate skew normal distribtuin between limits
    Fb1b2(i) = quad2d(fun2d,L,B(1),L,B(2));
    Fa1b2(i) = quad2d(fun2d,L,A(1),L,B(2));
    Fb1a2(i) = quad2d(fun2d,L,B(1),L,A(2));
    Fa1a2(i) = quad2d(fun2d,L,A(1),L,A(2));
    Conform(i) = Fb1b2(i) - Fa1b2(i) - Fb1a2(i) + Fa1a2(i);
    
    check = mvncdf([3 3],[7 7],MU,SIGMA);
    
    LB(i) = Fb1b2(i) - (Fa1b2(i) + Fb1a2(i));
    if LB(i) < 0
        LB(i) = 0
    end
    UB(i) = Fb1b2(i) - max([Fa1b2(i),Fb1a2(i)]);
end

figure(1)
plotyy(Corr_vec,Fa1a2,Corr_vec,Fa1b2./Fa1a2); grid on
xlabel('Correlation')
ylabel('Fa1a2')
