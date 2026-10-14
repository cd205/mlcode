% Study the 2D conformance problem
clear all
clc
close all
% Exact Solution:
%   Exact:  F(b1,b2) - F(a1,b2,) - F(b1,a2) +F(a1,a2)
% Amir:
%   LB:     F(b1,b2) - {F(a1,b2,) + F(b1,a2)}
%   UB:     F(b1,b2) - MAX {F(a1,b2,), F(b1,a2)}
sigmas = linspace(-0.79,0.79,100);
for i = 1:length(sigmas)
    A = [3 3];
    B = [7 7];
    L = -10;
    mu1 = 3;
    mu2 = 3;
    alpha1 = 0;
    alpha2 = 0;
    sigma11 = 0.7;
    sigma22 = 0.7;
    if sigmas(i) < 0
        sigmacorr = sigmas(i)^2;
        sigmacorr  = -1*sigmacorr;
    elseif sigmas(i) > 0
        sigmacorr = sigmas(i)^2;
    elseif sigmas(i) == 0
        sigmacorr = 0;
    end
    sigmacorr_vec(i) = sigmacorr;
    SIGMA12 = sigmacorr;
    SIGMA21 = sigmacorr;
    MU = [mu1 mu2];
    ALPHA = [alpha1 alpha2];
    SIGMA = [sigma11^2 SIGMA12; SIGMA21 sigma22^2];
    %sigmacorr = sigmas(i)
    % Define bivariate skew normal function
    fun2d = @(X,Y) dmsn_quad2d(X,Y,MU,SIGMA,ALPHA);
    
    % Integrate bivariate skew normal distribtuin between limits
    Fb1b2(i) = quad2d(fun2d,L,B(1),L,B(2));
    Fa1b2(i) = quad2d(fun2d,L,A(1),L,B(2));
    Fb1a2(i) = quad2d(fun2d,L,B(1),L,A(2));
    Fa1a2(i) = quad2d(fun2d,L,A(1),L,A(2));
    Conform = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
    
    check = mvncdf([3 3],[7 7],MU,SIGMA);
    
    LB = Fb1b2(i) - (Fa1b2(i) + Fb1a2(i));
    if LB < 0
        LB = 0;
    end
    UB = Fb1b2(i) - max([Fa1b2(i),Fb1a2(i)]);
   
end
 plot(sigmacorr_vec,Fa1a2,'.-'); hold on; grid on
 plot(sigmacorr_vec,Fb1a2,'r.-'); hold on
 plot(sigmacorr_vec,Fa1b2,'c.-'); hold on
 %plot(sigmas,Fb1b2,'k.-');
 legend('Fa1a2','Fb1a2','Fa1b2')
 xlabel('correlation')
 ylabel('Probability')
 
 u=linspace(0,10,500); 
 [x1,x2]=meshgrid(u);
 X = [x1(:) x2(:)];
 P = mvnpdf(X,[mu1 mu2],SIGMA);
 P = reshape(P,length(u),length(u));
 figure;
 subplot(1,2,1);
 contour(x1,x2,P);
 xlabel('x_1')
 ylabel('x_2')
 %title('Gaussian Copula');
 axis square;
 subplot(1,2,2);
 mesh(x1,x2,P);
 xlabel('x_1')
 ylabel('x_2')
 zlabel('Probability Density')
%

%     s1 = struct('Fb1b2',Fb1b2,'Fa1b2',Fa1b2,'Fb1a2',Fb1a2,'Fa1a2',Fa1a2,...
%         'Conform',Conform)
%     
%     pdf1 = dsn([0:0.1:10],mu1,sigma11,alpha1);
%     pdf2 = dsn([0:0.1:10],mu2,sigma22,alpha2);
%     subplot(1,2,1)
%     plot([0:0.1:10],pdf1,'.-')
%     line([3 3], [0 0.4])
%     line([7 7], [0 0.4])
%     grid on
%     subplot(1,2,2)
%     plot([0:0.1:10],pdf2,'.-')
%     line([3 3], [0 0.4])
%     line([7 7], [0 0.4])
%     grid on
%     
%     figure(3)
%     plot(LB,0,'g.','MarkerSize',30); hold on
%     plot(UB,0,'r.','MarkerSize',30); hold on
%     plot(Conform,0,'b.','MarkerSize',30); grid on
%     
% 
% mean1 = mu1+sigma11*(alpha1/sqrt(1+alpha1^2))*(sqrt(2/pi))