clear all
close all
clc
%% grid
xp2 = linspace(6,7.5,50); xp3 = linspace(3.0,4.5,50);
[XP2 XP3] = meshgrid(xp2,xp3);
X = [XP2(:) XP3(:)];
%% statistical moments
MU = [6.8776 3.9006];
MU_rw = [6.8687 3.8965]
L = [6.8 3.8]; 
U = [7.2 4.2];  % Upper limit is scrap as these are holes
sig11 = 0.1362; sig22 = 0.0527;
rho = 0.7052
%% Marginals distributions 
% x2_pdf = normpdf(xp2,MU(1),sig11); % large diameter (x_2) pdf
fc2 = @(lim) normcdf(lim,MU(1),sig11); % large diameter (x_2) cdf
fc2rw = @(lim) normcdf(lim,MU_rw(1),sig11);

pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
pd3_rw = makedist('tLocationScale','mu',MU_rw(2),'sigma',sig22,'nu',2.2522);
% x3_pdf = normpdf(xp3,MU(2),sig22);%pdf(pd3,xp3);             
fc3 = @(lim) cdf(pd3,lim)              % small diameter (x_3) pdf
fc3rw = @(lim) cdf(pd3_rw,lim)
% fc3 = @(lim) normcdf(lim,MU(2),sig22);%cdf(pd3,xp3);   % alternative normal distributions for the x_3 feature
% fc3rw = @(lim) normcdf(lim,MU_rw(2),sig22);

% figure;
% plot(xp2,fc2(xp2),'m.-')
% figure;
% plot(xp3,fc3(xp3),'k-')
% 
% x2_pdf_Grid = normpdf(X(:,1),MU(1),sig11);
% x3_pdf_Grid = pdf(pd3,X(:,2));
% x2_cdf_Grid = normcdf(X(:,1),MU(1),sig11);
% x3_cdf_Grid = cdf(pd3,X(:,2));
% 
% 
% Ccdf = copulacdf('Gaussian',[x2_cdf_Grid,x3_cdf_Grid],rho);
% Ccdf = reshape(Ccdf,length(xp2),length(xp3));
% 
% figure;
% surf(xp2,xp3,Ccdf)



% 
% 
SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2]
Fb1b2 = copulacdf('Gaussian',[fc2(U(1)),fc3(U(2))],rho)
%Fb1b2o = mvncdf([U(1),U(2)],MU,SIGMA)
Fa1b2 = copulacdf('Gaussian',[fc2(L(1)),fc3(U(2))],rho)
%Fa1b2o = mvncdf([L(1),U(2)],MU,SIGMA)
Fb1a2 = copulacdf('Gaussian',[fc2(U(1)),fc3(L(2))],rho)
%Fb1a2o = mvncdf([U(1),L(2)],MU,SIGMA)
Fa1a2 = copulacdf('Gaussian',[fc2(L(1)),fc3(L(2))],rho)
%Fa1a2o = mvncdf([L(1),L(2)],MU,SIGMA)

pI2 = Fa1b2 - Fa1a2;
pI3 = Fb1a2 - Fa1a2;
pI4 = Fa1a2;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pIS = 1 - Fb1b2;
 
