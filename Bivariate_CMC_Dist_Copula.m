% generate a biavariate cut-meausre-cut model using copulas
close all
clear all
clc
cut1 = 6.5;
cut2 = 5;
sigmaN = 1
sigma1 = 1;
sigma2 = 1;
LSL = 3;
USL = 7;


 %with Gaussian copula

p = 0.0; % parameter of Gaussian copula
u=linspace(0,10,1000); % 1000 equidistant numbers

[x,y]=meshgrid(u); % create the grid (the points) on which the functions are evaluated

a = normpdf(x,5,sigmaN); % compute standard normal pdf values for x
b = Fun_Cut_Measure_Cut_Dist(y,cut1,cut2,sigma1,sigma2,LSL,USL);
figure(1)
subplot(1,2,1)
plot(x(1,:),a(1,:),'LineWidth',2);hold on
plot(y(:,1),b(:,1),'r','LineWidth',2); grid on
xlabel('x_i')
ylabel('Probability Density')
legend('x_1','x_2')
line([LSL LSL],[0 max(max(max(b)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
line([USL USL],[0 max(max(max(b)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
u = normcdf(x,5,1); % compute standard normal cdf values for x
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
legend('x_1','x_2')
f = copulapdf('Gaussian',[u(:),v(:)],p); %compute the pdf of gaussian copula
mvd = reshape(f,1000,1000).*a.*b; % create multivariate density from the product
% of the copula pdf and the marginal pdfs
% reshape f to avoid matrix
% dimension conflicts

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
axis square;

%% 
% Integrate the areas (rectangles)
fun = @(Xi,Yi) interp2(x,y,mvd,Xi,Yi)
Fb1b2 = quad2d(fun,0,USL,0,USL)
Fa1b2 = quad2d(fun,0,LSL,0,USL)
Fb1a2 = quad2d(fun,0,USL,0,LSL)
Fa1a2 = quad2d(fun,0,LSL,0,LSL)
Conform = Fb1b2 - Fa1b2 - Fb1a2 - Fa1a2

Fb1b2N = mvncdf([0 0],[USL USL],[cut2 cut2],[sigma1 sigma1])
Fa1b2N = mvncdf([0 0],[LSL USL],[cut2 cut2],[sigma1 sigma1])
Fb1a2N = mvncdf([0 0],[USL LSL],[cut2 cut2],[sigma1 sigma1])
Fa1a2N = mvncdf([0 0],[LSL LSL],[cut2 cut2],[sigma1 sigma1])
ConformN = mvncdf([LSL LSL],[USL USL],[cut2 cut2],[sigma1 sigma1])
% d1 = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
% d2 = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
% 
% invCDF1 = cumtrapz(xi,d1)';
% invCDF2 = cumtrapz(xi,d2)';
% 
% plot(invCDF1,xi)
% 
% n = 100;
% rho =0.0;
% nu = 1;
% T = mvtrnd([1 rho; rho 1], nu, n);
% U = tcdf(T,nu);
% %U = copulacdf('Clayton',[T(:,1) T(:,2)],1);
% X = [invCDF1.*U(:,1) invCDF2.*U(:,2)];
% 
% figure(2)
% plot(X(:,1),X(:,2),'.'); 