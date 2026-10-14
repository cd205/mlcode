% Study the 2D conformance problem
clear all
clc
close all
MU = [5 5];
sigma1 = 1;
sigma2 = 1;
sigma12 = 0.9;
sigma21 = sigma12;
SIGMA = [sigma1^2 sigma12^2; sigma21^2 sigma2^2]
A = [3 3];
B = [7 7];

u=linspace(0,10,50); 
[x,y]=meshgrid(u); % create the grid (the points) on which the functions are evaluated
X = [x(:) y(:)];

a = normpdf(x,MU(1),sigma1^2);
b = normpdf(y,MU(2),sigma2^2);
u = normcdf(x,MU(1),sigma1^2);
v = normcdf(y,MU(2),sigma2^2);

p = [1 sigma12^2; sigma21^2 1]

Act_mvncdf = mvncdf(X,MU,SIGMA);
Act_mvncdf = reshape(Act_mvncdf,50,50);
mvcdf = copulacdf('Gaussian',[u(:),v(:)],p);
mvcdf = reshape(mvcdf,50,50);

figure;
subplot(1,2,1)
mesh(x,y,Act_mvncdf)
xlabel('x')
ylabel('y')
zlabel('Cumulative Density')

subplot(1,2,2)
mesh(x,y,mvcdf)
xlabel('x')
ylabel('y')
zlabel('Cumulative Density')