% Limits are reversed becasue the lower limit causes rework
MU_Rrw = L+(U-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
fc2Rrw = @(lim) normcdf(lim,MU_Rrw(1),sig11);
pd3_Rrw = makedist('tLocationScale','mu',MU_Rrw(2),'sigma',sig22,'nu',2.2522);
fc3Rrw = @(lim) cdf(pd3_Rrw,lim)

%p22 = fc2rw(L(1))
p22 = 1- fc2Rrw(U(1))
%p2C =fc2rw(U(1)) - fc2rw(L(1))
p2C = fc2Rrw(U(1)) - fc2Rrw(L(1))
%p2S = 1 - fc2rw(U(1))
p2S = fc2Rrw(L(1))

%p33 = fc3rw(L(2))
p33 = 1- fc3Rrw(U(2))
%p3C =fc3rw(U(2)) - fc3rw(L(2))
p3C = fc3Rrw(U(2)) - fc3Rrw(L(2))
%p3S = 1 - fc3rw(U(2))
p3S = fc3Rrw(L(2))

p42 = pI2; 
p43 = pI3; 
p44 = pI4;
p4C = pIC; 
p4S = pIS;
p5C = 1; 
p5S = 0; 
 
m12 = pI2/((1-p22)*(1-p44));
m13 = pI3/((1-p33)*(1-p44));
m14 = pI4/(1-p44);
 
fIC = pIC + pI2*p2C/((1-p22)*(1-p44)) + pI3*p3C/((1-p33)*(1-p44)) + pI4*p4C/(1-p44);
f2C = (p2C/(1-p22));%*p12;
f3C = (p3C/(1-p33));%*p13;
% %Sum_45 = p25*p12/((1-p22)*(1-p14)) + p35*p13/((1-p33)*(1-p14));
% %f45 = (p15/(1-p14)) + Sum_45;
f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;
% 
 %% Scrap parts
 % NOTE: p12, p13 and p14 that multiply f26, f36 and f46 account for the
 % number of parts flowing through into these rework stages,  this could be
 % done in the cost model rather than here
 % Sum_16 = p35*p13 + p46*p14 + p56*p15;
 % Prod_16 = (1-p22)*(1-p33)*(1-p44);
 % f16 = (p26*p12*(1-p33) + (Sum_16*Prod_16))/Prod_16;
fIS = pIS + pI2*p2S/((1-p22)*(1-p44)) + pI3*p3S/((1-p33)*(1-p44)) + pI4*p4S/(1-p44);
f2S = (p2S/(1-p22));%*p12;
f3S = (p3S/(1-p33));%*p13;
 %Sum_46 = p26*p16/((1-p22)*(1-p14)) + p36*p13/((1-p33)*(1-p14));
 %f46 = (p16/(1-p14)) + Sum_46;
f4S = (p42*p2S/((1-p22)*(1-p44)) + p43*p3S/((1-p33)*(1-p44)) + p4S/(1-p44));%*p14;
 
 
f1s = [fIC, f2C*(pI4*(pI2/(1-pI4))+pI2),...
            f3C*(pI4*(pI3/(1-pI4))+pI3)...
            pI4*(pIC/(1-pI4))];
f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
            f3S*(pI4*(pI3/(1-pI4))+pI3),...
            pI4*(pIS/(1-pI4))];

PC = 20;
SP = 100 ;
SC = [50 50 50 50];
RC = [0 5 5 10];
Profit = SP*fIC - PC - SC(1)*pIS - ...
         SC(2)*f2s(2) - SC(3)*f2s(3) - SC(4)*f2s(4) -...
         RC(2)*m12 - RC(3)*m13 - RC(4)*m14;    
        
        
%EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
MUs = [MU,MU_rw]
%% Optimise means for max profit 
[Profit] = ConRodProfit(MUs,SP,sig11,sig22,rho,L,U,PC,SC,RC,'L')

FUN = @(MUs) -1*ConRodProfit(MUs,SP,sig11,sig22,rho,L,U,PC,SC,RC,'L');
x0 = [U(1),U(2),U(1),U(2)];
LB = L;
UB = U;
options = optimset('TolFun',1e-7,'TolX',1e-6);
MU_opt_vec = fminsearchcon(FUN,x0,[LB LB],[UB UB],[],[],[],options)
Opt_val = -1*FUN(MU_opt_vec)


