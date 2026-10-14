
clear all
clc
close all

InitialBatch = 100000
nom = 5
sigma = 0.6
USL = 7
LSL = 3
depth1 = 7;

%% First cut - aim for USL
Cut1 = normrnd(depth1,sigma,InitialBatch,1);
bins = [0:0.1:10];
hist(Cut1,bins)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on
% Check what conforms and create 'Sample2' of parts that require a second 
% cut 
InSpec = 0;
c1 = 1;
c2 = 1;
for i = 1:length(Cut1)
    if Cut1(i)<=USL
        InSpec(c1) = Cut1(i);
        c1 = c1+1;
    else
        Sample2(c2) = Cut1(i);
        c2 = c2+1;
    end
end
length(InSpec)
length(Sample2)
p_exact = length(InSpec)/InitialBatch

%% Second cut - aim for nominal 
Cut2 = normrnd(nom,sigma,length(Sample2),1);
figure(2)
hist(Cut2,bins)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on

x = [InSpec, Cut2'];

figure(3)
hist(x,bins)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on


%% Try and estimate the original distributions from the final distribution 
% 'x'
pdf_normmixture = @(x,p,mu1,mu2) ...
                 p*normpdf(x,mu1,sigma) + (1-p)*normpdf(x,mu2,sigma);

             
pStart = .5;
muStart = [7.5 5]
%sigmaStart = [1]%sqrt(var(x) - .25*diff(muStart).^2)
start = [pStart muStart]% sigmaStart sigmaStart];
% specify bounds of zero and one for the mixing probability, and lower 
% bounds of zero for the standard deviations. The remaining elements of 
% the bounds vectors are set to +Inf or -Inf, to indicate no restrictions.
lb = [0 -Inf -Inf];
ub = [1 Inf Inf];

% increse the defualt number of evaluations in Max Liklihood Estimation
% (mle)
options = statset('MaxIter',500, 'MaxFunEvals',800);
paramEsts = mle(x, 'pdf',pdf_normmixture, 'start',start,...
    'lower',lb,'upper',ub,'options',options,'optimfun','fmincon')

%% Plot the fitted density distribution
figure(4)
% = -2.5:.5:12;
h = bar(bins,histc(x,bins)/(length(x)*.5),'histc');
set(h,'FaceColor',[.9 .9 .9]);
xgrid = linspace(1.1*min(x),1.1*max(x),200);
pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3));
hold on; plot(xgrid,pdfgrid,'.-'); grid on; hold off
xlabel('x'); ylabel('Probability Density');