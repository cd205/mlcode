% Gaussian mixture model %
clear all
close all
clc


sigma1 = 1;
sigma2 = 1;
mu1 = 4;
mu2 = 0;
p = 0.5
x = linspace(-5,5,100);

% create a guassian mixture model %
pdf_normmixture = @(x) ...
    p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);

% Integrate the funciton numerically to find the CDF

lb = -5*ones(length(x));
ub = x';
for i = 1:length(x)
    CDF(i) = quad(pdf_normmixture,lb(i),ub(i));
end

figure(1)
[AX,H1,H2] = plotyy(x,pdf_normmixture(x),x,CDF,'plot');
set(get(AX(1),'Ylabel'),'String','PDF') 
set(get(AX(2),'Ylabel'),'String','CDF') 
xlabel('x')
grid on, hold on

% see if the CDF can be found with norncdf function 
cdf_normmixture = @(x) ...
    p*normcdf(x,mu1,sigma1) + (1-p)*normcdf(x,mu2,sigma2);

figure(2)
plot(x,cdf_normmixture(x),'-r')
hold on
plot(x,CDF,'g.')