% %% Determine final manufacutred Distribution distribution
% % --------------- IMPORTANT -------------------
% % you MUST Reset the Upper limit (Scrap Limit) to a high number to scrap is included
% % --------------- IMPORTANT -------------------
% 
% MU = [6.8776 3.9006];
% MU_rw = [6.8687 3.8965]
% L = [6.8 3.8]; 
% U = [7 4.2]; % Upper limit is scrap as these are holes
% sig11 = 0.1362; sig22 = 0.05027;
% rho = 0.7052
% %% Marginals distributions 
% fc2 = @(lim) normcdf(lim,MU(1),sig11); % large diameter (x_2) cdf
% fc2rw = @(lim) normcdf(lim,MU_rw(1),sig11);
% pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
% pd3_rw = makedist('tLocationScale','mu',MU_rw(2),'sigma',sig22,'nu',2.2522);           
% fc3 = @(lim) cdf(pd3,lim);              % small diameter (x_3) pdf
% fc3rw = @(lim) cdf(pd3_rw,lim);
% 
% SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];
% Fb1b2 = copulacdf('Gaussian',[fc2(U(1)),fc3(U(2))],rho);
% Fa1b2 = copulacdf('Gaussian',[fc2(L(1)),fc3(U(2))],rho);
% Fb1a2 = copulacdf('Gaussian',[fc2(U(1)),fc3(L(2))],rho);
% Fa1a2 = copulacdf('Gaussian',[fc2(L(1)),fc3(L(2))],rho);
% 
% pI2 = Fa1b2 - Fa1a2;
% pI3 = Fb1a2 - Fa1a2;
% pI4 = Fa1a2;
% pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
% pIS = 1 - Fb1b2;
%  
% % Limits are reversed becasue the lower limit causes rework
% MU_Rrw = L+(U-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
% fc2Rrw = @(lim) normcdf(lim,MU_Rrw(1),sig11);
% pd3_Rrw = makedist('tLocationScale','mu',MU_Rrw(2),'sigma',sig22,'nu',2.2522);
% fc3Rrw = @(lim) cdf(pd3_Rrw,lim);
% 
% p22 = 1- fc2Rrw(U(1));
% p2C = fc2Rrw(U(1)) - fc2Rrw(L(1));
% p2S = fc2Rrw(L(1));
% 
% p33 = 1- fc3Rrw(U(2));
% p3C = fc3Rrw(U(2)) - fc3Rrw(L(2));
% p3S = fc3Rrw(L(2));
% 
% p42 = pI2; 
% p43 = pI3; 
% p44 = pI4;
% p4C = pIC; 
% p4S = pIS;
% p5C = 1; 
% p5S = 0; 
%  
% m12 = pI2/((1-p22)*(1-p44));
% m13 = pI3/((1-p33)*(1-p44));
% m14 = pI4/(1-p44);
%  
% fIC = pIC + pI2*p2C/((1-p22)*(1-p44)) + pI3*p3C/((1-p33)*(1-p44)) + pI4*p4C/(1-p44);
% f2C = (p2C/(1-p22));%*p12;
% f3C = (p3C/(1-p33));%*p13;
% f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;
% % 
% 
% fIS = pIS + pI2*p2S/((1-p22)*(1-p44)) + pI3*p3S/((1-p33)*(1-p44)) + pI4*p4S/(1-p44);
% f2S = (p2S/(1-p22));%*p12;
% f3S = (p3S/(1-p33));%*p13;
% f4S = (p42*p2S/((1-p22)*(1-p44)) + p43*p3S/((1-p33)*(1-p44)) + p4S/(1-p44));%*p14;
%  
%  
% f1s = [fIC, f2C*(pI4*(pI2/(1-pI4))+pI2),...
%             f3C*(pI4*(pI3/(1-pI4))+pI3)...
%             pI4*(pIC/(1-pI4))];
% f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
%             f3S*(pI4*(pI3/(1-pI4))+pI3),...
%             pI4*(pIS/(1-pI4))];
% 
% % dual feature rework form inital stage I and stage 4
% pdf2_Grid = normpdf(X(:,1),MU(1),sig11);
% pdf3_Grid = pdf(pd3,X(:,2));
% cdf2_Grid = normcdf(X(:,1),MU(1),sig11);
% cdf3_Grid = cdf(pd3,X(:,2));
% 
% % single feature rework form stage 2 and stage 3
% pdf2_rw_Grid = normpdf(X(:,1),MU_rw(1),sig11);
% pdf3_rw_Grid = pdf(pd3_rw,X(:,2));
% cdf2_rw_Grid = normcdf(X(:,1),MU_rw(1),sig11);
% cdf3_rw_Grid = cdf(pd3_rw,X(:,2));
% 
% 
% % work out where function will be zero, i.e. outside the limits. Aim is to
% % generate a vecotr of zeros and ones, zero where function is outside of
% % limits and a one where it is inside
% IX1 = (X(:,1)>=L(1) & X(:,1)<=U(1)); IX2 = (X(:,2)>=L(2) & X(:,2)<=U(2)); 
% %IX1 = (X(:,1)>=L(1)); IX2 = (X(:,2)>=L(2)); % includes scrap
% %X = [X1(:) X2(:)];
% IX = [IX1 IX2];
% sizeIX = size(IX);
% IXV = zeros(sizeIX(1),1);
% % Generate zeros and ones vector indicating where function is inside limits
% 
% for i = 1:sizeIX(1)
% if IX(i,1)==1 && IX(i,2)==1
%     IXV(i) = 1;
% end
% end
% figure;
% plot3(X(:,1),X(:,2),IXV,'r.'); grid on
% % (f1s(4)+f2s(4)+pIC+pIS).*IXV.*
% % Copula for dual rework
% Cpdf1 = copulapdf('Gaussian',[cdf2_Grid,cdf3_Grid],rho).*pdf2_Grid.*pdf3_Grid;
% Ccdf1 = copulacdf('Gaussian',[cdf2_Grid,cdf3_Grid],rho);
% Cft =  IXV.*(Cpdf1)./(copulacdf...
%     ('Gaussian',[normcdf(U(1),MU(1),sig11),cdf(pd3,U(2))],rho)-copulacdf...
%     ('Gaussian',[normcdf(L(1),MU(1),sig11),cdf(pd3,L(2))],rho));
% Cpdf1 = reshape(Cpdf1,length(xp2),length(xp3)); % can delete
% Ccdf1 = reshape(Ccdf1,length(xp2),length(xp3)); % can delete
% Cft = reshape(Cft,length(xp2),length(xp3));
% q_Cft  = trapz(xp3,trapz(xp2,Cft))
% 
% 
% figure;
% m1 = mesh(xp2,xp3,Cpdf1); grid on
% figure;
% m1 = mesh(xp2,xp3,Ccdf1); grid on
% 
% % Copula for single feature rework 
% Cpdf1_rw = copulapdf('Gaussian',[cdf2_rw_Grid,cdf3_rw_Grid],0).*pdf2_rw_Grid.*pdf3_rw_Grid;
% %Ccdf1_rw = copulacdf('Gaussian',[cdf1_rw_Grid,cdf2_rw_Grid],0);
% Cft_rw =  (f1s(2)+f1s(3)+f2s(2)+f2s(3)).*IXV.*(Cpdf1_rw)./(1-copulacdf...
%     ('Gaussian',[normcdf(L(1),MU_rw(1),sig11),cdf(pd3_rw,L(2))],0));
% 
% %Cpdf1_rw = reshape(Cpdf1_rw,length(x1),length(x2));
% %Ccdf1_rw = reshape(Ccdf1_rw,length(x1),length(x2));
% Cft_rw = reshape(Cft_rw,length(xp2),length(xp3));
% 
% TOTCopula = Cft + Cft_rw;
% figure(9)
% m1 = mesh(xp2,xp3,TOTCopula,'EdgeColor',[33 64 154]./255,'LineWidth',1); hold on
% 
% q_Cpdf1  = trapz(xp3,trapz(xp2,reshape(Cpdf1,length(xp2),length(xp3))))
% q_Cpdf1  = trapz(xp3,trapz(xp2,reshape(Cpdf1_rw,length(xp2),length(xp3))))
% q_TOTCopula = trapz(xp3,trapz(xp2,TOTCopula))
% 






