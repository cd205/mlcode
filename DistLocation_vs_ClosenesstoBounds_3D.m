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
A = [3 3 3];
B = [7 7 7];
L = -10;
alpha1 = 0;
alpha2 = 0;
alpha3 = 0;
sigma11 = 1.0;
sigma22 = 1.0;
sigma33= 1.0;
sigma12 = 0.0;
sigma13 = 0;
sigma21 = 0.0;
sigma23 = 0;
sigma31 = 0; 
sigma32 = 0;
ALPHA = [alpha1 alpha2 alpha3];
SIGMA = [sigma11^2 sigma12^2 sigma13^2;...
        sigma21^2 sigma22^2 sigma23^2;...
        sigma31^2 sigma32^2 sigma33^2];
mu1 = linspace(4,4,num);
mu2 = linspace(4,4,num);
mu3 = linspace(2,5,num);


tic
parfor i = 1:length(mu3)
    MU = [mu1(i) mu2(i) mu3(i)];
    % Define trivariate skew normal function
%     fun3d = @(X,Y,Z) dmsn_triplequad(X,Y,Z,MU,SIGMA,ALPHA);
%     % Integrate trivariate skew normal distribtuin between limits
%     Fa1a2a3 = triplequad(fun3d,L,A(1),L,A(2),L,A(3));
%     Fa1a2b3 = triplequad(fun3d,L,A(1),L,A(2),L,B(3));
%     Fa1b2a3 = triplequad(fun3d,L,A(1),L,B(2),L,A(3));
%     Fa1b2b3 = triplequad(fun3d,L,A(1),L,B(2),L,B(3));
%     Fb1a2a3 = triplequad(fun3d,L,B(1),L,A(2),L,A(3));
%     Fb1a2b3 = triplequad(fun3d,L,B(1),L,A(2),L,B(3));
%     Fb1b2a3 = triplequad(fun3d,L,B(1),L,B(2),L,A(3));
%     Fb1b2b3 = triplequad(fun3d,L,B(1),L,B(2),L,B(3));
    
    Fa1a2a3 = mvncdf([L L L],A,MU,SIGMA); 
    Fa1a2b3 = mvncdf([L L L],[A(1),A(2),B(3)],MU,SIGMA);
    Fa1b2a3 = mvncdf([L L L],[A(1),B(2),A(3)],MU,SIGMA);
    Fa1b2b3 = mvncdf([L L L],[A(1),B(2),B(3)],MU,SIGMA);
    Fb1a2a3 = mvncdf([L L L],[B(1),A(2),A(3)],MU,SIGMA);
    Fb1a2b3 = mvncdf([L L L],[B(1),A(2),B(3)],MU,SIGMA);
    Fb1b2a3 = mvncdf([L L L],[B(1),B(2),A(3)],MU,SIGMA);
    Fb1b2b3 = mvncdf([L L L],B,MU,SIGMA);

    Conform(i) = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
        + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3
    
    %check = mvncdf([3 3],[7 7],MU,SIGMA);
    
    LB(i) = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3);
    if LB(i) < 0
        LB(i) = 0;
    end
    UB(i) = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3]);
end



toc
plot(mu3,Conform-LB,'b.-'); hold on
plot(mu3,UB-Conform,'r.-')
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
mean1 = mu1+sigma1*(alpha1/sqrt(1+alpha1^2));