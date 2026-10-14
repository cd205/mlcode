clear all
close all
clc
Data = load('ManDataCrankShaft.dat');


x1 = Data(:,1); x2 = Data(:,2); x3 = Data(:,3);

figure;
(scatterhist(x2,x3));
% Transform the data to the copula scale (unit square) using a kernel 
% estimator of the cumulative distribution function.
u = ksdensity(x2,x2,'function','cdf');
v = ksdensity(x3,x3,'function','cdf');

figure;
scatterhist(u,v)
xlabel('u')
ylabel('v')

% Fit a Gaussian copula
[dep] = copulafit('Gaussian',[u v])
CLG = NormalCopula_CL(dep(1,2),[u v])
rG = copularnd('Gaussian',dep,5000);
uv = mvnrnd(zeros(1,2),dep,5000);
uu = normcdf(uv);
rG = uu;

CLG2 = gausscml(dep(1,2),u,v)


% Fit a Clayton Copula
[dep] = copulafit('Clayton',[u v])
CLC = claytonCL(dep,[u v])
%rC = copularnd('Clayton',dep,10);
p = rand(length(uu(:,2)),1);
uu2 = uu(:,1).*(p.^(-dep./(1+dep)) - 1 + uu(:,1).^dep).^(-1./dep);
rC = [uu(:,1), uu2];
CLC2 = claytoncml(dep,u,v)
% Fit Frank Copula

[dep] = copulafit('Frank',[u v])
CLF = claytonCL(dep,[u v])
%rF = copularnd('Frank',dep,1000);
uu22 = -log((exp(-dep.*uu(:,1)).*(1-p)./p + exp(-dep))./(1 + exp(-dep.*uu(:,1)).*(1-p)./p))./dep;
rF = [uu(:,1), uu22];
CLF2 = frankcml(dep,u,v)

%% Plots

% Gaussian correlation
u1 = rG(:,1);
v1 = rG(:,2);

% Transform the random sample back to the original scale of the data.
MU = [7 4];
sig11 = 0.1362; sig22 = 0.05027;
x2_rnd = normrnd(MU(1),sig11,1000,1);
%pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
x3_rnd = random('tLocationScale',MU(2),sig22,2.2522,1000,1);
x_2 = ksdensity(x2_rnd,u1,'function','icdf');
x_3 = ksdensity(x3_rnd,v1,'function','icdf');
figure;
scatterhist(x_2,x_3,'Direction','out');set(gca,'FontSize',15); grid on
set(get(gca,'children'),'marker','.'); hold on
scatter(x2,x3,'ro');
axis([6.5 7.5 3.5 4.5])
% Clayton correlation
u1 = rC(:,1);
v1 = rC(:,2);

% Transform the random sample back to the original scale of the data.
%MU = [7 4]
%sig11 = 0.1362; sig22 = 0.05027;
%x2_rnd = normrnd(MU(1),sig11,1000,1);
%pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
%x3_rnd = random('tLocationScale',MU(2),sig22,2.2522,1000,1);
x_2 = ksdensity(x2_rnd,u1,'function','icdf');
x_3 = ksdensity(x3_rnd,v1,'function','icdf');
figure
scatterhist(x_2,x_3,'Direction','out');set(gca,'FontSize',15); grid on
set(get(gca,'children'),'marker','.'); hold on
scatter(x2,x3,'ro')
axis([6.5 7.5 3.5 4.5])
% Frank Correlation
u1 = rF(:,1);
v1 = rF(:,2);

