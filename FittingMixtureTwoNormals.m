% Fitting A Mixture of Two Normals
clear all
close all
clc
%% Example of how to create a bimodal dist
% First, flip a biased coin.  If it lands heads, pick a value at random
% from a normal distribution with mean mu_1 and standard deviation
% sigma_1. If the coin lands tails, pick a value at random from a normal
% distribution with mean mu_2 and standard deviation sigma_2.
%x = [trnd(20,1,50) trnd(4,1,100)+3]
x = [normrnd(0,0.8,1,40) normrnd(1.8,1,1,80)];
hist(x,-2.25:.5:7.25);
xlabel('x'); ylabel('Number of Observations'); grid on

pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) ...
                 p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);
                     
pStart = .5;
muStart = quantile(x,[.25 .75])
sigmaStart = sqrt(var(x) - .25*diff(muStart).^2)
start = [pStart muStart sigmaStart sigmaStart];
% specify bounds of zero and one for the mixing probability, and lower 
% bounds of zero for the standard deviations. The remaining elements of 
% the bounds vectors are set to +Inf or -Inf, to indicate no restrictions.
lb = [0 -Inf -Inf 0 0];
ub = [1 Inf Inf Inf Inf];

% increse the defualt number of evaluations in Max Liklihood Estimation
% (mle)
options = statset('MaxIter',600, 'MaxFunEvals',800);
paramEsts = mle(x, 'pdf',pdf_normmixture, 'start',start,...
    'lower',lb,'upper',ub,'options',options)

%% Plot the fitted density distribution
figure(2)
bins = -2.5:.5:7.5;
h = bar(bins,histc(x,bins)/(length(x)*.5),'histc');
set(h,'FaceColor',[.9 .9 .9]);
xgrid = linspace(1.1*min(x),1.1*max(x),200);
pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),...
    paramEsts(4),paramEsts(5));
hold on; plot(xgrid,pdfgrid,'-'); grid on; hold off
xlabel('x'); ylabel('Probability Density');


h_ks = kstest(x)
h_li = lillietest(x)
[AD2,P] = AnDartest([x]);
Stats = struct('P',P,'AD',AD2,'n',length(x));
StatsString = evalc('Stats')

hold on 
uicontrol('Style', 'text','FontSize',13,...
       'String', [num2str(StatsString(9:end))],... 
       'Units','normalized',...
       'Position', [0.65 0.51 0.25 0.41]); 

