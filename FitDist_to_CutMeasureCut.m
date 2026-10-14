
clear all
close all
clc
tic
n = 500000;
mu1 = 6;
mu2 = 5;
sigma = 0.8;
USL =7
Nom = 5

% do first cut
Cut1 = normrnd(mu1,sigma,1,n);

InSpec = 0;
c = 1;
for i = 1:n
    if Cut1(i) <= USL
       InSpec = InSpec + 1;
       Sample1(c) = Cut1(i);
       c = c+1;
    else
    end
end

%do second cut with all the components that are obove the USL
Cut2 = normrnd(mu2,sigma,1,n-InSpec);

bins = [0:0.1:8];
TotalPop = [Sample1 Cut2];
figure(1)
h = bar(bins,histc(TotalPop,bins),'histc');
line([7 7],[0 500],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 500],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on
xlabel('Dimension')
ylabel('Number of samples')
grid on; hold on

% This is a truncated mixed normal distribution, not that easy to fit a
% model to
%% Try and model with a mixture mode
% create a guassian mixture model %
p = InSpec/n
x = linspace(0,9,10000);
pdf_normmixture = @(x) ...
    p*normpdf(x,mu1,sigma) + (1-p)*normpdf(x,mu2,sigma);


pdf = pdf_normmixture(x);
figure(3)
%[ax, h1, h2] = plotyy(x ,h, x,pdf_normmixture(x) , @hist, @line);
[AX,H1,H2] = plotyy(bins,hist(TotalPop,bins),x,pdf,@bar,@line)
%set(H1,'marker','o','color','red')
set(H2,'color','magenta') 
set(get(AX(1),'Ylabel'),'String','Number of Samples') 
set(get(AX(2),'Ylabel'),'String','PDF','color','magenta') 
line([7 7],[0 500],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 500],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
xlabel('x')
grid on, hold on
toc
