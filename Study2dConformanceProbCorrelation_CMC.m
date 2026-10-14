% Study the 2D conformance problem
clear all
clc
close all
CUT1 = [7 6]
CUT2 = [5 5]
sigmadim1 = 1;
sigmadim2 = 1;
A = [3 3];
B = [7 7];
u=linspace(0,10,50); 
[x,y]=meshgrid(u); % create the grid (the points) on which the functions are evaluated


a = Fun_Cut_Measure_Cut_Dist(x,CUT1(1),CUT2(1),sigmadim1,sigmadim1,A(1),B(2));
b = Fun_Cut_Measure_Cut_Dist(y,CUT1(2),CUT2(2),sigmadim2,sigmadim2,A(2),B(2));
for i = 1:length(u)
    u(i,:) = cumtrapz(x(i,:),a(i,:));
end
for i = 1:length(u)
    v(:,i) = cumtrapz(y(:,i),b(:,i));
end
figure(1)
subplot(1,2,1)
plot(x(1,:),a(1,:),'LineWidth',2);hold on
plot(y(:,1),b(:,1),'r','LineWidth',2); grid on
xlabel('x_i')
ylabel('Probability Density')
legend('x_1','x_2')
line([A(1) A(1)],[0 max(max(max(b)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
line([B(1) B(1)],[0 max(max(max(b)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
subplot(1,2,2)
plot(x(1,:),u(1,:),'LineWidth',2);hold on
plot(y(:,1),v(:,1),'r','LineWidth',2);grid on
xlabel('x_i')
ylabel('Cumulative Density')
legend('x_1','x_2')
sigmas = linspace(-0.9,0.9,20);
for i = 1:length(sigmas)
    if sigmas(i) < 0
        sigmacorr = sigmas(i)^2;
        sigmacorr  = -1*sigmacorr;
    elseif sigmas(i) > 0
        sigmacorr = sigmas(i)^2;
    elseif sigmas(i) == 0
        sigmacorr = 0;
    end
    sigmacorr_vec(i) = sigmacorr;
    p = [1 sigmacorr; sigmacorr 1]; % parameter of Gaussian copula
    Cols_LSL_a = find(x(1,:)<=A(1));
    Rows_LSL_a = find(y(:,1)<=A(1));
    Cols_USL_b = find(x(1,:)>=B(1)); % find all elements >= to USL in x matrix
    Rows_USL_b = find(y(:,1)>=B(1)); % find all elements >= to USL in y matrix
        
    % Integrate bivariate distribtuin between limits
    Fb1b2(i) = copulacdf('Gaussian',[u(1,Cols_USL_b(1)),v(Rows_USL_b(1),1)],p);
    Fa1b2(i) = copulacdf('Gaussian',[u(1,Cols_LSL_a(end)),v(Rows_USL_b(1),1)],p);
    Fb1a2(i) = copulacdf('Gaussian',[u(1,Cols_USL_b(1)),v(Rows_LSL_a(end),1)],p);
    Fa1a2(i) = copulacdf('Gaussian',[u(1,Cols_LSL_a(end)),v(Rows_LSL_a(end),1)],p);
    
    Conform = Fb1b2(i) - Fa1b2(i) - Fb1a2(i) + Fa1a2(i);
    
    checkNormal = mvncdf([3 3],[7 7],CUT2,p);
    
    LB(i) = Fb1b2(i) - (Fa1b2(i) + Fb1a2(i));
    if LB(i) < 0
        LB(i) = 0;
    end
    UB(i) = Fb1b2(i) - max([Fa1b2(i),Fb1a2(i)]);
    
end
figure;
 plot(sigmas,Fa1a2,'.-'); hold on; grid on
 plot(sigmas,Fb1a2,'r.-'); hold on
 plot(sigmas,Fa1b2,'c.-'); hold on
 %plot(sigmas,Fb1b2,'k.-'); hold on
 %plot(sigmas,Fb1b2,'k.-');
 legend('Fa1a2','Fb1a2','Fa1b2')
 xlabel('correlation')
 ylabel('Probability')
 
 pdf = copulapdf('Gaussian',[u(:),v(:)],p);
 f = copulacdf('Gaussian',[u(:),v(:)],p); %compute the pdf of gaussian copula
 pdfd = reshape(pdf,50,50).*a.*b;
 mvd = reshape(f,50,50);%.*a.*b; % create multivariate density from the product
% of the copula pdf and the marginal pdfs
 
 figure;
 subplot(1,2,1);
 contour(x,y,pdfd);
 xlabel('x_1')
 ylabel('x_2')
 %title('Gaussian Copula');
 axis square;
 subplot(1,2,2);
 mesh(x,y,pdfd);
 xlabel('x_1')
 ylabel('x_2')
 zlabel('Probability Density')
 
 figure;
 subplot(1,2,1);
 contour(x,y,mvd);
 xlabel('x_1')
 ylabel('x_2')
 %title('Gaussian Copula');
 axis square;
 subplot(1,2,2);
 mesh(x,y,mvd);
 xlabel('x_1')
 ylabel('x_2')
 zlabel('Cumulative Density')
    
    %
    % sigmas = linspace(-0.79,0.79,100);
    % for i = 1:length(sigmas)
    %     A = [3 3];
    %     B = [7 7];
    %     L = -10;
    %     mu1 = 3;
    %     mu2 = 3;
    %     alpha1 = 0;
    %     alpha2 = 0;
    %     sigma11 = 0.8;
    %     sigma22 = 0.8;
    %     sigma12 = sigmas(i);
    %     sigma21 = sigmas(i);
    %     MU = [mu1 mu2];
    %     ALPHA = [alpha1 alpha2];
    %     SIGMA = [sigma11^2 sigma12^2; sigma21^2 sigma22^2];
    %
    %     % Define bivariate skew normal function
    %     fun2d = @(X,Y) dmsn_quad2d(X,Y,MU,SIGMA,ALPHA);
    %
    %     % Integrate bivariate skew normal distribtuin between limits
    %     Fb1b2(i) = quad2d(fun2d,L,B(1),L,B(2));
    %     Fa1b2(i) = quad2d(fun2d,L,A(1),L,B(2));
    %     Fb1a2(i) = quad2d(fun2d,L,B(1),L,A(2));
    %     Fa1a2(i) = quad2d(fun2d,L,A(1),L,A(2));
    %     Conform = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
    %
    %     check = mvncdf([3 3],[7 7],MU,SIGMA);
    %
    %     LB = Fb1b2(i) - (Fa1b2(i) + Fb1a2(i));
    %     if LB < 0
    %         LB = 0;
    %     end
    %     UB = Fb1b2(i) - max([Fa1b2(i),Fb1a2(i)]);
    %
    % end
    %  plot(sigmas,Fa1a2,'.-'); hold on; grid on
    %  plot(sigmas,Fb1a2,'r.-'); hold on
    %  %plot(sigmas,Fb1b2,'k.-');
    %  xlabel('correlation')
    %  ylabel('Probability')
    % %