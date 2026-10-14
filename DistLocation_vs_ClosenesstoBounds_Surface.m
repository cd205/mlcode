% Study how moving the location of the distribution effects the nearness of
% the exact solution to the upper or lower bound
clear all
clc
close all
% Exact Solution:
%   Exact:  F(b1,b2) - F(a1,b2,) - F(b1,a2) +F(a1,a2)
% Amir:
%   LB:     F(b1,b2) - {F(a1,b2,) + F(b1,a2)}
%   UB:     F(b1,b2) - MAX {F(a1,b2,), F(b1,a2)}


A = [3 3];
B = [7 7];
L = -10;
alpha1 = 0;
alpha2 = 0;
sigma1 = 1.0;
sigma2 = 1.0;
ALPHA = [alpha1 alpha2];
SIGMA = [sigma1^2 0; 0 sigma2^2];
mu1 = linspace(1,6,50);
mu2 = linspace(1,6,50);




for i = 1:length(mu1)
    for j = 1:length(mu2)
        MU = [mu1(i) mu2(j)];
        
        Fb1b2 = mvncdf([L L],[B(1) B(2)],MU,SIGMA);
        Fa1b2 = mvncdf([L L],[A(1) B(2)],MU,SIGMA);
        Fb1a2 = mvncdf([L L],[B(1) A(2)],MU,SIGMA);
        Fa1a2 = mvncdf([L L],[A(1) A(2)],MU,SIGMA);
        Conform = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
        
        %check = mvncdf([3 3],[7 7],MU,SIGMA);
        
        LB = Fb1b2 - (Fa1b2 + Fb1a2);
        if LB < 0
            LB = 0;
        end
        UB = Fb1b2 - max([Fa1b2,Fb1a2]);
        LB_Error(j,i) = Conform - LB;
        UB_Error(j,i) = UB-Conform;
    end
end

[X Y] = meshgrid(mu1,mu2);
%surface(X, Y, LB_Error,'FaceColor', [0.5 1.0 0.5], 'EdgeColor', 'none');
%surface(X, Y, UB_Error,'FaceColor', [1.0 0.5 0.0], 'EdgeColor', 'none');
subplot(1,2,1)
surf(X,Y,LB_Error)
xlabel('mu_1')
ylabel('mu_2')
zlabel('Exact Sol - Lower Bound')
subplot(1,2,2)
surf(X,Y,UB_Error)
xlabel('mu_1')
ylabel('mu_2')
zlabel('Upper Bound - Exact Sol')
% 
% plot(mu1,Conform-LB,'b.-'); hold on
% plot(mu1,UB-Conform,'r.-')
% xlabel('Location mu1 & mu2')
% ylabel('Distance from exact solution to bounds')
grid on
