
clear all
close all
clc
Data = load('ManDataCrankShaft.dat');


x1 = Data(:,1); x2 = Data(:,2); x3 = Data(:,3);

%% x1-feature
% figure;
%hist(x1,10)
[h1 p1] = chi2gof(x1,'Alpha',0.01)
pdf1 = fitdist(x1,'Normal')

pdf_NonMix = @(x,mu1,sigma1)  normpdf(x,mu1,sigma1)
figure(2)
bins1 = linspace(19.4,20.8,12);
h = bar(bins1,histc(x1,bins1)/(length(x1)*((20.8-19.4)/12)),'histc'); hold on
set(h,'FaceColor',[.9 .9 .9]); set(gca,'FontSize',15)
xgrid = linspace(19,21,200);
%pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4),paramEsts(5));
hold on; plot(xgrid,pdf_NonMix(xgrid,pdf1.mu,pdf1.sigma),'-','LineWidth',1.5); 
line([19 19],[0 2.5],'Color','red','LineWidth',2.5)
line([21 21],[0 2.5],'Color','green','LineWidth',2.5)
text(19.07,2.2,{'p = 0.7442' ; 'mean = 20.0001' ; 'sigma = 0.2386 ' },'BackgroundColor',[1 1 1],'FontSize',15)
xlabel('Length (cm) (x_1)'); ylabel('Probability Density'); grid on
legend('Empirical','Continuous')

% xgrid2 = xgrid;
% pdfgrid2 = pdf_NonMix(xgrid2,paramEsts2(1),paramEsts2(2));
% plot(xgrid,pdfgrid2,'r')



%% x2-feature
figure
hist(x2)
[h2 p2] = chi2gof(x2,'Alpha',0.01)
pdf2 = fitdist(x2,'Normal')

pdf_NonMix = @(x,mu1,sigma1)  normpdf(x,mu1,sigma1);
figure;
bins2 = linspace(6.5,7.5,12);
h = bar(bins2,histc(x2,bins2)/(length(x2)*((7.5-6.5)/12)),'histc'); hold on
set(h,'FaceColor',[.9 .9 .9]); set(gca,'FontSize',15)
xgrid = linspace(6.5,7.5,200);
%pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4),paramEsts(5));
hold on; plot(xgrid,pdf_NonMix(xgrid,pdf2.mu,pdf2.sigma),'-','LineWidth',1.5);  
line([6.8 6.8],[0 3.5],'Color','green','LineWidth',2.5)
line([7.2 7.2],[0 3.5],'Color','red','LineWidth',2.5)
text(6.53,3.1,{'p = 0.5532' ; 'mean = 7.0020' ; 'sigma = 0.1362 ' },'BackgroundColor',[1 1 1],'FontSize',15)
xlabel('Diameter - big end (cm) (x_2)'); ylabel('Probability Density'); grid on
legend('Empirical','Continuous')
axis([6.5 7.5 0 3.5])



%% x3-feature
%figure;
%hist(x3)
[h3 p3] = chi2gof(x3,'Alpha',0.05)
pdf3 = fitdist(x3,'Normal')
[D PD] = allfitdist(x3,'PDF')
% plot(x2,x3,'r.'); grid on
xp = linspace(3.5,4.5,200);
pars = D(1).Params;
ploc1 = pdf('tlocationscale',xp,pars(1),pars(2),pars(3));
% figure;
% plot(xp,ploc1,'k-.')
figure;
bins = linspace(3.6,4.3,12);
%ploc2 = pdf('tlocationscale',xgrid,pars(1),pars(2),pars(3));  %tlocationscale distribution 
h = bar(bins,histc(x3,bins)/(length(x3)*((4.3-3.6)/12)),'histc'); hold on
set(h,'FaceColor',[.9 .9 .9]);  set(gca,'FontSize',15)
plot(xp,ploc1,'-','LineWidth',1.5); hold on
plot(xp,pdf_NonMix(xp,pdf3.mu,pdf3.sigma),'r-.','LineWidth',1.5);
line([3.8 3.8],[0 7],'Color','green','LineWidth',2.5)
line([4.2 4.2],[0 7],'Color','red','LineWidth',2.5)
text(3.53,4.8,{'p = 0.0083' ; 'mean = 4.0131' ; 'sigma = 0.0527 ' ; 'nu = 2.2522'},'BackgroundColor',[1 1 1],'FontSize',15)
text(3.53,6.2,{'NLogL_{Norm} = -56.91 ' ; 'NLogL_{tloc} = -62.77 '},'BackgroundColor',[1 1 1],'FontSize',15)
xlabel('Diameter - small end (cm) (x_3)'); ylabel('Probability Density'); grid on
legend('Empirical','Continuous','Normal')
axis([3.5 4.5 0 7])


[transdat, lambda] = boxcox(x3)
% xgrid2 = xgrid;
% pdfgrid2 = pdf_NonMix(xgrid2,paramEsts2(1),paramEsts2(2));
% plot(xgrid,pdfgrid2,'r'); hold on
% plot(xp,ploc1,'m-.')
% 
% 
% 
% pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) ...
%                          p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);
% pStart = .5;
% muStart = quantile(x3,[.25 .75])
% sigmaStart = sqrt(var(x3) - .25*diff(muStart).^2)
% start = [pStart muStart sigmaStart sigmaStart];
% lb = [0 -Inf -Inf 0 0];
% ub = [1 Inf Inf Inf Inf];
% options = statset('MaxIter',500, 'MaxFunEvals',1000);
% paramEsts = mle(x3, 'pdf',pdf_normmixture, 'start',start, ...
%                           'lower',lb, 'upper',ub, 'options',options)
% pdf_NonMix = @(x,mu1,sigma1)  normpdf(x,mu1,sigma1)
% muStart2 = 4
% sigmaStart2 = 0.08
% start2 = [muStart2 sigmaStart2];
% lb2 = [-Inf 0];
% ub2 = [Inf Inf];
% options = statset('MaxIter',500, 'MaxFunEvals',1000);
% paramEsts2 = mle(x3, 'pdf',pdf_NonMix, 'start',start2, ...
%                           'lower',lb2, 'upper',ub2, 'options',options)
% 
% figure;
% bins = linspace(3.6,4.3,12);
% ploc2 = pdf('tlocationscale',xgrid,pars(1),pars(2),pars(3));  %tlocationscale distribution 
% h = bar(bins,histc(x3,bins)/(length(x3)*((4.3-3.6)/12)),'histc');
% set(h,'FaceColor',[.9 .9 .9]);
% xgrid = linspace(3.5,4.5,200);
% pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4),paramEsts(5));
% hold on; plot(xgrid,pdfgrid,'-'); 
% xlabel('x'); ylabel('Probability Density'); grid on
% 
% xgrid2 = xgrid;
% pdfgrid2 = pdf_NonMix(xgrid2,paramEsts2(1),paramEsts2(2));
% plot(xgrid,pdfgrid2,'r'); hold on
% plot(xp,ploc1,'m-.')