% Transform the random sample back to the original scale of the data.
%MU = [7 4]
%sig11 = 0.1362; sig22 = 0.05027;
%x2_rnd = normrnd(MU(1),sig11,1000,1);
%pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
%x3_rnd = random('tLocationScale',MU(2),sig22,2.2522,1000,1);
x_2 = ksdensity(x2_rnd,u1,'function','icdf');
x_3 = ksdensity(x3_rnd,v1,'function','icdf');
figure
scatterhist(x_2,x_3,'Direction','out');set(gca,'FontSize',15); grid on
set(get(gca,'children'),'marker','.'); hold on
scatter(x2,x3,'ro')
axis([6.5 7.5 3.5 4.5])
% %% Marginals
% xp2 = linspace(5,9,100); xp3 = linspace(2,5,100);
% [XP2 XP3] = meshgrid(xp2,xp3);
% X = [XP2(:) XP3(:)];
% MU = [7 4];
% U = [6.8 3.8]; % Upper limit is rework (which is actually the lower limit
% L = [7.2 4.2]; % as these are holes
% sig11 = 0.1362; sig22 = 0.05027;
% x2_pdf = normpdf(xp2,MU(1),sig11);
% x2_cdf = normcdf(xp2,MU(1),sig11);
% pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
% x3_pdf = pdf(pd3,xp3);
% x3_cdf = cdf(pd3,xp3);
% 
% figure;
% plot(xp2,x2_pdf,'m.-')
% figure;
% plot(xp3,x3_pdf,'k-')
% 
% x2_pdf_Grid = normpdf(X(:,1),MU(1),sig11);
% x3_pdf_Grid = pdf(pd3,X(:,2));
% x2_cdf_Grid = normcdf(X(:,1),MU(1),sig11);
% x3_cdf_Grid = cdf(pd3,X(:,2));
% 
% % PDF scatter plot
% CpdfScat = copulapdf('Gaussian',[x2_cdf,x3_cdf],0).*x2_pdf.*x3_pdf;
% %CpdfScat = reshape(Cpdf1,length(xp2),length(xp3));
% %figure;scatterhist()
% 
% % PDF surface plot
% Cpdf1 = copulapdf('Gaussian',[x2_cdf_Grid,x3_cdf_Grid],0).*x2_pdf_Grid.*x3_pdf_Grid;
% Cpdf1 = reshape(Cpdf1,length(xp2),length(xp3));
% 
% 
% 
% %%
% 
% 
% % U = [7 7];
% % L = [0 0];
% % MU = [5.5 5.5];
% % mu1_rw = 7; mu2_rw = 7;
% % rho = 0.0 % dependence
% % sig11 = 1; sig22 = 1
% % SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2]
% % 
% % 
% % MU_R = L+(U-MU); % reverse the axes 
% % sig11 = sqrt(SIGMA(1));
% % sig22 = sqrt(SIGMA(2,2));
% % 
% % Fb1b2 = mvncdf([U(1),U(2)],MU_R,SIGMA);
% % Fa1b2 = mvncdf([L(1),U(2)],MU_R,SIGMA);
% % Fb1a2 = mvncdf([U(1),L(2)],MU_R,SIGMA);
% % Fa1a2 = mvncdf([L(1),L(2)],MU_R,SIGMA);
% % 
% % pI2 = Fa1b2 - Fa1a2;
% % pI3 = Fb1a2 - Fa1a2;
% % pI4 = Fa1a2;
% % pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
% % pIS = 1 - Fb1b2;
% % 
% % p22 = 1 - normcdf(U(1),mu1_rw,sig11);
% % p2C = normcdf(U(1),mu1_rw,sig11) - normcdf(L(1),mu1_rw,sig11);
% % p2S = normcdf(L(1),mu1_rw,sig11);
% % p33 = 1 - normcdf(U(2),mu2_rw,sig22);
% % p3C = normcdf(U(2),mu2_rw,sig22) - normcdf(L(2),mu2_rw,sig22);
% % p3S = normcdf(L(2),mu2_rw,sig22);
% % 
% % p42 = pI2; 
% % p43 = pI3; 
% % p44 = pI4;
% % p4C = pIC; 
% % p4S = pIS;
% % p5C = 1; 
% % p5S = 0; 
% % 
% % m12 = pI2/((1-p22)*(1-p44));
% % m13 = pI3/((1-p33)*(1-p44));
% % m14 = pI4/(1-p44);
% % 
% % fIC = pIC + pI2*p2C/((1-p22)*(1-p44)) + pI3*p3C/((1-p33)*(1-p44)) + pI4*p4C/(1-p44);
% % f2C = (p2C/(1-p22));%*p12;
% % f3C = (p3C/(1-p33));%*p13;
% % %Sum_45 = p25*p12/((1-p22)*(1-p14)) + p35*p13/((1-p33)*(1-p14));
% % %f45 = (p15/(1-p14)) + Sum_45;
% % f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;
% % 
% % %% Scrap parts
% % % NOTE: p12, p13 and p14 that multiply f26, f36 and f46 account for the
% % % number of parts flowing through into these rework stages,  this could be
% % % done in the cost model rather than here
% % % Sum_16 = p35*p13 + p46*p14 + p56*p15;
% % % Prod_16 = (1-p22)*(1-p33)*(1-p44);
% % % f16 = (p26*p12*(1-p33) + (Sum_16*Prod_16))/Prod_16;
% % fIS = pIS + pI2*p2S/((1-p22)*(1-p44)) + pI3*p3S/((1-p33)*(1-p44)) + pI4*p4S/(1-p44);
% % f2S = (p2S/(1-p22));%*p12;
% % f3S = (p3S/(1-p33));%*p13;
% % %Sum_46 = p26*p16/((1-p22)*(1-p14)) + p36*p13/((1-p33)*(1-p14));
% % %f46 = (p16/(1-p14)) + Sum_46;
% % f4S = (p42*p2S/((1-p22)*(1-p44)) + p43*p3S/((1-p33)*(1-p44)) + p4S/(1-p44));%*p14;
% % 
% % 
% % f1s = [fIC, f2C*(pI4*(pI2/(1-pI4))+pI2),...
% %             f3C*(pI4*(pI3/(1-pI4))+pI3)...
% %             pI4*(pIC/(1-pI4))]
% % f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
% %             f3S*(pI4*(pI3/(1-pI4))+pI3),...
% %             pI4*(pIS/(1-pI4))]
% % 
% % %% dual variable truncated distribution
% % % truncated dist with MU = [mu1 mu2]
% % x1 = linspace(0,10,nums); x2 = linspace(0,10,nums);
% % [X1,X2] = meshgrid(x1',x2');
% % %MU = [mu1 mu2];
% % [pdf IXV] = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
% % figure;
% % surf(x1,x2,pdf,'EdgeColor','none')
% % fun = @(X1,X2) tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
% % % q1 = integral2(fun,0,10,0,10)
% % q_pdf = trapz(x2,trapz(x1,pdf))
% % 
% % (pIC + pIS)
% % (f1s(2)+f1s(3)+f2s(2)+f2s(3))
% % (f1s(4)+f2s(4))
% % 
% % %% truncated dist where MU1 = [mu1 mu2] and MU2 = [mu1_rw mu2_rw]
% % MU1 = [MU]; MU2 = [mu1_rw mu2_rw];
% % % pdf1 is Turncated distribution from inital iteration, this includes the 
% % % pIC and pIS parts, i.e. comformance and scrap from initial processing
% % pdf1 = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)*(pIC+pIS);                    % dependence given by 'rho' for dual feature rework 
% % % pdf2 is Turncated distribution from the rework from the two single
% % % feature rework states (state 2 and 3), assume no dependence 
% % pdf2 = tmvnorm_2var(X1,X2,MU2,sig11,sig22,0,L,U)*(f1s(2)+f1s(3)+f2s(2)+f2s(3)); % dependence is 0 as this is the single feature rework
% % % pdf3 is Turncated distribution from the rework from the fourth state, it
% % % is the same as the inital process but with fewer components
% % pdf3 = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)*(f1s(4)+f2s(4));              % dependence given by 'rho' for dual feature rework 
% % % pdfTot is the combination of the pdfs
% % pdfTot = pdf1+pdf2+pdf3;
% % figure(2);
% % surf(x1,x2,pdfTot,'EdgeColor','none')
% % q_pdfTot = trapz(x2,trapz(x1,pdfTot))
% % %[TC2,S2] = MinCMCFun_Iterative_2var(mu1,mu2,mu1_rw,mu2_rw,U,L,SIGMA)
% % 
% % figure;
% % m1 = mesh(x1,x2,pdf,'EdgeColor','red','LineWidth',1); hold on
% % %set(m1,'FaceAlpha',0.8)
% % %m2 = mesh(x1,x2,pdfTot,'EdgeColor',[33 64 154]./255,'LineWidth',1.1); hold on
% % set(m1,'FaceAlpha',0.4)
% % view(60, 30);  
% % set(gca,'FontSize',15)
% % xlabel('\mu_{1}'); ylabel('\mu_{2}'); zlabel('Probability Density');
% % title('tmvnorm_2var plot')
% % legend('Case I surface','Case II surface');
% % 
% % 
% % 
% % %% GET THE MARGINAL DISTRIBUTIONS 
% % %clear x1; clear x2
% % funTrun = @(x1,x2) tmvnorm_2var(x1,x2,MU,sig11,sig22,rho,L,U)*(pIC+pIS)+...  % dependence given by 'rho' for dual feature rework 
% %  tmvnorm_2var(x1,x2,MU2,sig11,sig22,0,L,U)*(f1s(2)+f1s(3)+f2s(2)+f2s(3))+... % dependence is 0 as this is the single feature rework
% %  tmvnorm_2var(x1,x2,MU,sig11,sig22,rho,L,U)*(f1s(4)+f2s(4));                 % dependence given by 'rho' for dual feature rework 
% % 
% % % trunmvnpdf = funTrun(X1,X2)
% % % surf(x1,x2,trunmvnpdf)
% % %f = @(x,y)fun_2VarReverse_CMC_Dist(x,y,SIGMA,CUT1,CUT2,A,B);
% % fx_org = @(x1)integral(@(x2)fun(x1,x2),0,1,'ArrayValued',true);
% % fx1 = @(x1)integral(@(x2)funTrun(x1,x2),0,1,'ArrayValued',true); % fx is a function in x, 
% %             % for every call 'x' the bivariate function is evaluated at 'x' and in y from -inf to inf
% % fx2 = @(x2)integral(@(x1)fun(x1,x2),0,1,'ArrayValued',true);
% % % NOTE it is much faster to integrate between finite numbers eg -20 to 20 
% % % then to go from -inf to inf 
% % 
% % % x1 = linspace(1,9,2);
% % % x2 = x1;
% % %  
% % % for i = 1:length(x1)
% % %     i
% % %     marginal_x1(i) = fx1(x1(i));
% % %     marginal_x2(i) = fx2(x2(i));
% % % end
% % % figure;
% % % plot(x1,marginal_x1,'r.-','LineWidth',1.5); hold on
% % % plot(x2,marginal_x2,'.-','Color',[33 64 154]./255,'LineWidth',1.5); grid on
% % % line([3 3],[0 0.45],'Color','red','LineWidth',2.5)
% % % line([7 7],[0 0.45],'Color','green','LineWidth',2.5)
% % % set(gca,'FontSize',15)
% % % xlabel('Mean (\mu)')
% % % ylabel('Probability Density')
% % % Leg = legend('Case I','Case II'); 
% % % set(Leg,'FontSize',15)
% % % axis([1 9 0 0.5])
% % 
% % %% Use a Copula to get the multivariate distribution back 
% % % Dual feature distributions
% % % New Sigma 
% % 
% % 
% % % fx_org = @(x1)integral(@(x2)fun(x1,x2),-10,10,'ArrayValued',true);
% % % for i = 1:length(x1)
% % %     i
% % %     marginal_x1_org(i) = fx_org(x1(i));
% % % end
% % 
% % dep = .0
% % sig11 = 1; sig22 = 1
% % SIGMA_d = [sig11^2 dep*sig11*sig22; dep*sig11*sig22 sig22^2]
% % x1 = linspace(0,10,nums); x2 = linspace(0,10,nums);
% % [X1 X2] = meshgrid(x1,x2);
% % X = [X1(:) X2(:)];
% % 
% % pdf1 = Fun_TruncatedNormalDist_pdf(x1,MU(1),sig11,L(1),U(1),U(1),0);
% % pdf1_rw = Fun_TruncatedNormalDist_pdf(x1,mu1_rw,sig11,L(1),U(1),U(1),0);
% % cdf1 = Fun_TruncatedNormalDist_cdf(x1,MU(1),sig11,0,10,10,0);
% % cdf1_rw = Fun_TruncatedNormalDist_cdf(x1,mu1_rw,sig11,L(1),U(1),U(1),0);
% % 
% % %inter1 = trapz(x1,marginal_x1_org)
% % inter2 = trapz(x1,pdf1)
% % 
% % figure;
% % plot(x1,pdf1,'.-'); hold on; grid on
% % plot(x1,cdf1,'r.-')
% % % plot(x1,pdf1_rw,'r.-')
% % % plot(x1,marginal_x1_org,'g.-')
% % % figure;
% % % plot(x1,cdf1,'.-'); hold on; grid on
% % % plot(x1,cdf1_rw,'r.-')
% % 
% % % dual feature rework form inital stage I and stage 4
% % pdf1_Grid = Fun_TruncatedNormalDist_pdf(X(:,1),MU(1),sig11,L(1),U(1),U(1),0);
% % pdf2_Grid = Fun_TruncatedNormalDist_pdf(X(:,2),MU(2),sig22,L(2),U(2),U(2),0);
% % cdf1_Grid = Fun_TruncatedNormalDist_cdf(X(:,1),MU(1),sig11,L(1),U(1),U(1),0);
% % cdf2_Grid = Fun_TruncatedNormalDist_cdf(X(:,2),MU(2),sig22,L(1),U(1),U(1),0);
% % % single feature rework form stage 2 and stage 3
% % pdf1_rw_Grid = Fun_TruncatedNormalDist_pdf(X(:,1),mu1_rw,sig11,L(1),U(1),U(1),0);
% % pdf2_rw_Grid = Fun_TruncatedNormalDist_pdf(X(:,2),mu2_rw,sig22,L(2),U(2),U(2),0);
% % cdf1_rw_Grid = Fun_TruncatedNormalDist_cdf(X(:,1),mu1_rw,sig11,L(2),U(2),U(2),0);
% % cdf2_rw_Grid = Fun_TruncatedNormalDist_cdf(X(:,2),mu2_rw,sig22,L(2),U(2),U(2),0);
% % 
% % 
% % Cpdf1_Fun = @(xi1,xi2) copulapdf('Gaussian',...
% %     [Fun_TruncatedNormalDist_cdf(xi1,MU(1),sig11,L(1),U(1),U(1),0),...
% %      Fun_TruncatedNormalDist_cdf(xi2,MU(2),sig22,L(2),U(2),U(2),0)],dep)...
% %    .*Fun_TruncatedNormalDist_pdf(xi1,MU(1),sig11,L(1),U(1),U(1),0)...
% %    .*Fun_TruncatedNormalDist_pdf(xi2,MU(2),sig22,L(2),U(2),U(2),0);
% % 
% % % PDF surface plot
% % Cpdf1 = copulapdf('Gaussian',[cdf1_Grid,cdf2_Grid],dep).*pdf1_Grid.*pdf2_Grid;
% % Ccdf1 = copulacdf('Gaussian',[cdf1_Grid,cdf2_Grid],dep);
% % Cpdf1 = reshape(Cpdf1,length(x1),length(x2));
% % Ccdf1 = reshape(Ccdf1,length(x1),length(x2));
% % 
% % 
% % q_Cpdf1 = trapz(x2,trapz(x1,Cpdf1))
% % % plot outer diameter finish distributions
% % figure(8)
% % m1 = mesh(x1,x2,Cpdf1,'EdgeColor','green','LineWidth',1); hold on
% % m2 = mesh(x1,x2,pdf,'EdgeColor','red','LineWidth',1); hold on
% % set(m1,'FaceAlpha',0.4);set(m2,'FaceAlpha',0.4)
% % view(60, 30);  
% % set(gca,'FontSize',15)
% % xlabel('\mu_{1}'); ylabel('\mu_{2}'); zlabel('Probability Density');
% % legend('Case I surface','Case II surface');
% % 
% % 
% % %% PDF surface plot with dual; and single feature rework 
% % CpdfDualRwork = (pIC+pIS+f1s(4)+f2s(4))*(copulapdf('Gaussian',[cdf1_Grid,...
% %                  cdf2_Grid],dep).*pdf1_Grid.*pdf2_Grid);
% % CpdfSingalRwork = (f1s(2)+f1s(3)+f2s(2)+f2s(3))*(copulapdf('Gaussian',...
% %      [cdf1_rw_Grid,cdf2_rw_Grid],0).*pdf1_rw_Grid.*pdf2_rw_Grid);  % dependence is 0 as this is the single feature rework          
% % CpdfCombo = CpdfDualRwork + CpdfSingalRwork ;           
% % CpdfCombo = reshape(CpdfCombo,length(x1),length(x2));
% % 
% % figure(9)
% % m1 = mesh(x1,x2,CpdfCombo,'EdgeColor','black','LineWidth',1); hold on
% % m2 = mesh(x1,x2,pdfTot,'EdgeColor','yellow','LineWidth',1); hold on
% % set(m1,'FaceAlpha',0.4)
% % view(60, 30);  
% % set(gca,'FontSize',15)
% % xlabel('\mu_{1}'); ylabel('\mu_{2}'); zlabel('Probability Density');
% % legend('Case I surface','Case II surface');
% % 
% % 
% % 
% % 
% % 
% % 
