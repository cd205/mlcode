% generate a biavariate cut-meausre-cut model
close all
clear all
clc
cut1 = 5;
cut2 = 5;
sigma1 = 0.5;
sigma2 = 0.5;
LSL = 3;
USL = 7;
xi = linspace(0,10,10000);

d1 = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
d2 = Fun_Cut_Measure_Cut_Dist(yi,cut1,cut2,sigma1,sigma2,LSL,USL);

invCDF1 = cumtrapz(xi,d1);
invCDF2 = cumtrapz(yi,d2);



plot(invCDF1,xi)

n = 10000;
rho =0.0;
nu = 1;
T = mvtrnd([1 rho; rho 1], nu, n);
U = tcdf(T,nu);
%U = copulacdf('Clayton',[T(:,1) T(:,2)],1);
X = [invCDF1'.*U(:,1) invCDF2'.*U(:,2)];

figure(2)
plot(X(:,1),X(:,2),'.'); 