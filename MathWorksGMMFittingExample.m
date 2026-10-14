% MathWorks Example for GMM fitting to a univarite normal mixture model
clear all
close all
clc
%x = [trnd(20,1,50) trnd(4,1,100)+2];
mu1 = 0
mu2 = 2
sigma1 = 1
sigma2 = 1
x = [normrnd(mu1,sigma1,[1,50]) normrnd(mu2,sigma2,[1,50])];
hist(x,-2.25:.5:7.25);

pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) ...
           p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);
       
pStart = .5;
muStart = quantile(x,[.25 .75]);
sigmaStart = sqrt(var(x) - .25*diff(muStart).^2);
start = [pStart muStart sigmaStart sigmaStart];

lb = [0 -Inf -Inf 0 0];
ub = [1 Inf Inf Inf Inf];

options = statset('MaxIter',700, 'MaxFunEvals',1000);
paramEsts = mle(x, 'pdf',pdf_normmixture, 'start',start, ...
                          'lower',lb, 'upper',ub,'alpha',0.05,'options',options)
% alpha is a the confidence level default is 0.05 or 95% confidence
%% Plotting
bins = -2.5:.5:7.5;
h = bar(bins,histc(x,bins)/(length(x)*.5),'histc');
set(h,'FaceColor',[.9 .9 .9]);
xgrid = linspace(1.1*min(x),1.1*max(x),200);
pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4),paramEsts(5));
hold on; plot(xgrid,pdfgrid,'-'); hold off
xlabel('x'); ylabel('Probability Density');
