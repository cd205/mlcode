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

num = 100;
A = [3 3];
B = [7 7];
L = -5;
alpha1 = 0;
alpha2 = 0;
sigma11 = 1.0;
sigma22 = 1.0;
sigma12 = 0.8;
sigma21 = 0.8;
ALPHA = [alpha1 alpha2];
SIGMA = [sigma11^2 sigma12^2; sigma21^2 sigma22^2]
mu1 = linspace(4,4,num);
mu2 = linspace(1,9,num);




for i = 1:length(mu1)
    MU = [mu1(i) mu2(i)];
    % Define bivariate skew normal function
    fun2d = @(X,Y) dmsn_quad2d(X,Y,MU,SIGMA,ALPHA);
    % Integrate bivariate skew normal distribtuin between limits
    Fb1b2 = quad2d(fun2d,L,B(1),L,B(2));
    Fa1b2 = quad2d(fun2d,L,A(1),L,B(2));
    Fb1a2 = quad2d(fun2d,L,B(1),L,A(2));
    Fa1a2 = quad2d(fun2d,L,A(1),L,A(2));
    Conform(i) = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
    
    %check = mvncdf([3 3],[7 7],MU,SIGMA);
    
    LB(i) = Fb1b2 - (Fa1b2 + Fb1a2);
    if LB(i) < 0
        LB(i) = 0;
    end
    UB(i) = Fb1b2 - max([Fa1b2,Fb1a2]);
end


plot(mu2,Conform-LB,'b.-'); hold on
plot(mu2,UB-Conform,'r.-')
xlabel('Location mu1 & mu2')
ylabel('Distance from exact solution to bounds')
legend('LB error','UB error')
grid on
% pdf1 = dsn([0:0.1:10],mu1,sigma1,alpha1);
% pdf2 = dsn([0:0.1:10],mu2,sigma2,alpha2);
% subplot(1,2,1)
% plot([0:0.1:10],pdf1,'.-')
% line([3 3], [0 0.4])
% line([7 7], [0 0.4])
% grid on
% subplot(1,2,2)
% plot([0:0.1:10],pdf2,'.-')
% line([3 3], [0 0.4])
% line([7 7], [0 0.4])
% grid on
% 
% figure(3)
% plot(LB,0,'g.','MarkerSize',30); hold on
% plot(UB,0,'r.','MarkerSize',30); hold on
% plot(Conform,0,'b.','MarkerSize',30); grid on
% 
% 
mean1 = mu1+sigma11*(alpha1/sqrt(1+alpha1^2))