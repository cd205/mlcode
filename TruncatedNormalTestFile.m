% Practice creating truncated distribution
clear all
close all
clc
% mu = 3;
% sigma = 0.9;
% xTrunc = 4;
% x = linspace(-10,10,200);
% pdf_truncnorm = @(x,mu,sigma) normpdf(x,mu,sigma) ./ normcdf(xTrunc,mu,sigma);
% 
% plot(x,pdf_truncnorm(x,mu,sigma),'.-')

n = 10;
mu = 1;
sigma = 3;
x = normrnd(mu,sigma,n,1);
xTrunc = 4;
x = x(x < xTrunc);
length(x)
hist(x,(-10:.5:4));

pdf_truncnorm = @(x,mu,sigma) normpdf(x,mu,sigma) ./ normcdf(xTrunc,mu,sigma);
start = [mean(x),std(x)]

[paramEsts,paramCIs] = mle(x, 'pdf',pdf_truncnorm, 'start',start, 'lower',[-Inf 0])