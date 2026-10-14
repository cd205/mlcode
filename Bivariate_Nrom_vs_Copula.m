% Bivariate_Norm_Exact
% compute a bivariate normal cdf and compare it to the results got from the
% copula version when correlation is present 
% 07/05/13
%% Normal cdf function
clear all 
close all
clc

mu = [5 4]; 
num = 30
sig11 = 0.9
sig22 = 0.4
rho = 0.9
x1 = linspace(0,10,num)
x2 = linspace(0,10,num)
SIGMA = [sig11^2 rho*sig11*sig22; rho*sig22*sig11 sig22^2];
[X1,X2] = meshgrid(x1,x2);
X = [X1(:) X2(:)];
p = mvncdf(X,mu,SIGMA);
subplot(1,2,1)
surf(X1,X2,reshape(p,num,num));
xlabel('x_1')
ylabel('x_2')


%% Copula function
n1 = normpdf(X1,mu(1),sig11);
n2 = normpdf(X2,mu(2),sig22);
c1 = normcdf(X1,mu(1),sig11);
c2 = normcdf(X2,mu(2),sig22);

f = copulacdf('Gaussian',[c1(:),c2(:)],rho)
mvd = reshape(f,num,num)
subplot(1,2,2);
surf(x1,x2,mvd);
xlabel('x_1')
ylabel('x_2')