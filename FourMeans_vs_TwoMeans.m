% call the MinCMCFun_2var function
clear all
close all
clc
mu1 =   5.295 ; mu2 = 5.295;
mu1_rw = 5.488; mu2_rw = 5.488;

sig11 = 1;
sig22 = 1;
rho = 0.5;
SIGMA = [sig11^2, rho*sig11*sig22; rho*sig11*sig22, sig22^2];
U = [6 6];
L = [4 4];
[Profit,TC,S,PIs,f1s,f2s] = MinCMCFun_2var(mu1,mu2,mu1_rw,mu2_rw,U,L,SIGMA)
PIs
CheckVals = f1s(2)+f1s(3)+f1s(4)+f2s(2)+f2s(3)+f2s(4)+PIs(4)+PIs(5)
%% single variable truncated distribution 
x = linspace(0,10,1000);
piCS = normcdf(U(1),mu1,sig11);       % 1-var conformance and scrap after 1st iter
pi2 = 1-normcdf(U(1),mu1,sig11);      % 1-var feed into rework state

% pdf from x_1 after first cut (i.e. TruncatedDist*Fa1b2
pdfa = Fun_TruncatedNormalDist_pdf(x,mu1,sig11,0,U(1),U(1),1)*piCS;
pdfb = Fun_TruncatedNormalDist_pdf(x,mu1_rw,sig11,0,U(1),U(1),1)*(PIs(1)+PIs(3));
figure(1);
plot(x,pdfa,'r.-'); grid on; hold on 
plot(x,pdfb,'g.-'); hold on 
plot(x,pdfa+pdfb,'m.-');
xlabel('x_1')
ylabel('Probability Density')
legend('PDF inital state','PDF rework state','Sum of PDFs')
int2one = trapz(x,pdfa+pdfb)

%% dual variable truncated distribution
% truncated dist with MU = [mu1 mu2]
x1 = linspace(3.5,6.5,200); x2 = linspace(3.5,6.5,200);
[X1,X2] = meshgrid(x1',x2');
MU = [mu1 mu2];
pdf = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
figure;
surf(x1,x2,pdf,'EdgeColor','none')
fun = @(X1,X2) tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
% q1 = integral2(fun,0,10,0,10)
q_pdf = trapz(x2,trapz(x1,pdf))
%% truncated dist where MU1 = [mu1 mu2] and MU2 = [mu1_rw mu2_rw]
MU1 = [mu1 mu2]; MU2 = [mu1_rw mu2_rw];
% pdf1 is Turncated distribution from inital iteration, this includes the 
% pIC and pIS parts, i.e. comformance and scrap from initial processing
pdf1 = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)*(PIs(4)+PIs(5));
% pdf2 is Turncated distribution from the rework from the two single
% feature rework states (state 2 and 3), assume no dependence 
pdf2 = tmvnorm_2var(X1,X2,MU2,sig11,sig22,0,L,U)*(f1s(2)+f1s(3)+f2s(2)+f2s(3));
% pdf3 is Turncated distribution from the rework from the fourth state, it
% is the same as the inital process but with fewer components
pdf3 = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)*(f1s(4)+f2s(4));
% pdfTot is the combination of the pdfs
pdfTot = pdf1+pdf2+pdf3;
figure;
surf(x1,x2,pdfTot,'EdgeColor','none')
q_pdfTot = trapz(x2,trapz(x1,pdfTot))
%[TC2,S2] = MinCMCFun_Iterative_2var(mu1,mu2,mu1_rw,mu2_rw,U,L,SIGMA)

figure;
hSurface = surf(x1,x2,pdf); hold on; grid on
set(hSurface, 'FaceColor',[1 0 0], 'FaceAlpha',0.5, 'EdgeAlpha', 0.2);
hSurface = surf(x1,x2,pdfTot);
set(hSurface, 'FaceColor',[0 1 0], 'FaceAlpha',0.5, 'EdgeAlpha', 0.2);
az = -20; el = 24; view(az, el);
set(gca,'FontSize',15)
Leg = legend('case_1','case_2'); set(Leg,'FontSize',15)
xlabel('x_1'); ylabel('x_2'), zlabel('Probability Density')
%% ----------1 variable example---------- %%
% LSL = 4; USL = 6;
% mu = 5; sig = 1;
% p11 = 1 - normcdf(USL,mu,sig)
% p13 = normcdf(LSL,mu,sig)
% RwC = 5
% SrC = 100
% 
% Rework = ((1/(1-p11))-1)*RwC 
% Scrap = p13/(1-p11)*100
% 
% TotCost1 = Rework+Scrap
% 
% CostInitial = SrC*p13 + RwC*p11
% for i = 1:1000
%     CostIter(i) = (SrC*p13 + RwC*p11)*(p11^i);
% end
% 
% TotCost2 = CostInitial+ sum(CostIter)