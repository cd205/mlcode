% Bivariate CMC CDF dist Copula[x,y]=meshgrid(u); % create the grid (the points) on which the functions are evaluated
close all
clear all
clc
cut1 = 6;
cut2 = 5;
sigmaN = 1
sigma1 = 1;
sigma2 = 1;
LSL = 3;
USL = 7;
nums = 20

u=linspace(0,10,nums); % 1000 equidistant numbers

[x,y]=meshgrid(u); % create the grid (the points) on which the functions are evaluated


%a = normpdf(x,5,sigmaN); % compute standard normal pdf values for x
[a RworkP_a ScrapP_a] = Fun_Cut_Measure_Cut_Dist(x,cut1,cut2,sigma1,sigma2,LSL,USL);
[b RworkP_b ScrapP_b] = Fun_Cut_Measure_Cut_Dist(y,cut1,cut2,sigma1,sigma2,LSL,USL);
figure(1)
subplot(1,2,1)
plot(x(1,:),a(1,:),'LineWidth',2);hold on
plot(y(:,1),b(:,1),'r','LineWidth',2); grid on
xlabel('x_i')
ylabel('Probability Density')
legend('Normal distribution','Cut-measure-cut distribution')
line([LSL LSL],[0 max(max(max(b)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
line([USL USL],[0 max(max(max(b)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
for i = 1:length(u)
    u(i,:) = cumtrapz(x(i,:),a(i,:));
end
%u = normcdf(x,5,sigmaN); % compute standard normal cdf values for x
%v = normcdf(y,3,0.7); % compute t3 cdf values for y
for i = 1:length(u)
    v(:,i) = cumtrapz(y(:,i),b(:,i));
end
figure(1)
subplot(1,2,2)
plot(x(1,:),u(1,:),'LineWidth',2);hold on
plot(y(:,1),v(:,1),'r','LineWidth',2);grid on
xlabel('x_i')
ylabel('Cumulative Density')
line([LSL LSL],[0 max(max(max(u)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
line([USL USL],[0 max(max(max(u)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
legend('Normal distribution','Cut-measure-cut distribution')

f = copulacdf('Gaussian',[u(:),v(:)],0.0); %compute the pdf of gaussian copula
mvd = reshape(f,nums,nums);%.*u.*v; % create multivariate density from the product
% of the copula pdf and the marginal pdfs
% reshape f to avoid matrix
% dimension conflicts

% LowLSLx = x<=LSL;                       % find all elements <= to LSL
% [rx cx] = size(LowLSL);                 % return the size of LowLSL 
% ColLowLSLx = sum(LowLSLx(:))/c          % calc which column LSL is in
% RowLowLSLx = sum(LowLSLx(:,ColLowLSLx)) % calc which row LSL is in 

Cols_USL = find(x(1,:)>=USL);   % find all elements >= to USL in x matrix
Rows_USL = find(y(:,1)>=USL);   % find all elements >= to USL in y matrix
xUSL = x(1,Cols_USL(1))
yUSL = y(Rows_USL(1),1)

Cols_LSL = find(x(1,:)<=LSL);   % find all elements >= to USL in x matrix
Rows_LSL = find(y(:,1)<=LSL);   % find all elements >= to USL in y matrix
xLSL = x(1,Cols_LSL(end))
yLSL = y(Rows_LSL(end),1)


Fb1b2 = copulacdf('Gaussian',[u(1,Cols_USL(1)),v(Rows_USL(1),1)],0.0)
%CDFUSL = mvd(Rows_USL(1),Cols_USL(1))
Fb1a2 = copulacdf('Gaussian',[u(1,Cols_USL(1)),v(Rows_LSL(end),1)],0.0)
Fa1b2 = copulacdf('Gaussian',[u(1,Cols_LSL(end)),v(Rows_USL(1),1)],0.0)
Fa1a2 = copulacdf('Gaussian',[u(1,Cols_LSL(end)),v(Rows_LSL(end),1)],0.0)

ScrapP = Fb1a2 + Fa1b2 - Fa1a2

figure;
subplot(1,2,1);
contour(x,y,mvd);
xlabel('x_1')
ylabel('x_2')
grid on
%title('Gaussian Copula');
axis square;
subplot(1,2,2);
mesh(x,y,mvd);

xlabel('x_1')
ylabel('x_2')
zlabel('Cumulative Density')
axis square;


figure;
subplot(1,2,1)
plot(x(1,:),u(1,:),'LineWidth',2);hold on
plot(y(:,1),v(:,1),'r','LineWidth',2);grid on
xlabel('x_i')
ylabel('Cumulative Density')
line([LSL LSL],[0 max(max(max(u)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([USL USL],[0 max(max(max(u)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
legend('Normal distribution','Cut-measure-cut distribution')
%title('Gaussian Copula');
axis square;
subplot(1,2,2);
surf(x,y,mvd,'LineStyle','none');
alpha 0.7
xlabel('x_1')
ylabel('x_2')
zlabel('Cumulative Density')
axis square;
line([0 0],[0 10],[0.002 0.002],'color',[1 0 0],'LineWidth',3) 
line([3 3],[3 10],[0.002 0.002],'color',[1 0 0],'LineWidth',3)
line([0 10],[0 0],[0.002 0.002],'color',[1 0 0],'LineWidth',3)
line([3 10],[3 3],[0.002 0.002],'color',[1 0 0],'LineWidth',3) 
line([0 3],[10 10],[0.002 0.002],'color',[1 0 0],'LineWidth',3) 
line([10 10],[0 3],[0.002 0.002],'color',[1 0 0],'LineWidth',3)
line([3 10],[10 10],[0.002 0.002],'color',[0 1 0],'LineWidth',3)
line([3 7],[7 7],[0.002 0.002],'color',[0 1 0],'LineWidth',3)
line([10 10],[3 10],[0.002 0.002],'color',[0 1 0],'LineWidth',3)
line([7 7],[3 7],[0.002 0.002],'color',[0 1 0],'LineWidth',3)
% figure(4)
% mu = [0.5 0.5]; SIGMA = [0.1 0;0 0.1];
% [X1,X2] = meshgrid(linspace(0,1,50)',linspace(0,1,50)');
% X = [X1(:) X2(:)];
% p = mvncdf(X,mu,SIGMA);
% surf(X1,X2,reshape(p,50,50));
%% 
% % Integrate the areas (rectangles)
% fun = @(Xi,Yi) interp2(x,y,mvd,Xi,Yi)
% Fb1b2 = quad2d(fun,0,USL,0,USL)
% Fa1b2 = quad2d(fun,0,LSL,0,USL)
% Fb1a2 = quad2d(fun,0,USL,0,LSL)
% Fa1a2 = quad2d(fun,0,LSL,0,LSL)
% Conform = Fb1b2 - Fa1b2 - Fb1a2 - Fa1a2
% 
% Fb1b2N = mvncdf([0 0],[USL USL],[cut2 cut2],[sigma1 sigma1])
% Fa1b2N = mvncdf([0 0],[LSL USL],[cut2 cut2],[sigma1 sigma1])
% Fb1a2N = mvncdf([0 0],[USL LSL],[cut2 cut2],[sigma1 sigma1])
% Fa1a2N = mvncdf([0 0],[LSL LSL],[cut2 cut2],[sigma1 sigma1])
% ConformN = mvncdf([LSL LSL],[USL USL],[cut2 cut2],[sigma1 sigma1])
% % d1 = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
% % d2 = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
% % 
% % invCDF1 = cumtrapz(xi,d1)';
% % invCDF2 = cumtrapz(xi,d2)';
% % 
% % plot(invCDF1,xi)
% % 
% % n = 100;
% % rho =0.0;
% % nu = 1;
% % T = mvtrnd([1 rho; rho 1], nu, n);
% % U = tcdf(T,nu);
% % %U = copulacdf('Clayton',[T(:,1) T(:,2)],1);
% % X = [invCDF1.*U(:,1) invCDF2.*U(:,2)];
% % 
% % figure(2)
% plot(X(:,1),X(:,2),'.'); 