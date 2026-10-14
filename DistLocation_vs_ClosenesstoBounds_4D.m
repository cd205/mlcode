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

num = 80;
A = [3 3 3 3];
B = [8 8 8 8];
L = -10;
alpha1 = 0;
alpha2 = 0;
alpha3 = 0;
alpha4 = 0;
sigma1 = 0.7;
sigma2 = 0.7;
sigma3 = 0.7;
sigma4 = 0.7;
ALPHA = [alpha1 alpha2 alpha3];
SIGMA = [sigma1^2 0 0 0; 0 sigma2^2 0 0; 0 0 sigma3^2 0; 0 0 0 sigma4^2];
mu1 = linspace(4,4,num);
mu2 = linspace(4,4,num);
mu3 = linspace(4,4,num);
mu4 = linspace(1,7,num);



tic
for i = 1:length(mu3)
    MU = [mu1(i) mu2(i) mu3(i) mu4(i)];
    Fa1a2a3a4 = mvncdf([L,L,L,L],[A(1),A(2),A(3),A(4)],MU,SIGMA);
    Fb1b2b3b4 = mvncdf([L,L,L,L],[B(1),B(2),B(3),B(4)],MU,SIGMA);
    
    Fb1a2a3a4 = mvncdf([L,L,L,L],[B(1),A(2),A(3),A(4)],MU,SIGMA);
    Fa1b2a3a4 = mvncdf([L,L,L,L],[A(1),B(2),A(3),A(4)],MU,SIGMA);
    Fa1a2b3a4 = mvncdf([L,L,L,L],[A(1),A(2),B(3),A(4)],MU,SIGMA);
    Fa1a2a3b4 = mvncdf([L,L,L,L],[A(1),A(2),A(3),B(4)],MU,SIGMA);
    
    Fb1b2a3a4 = mvncdf([L,L,L,L],[B(1),B(2),A(3),A(4)],MU,SIGMA);
    Fb1a2b3a4 = mvncdf([L,L,L,L],[B(1),A(2),B(3),A(4)],MU,SIGMA);
    Fb1a2a3b4 = mvncdf([L,L,L,L],[B(1),A(2),A(3),B(4)],MU,SIGMA);
    Fa1b2b3a4 = mvncdf([L,L,L,L],[A(1),B(2),B(3),A(4)],MU,SIGMA);
    Fa1b2a3b4 = mvncdf([L,L,L,L],[A(1),B(2),A(3),B(4)],MU,SIGMA);
    Fa1a2b3b4 = mvncdf([L,L,L,L],[A(1),A(2),B(3),B(4)],MU,SIGMA);
    
    Fb1b2b3a4 = mvncdf([L,L,L,L],[B(1),B(2),B(3),A(4)],MU,SIGMA);
    Fa1b2b3b4 = mvncdf([L,L,L,L],[A(1),B(2),B(3),B(4)],MU,SIGMA);
    Fb1a2b3b4 = mvncdf([L,L,L,L],[B(1),A(2),B(3),B(4)],MU,SIGMA);
    Fb1b2a3b4 = mvncdf([L,L,L,L],[B(1),B(2),A(3),B(4)],MU,SIGMA);
    
    Conform(i) = + Fa1a2a3a4 + Fb1b2b3b4...
        - Fb1a2a3a4 - Fa1b2a3a4 - Fa1a2b3a4 - Fa1a2a3b4...
        + Fb1b2a3a4 + Fb1a2b3a4 + Fb1a2a3b4 + Fa1b2b3a4 + Fa1b2a3b4 + Fa1a2b3b4...
        - Fb1b2b3a4 - Fa1b2b3b4 - Fb1a2b3b4 - Fb1b2a3b4;
    
    
    LB(i) = Fb1b2b3b4 - (Fa1b2b3b4 + Fb1a2b3b4 + Fb1b2a3b4 + Fb1b2b3a4);
    if LB(i) < 0
        LB(i) = 0;
    end
    UB(i) = Fb1b2b3b4 - max([Fa1b2b3b4,Fb1a2b3b4,Fb1b2a3b4,Fb1b2b3a4]);
end



toc
plot(mu4,Conform-LB,'b.-'); hold on
plot(mu4,UB-Conform,'r.-')
xlabel('Location mu4')
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
mean1 = mu1+sigma1*(alpha1/sqrt(1+alpha1^2));