%% Determine final manufacutred Distribution distribution
% --------------- IMPORTANT -------------------
% you MUST Reset the Upper limit (Scrap Limit) to a high number to scrap is included
% --------------- IMPORTANT -------------------
%clear all
%close all
%clc
% Grid
xp2 = linspace(6.7,7.3,50); xp3 = linspace(3.7,4.2,50);
[XP2 XP3] = meshgrid(xp2,xp3);
X = [XP2(:) XP3(:)];

MU = [6.8776 3.9006];
MU_rw = [6.8687 3.8965]
L = [6.8 3.8]; 
U = [20 20]; % Upper limit is scrap as these are holes
sig11 = 0.1362; sig22 = 0.05027;
rho = 0.7052
%% Marginals distributions 
fc2 = @(lim) normcdf(lim,MU(1),sig11); % large diameter (x_2) cdf
fc2rw = @(lim) normcdf(lim,MU_rw(1),sig11);
pd3 = makedist('Normal','mu',MU(2),'sigma',sig22);
pd3_rw = makedist('Normal','mu',MU_rw(2),'sigma',sig22); 
%pd3 = makedist('GeneralizedExtremeValue','k',0.2,'mu',MU(2),'sigma',sig22);
%pd3_rw = makedist('GeneralizedExtremeValue','k',0.2,'mu',MU_rw(2),'sigma',sig22);          
fc3 = @(lim) cdf(pd3,lim);              % small diameter (x_3) pdf
fc3rw = @(lim) cdf(pd3_rw,lim);

figure;
plot(xp3,pdf(pd3,xp3),'r-'); grid on

SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];
Fb1b2 = copulacdf('Gaussian',[fc2(U(1)),fc3(U(2))],rho);
Fa1b2 = copulacdf('Gaussian',[fc2(L(1)),fc3(U(2))],rho);
Fb1a2 = copulacdf('Gaussian',[fc2(U(1)),fc3(L(2))],rho);
Fa1a2 = copulacdf('Gaussian',[fc2(L(1)),fc3(L(2))],rho);

pI2 = Fa1b2 - Fa1a2;
pI3 = Fb1a2 - Fa1a2;
pI4 = Fa1a2;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pIS = 1 - Fb1b2;
 
% Limits are reversed becasue the lower limit causes rework
MU_Rrw = L+(U-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
fc2Rrw = @(lim) normcdf(lim,MU_Rrw(1),sig11);
pd3_Rrw = makedist('tLocationScale','mu',MU_Rrw(2),'sigma',sig22,'nu',2.2522);
fc3Rrw = @(lim) cdf(pd3_Rrw,lim);

p22 = 1- fc2Rrw(U(1));
p2C = fc2Rrw(U(1)) - fc2Rrw(L(1));
p2S = fc2Rrw(L(1));

p33 = 1- fc3Rrw(U(2));
p3C = fc3Rrw(U(2)) - fc3Rrw(L(2));
p3S = fc3Rrw(L(2));

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
f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;
% 

fIS = pIS + pI2*p2S/((1-p22)*(1-p44)) + pI3*p3S/((1-p33)*(1-p44)) + pI4*p4S/(1-p44);
f2S = (p2S/(1-p22));%*p12;
f3S = (p3S/(1-p33));%*p13;
f4S = (p42*p2S/((1-p22)*(1-p44)) + p43*p3S/((1-p33)*(1-p44)) + p4S/(1-p44));%*p14;
 
 
f1s = [fIC, f2C*(pI4*(pI2/(1-pI4))+pI2),...
            f3C*(pI4*(pI3/(1-pI4))+pI3)...
            pI4*(pIC/(1-pI4))];
f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
            f3S*(pI4*(pI3/(1-pI4))+pI3),...
            pI4*(pIS/(1-pI4))];

% dual feature rework form inital stage I and stage 4
pdf2_Grid = normpdf(X(:,1),MU(1),sig11);
pdf3_Grid = pdf(pd3,X(:,2));
cdf2_Grid = normcdf(X(:,1),MU(1),sig11);
cdf3_Grid = cdf(pd3,X(:,2));

% single feature rework form stage 2 and stage 3
pdf2_rw_Grid = normpdf(X(:,1),MU_rw(1),sig11);
pdf3_rw_Grid = pdf(pd3_rw,X(:,2));
cdf2_rw_Grid = normcdf(X(:,1),MU_rw(1),sig11);
cdf3_rw_Grid = cdf(pd3_rw,X(:,2));


% work out where function will be zero, i.e. outside the limits. Aim is to
% generate a vecotr of zeros and ones, zero where function is outside of
% limits and a one where it is inside
IX1 = (X(:,1)>=L(1) & X(:,1)<=U(1)); IX2 = (X(:,2)>=L(2) & X(:,2)<=U(2)); 
%IX1 = (X(:,1)>=L(1)); IX2 = (X(:,2)>=L(2)); % includes scrap
%X = [X1(:) X2(:)];
IX = [IX1 IX2];
sizeIX = size(IX);
IXV = zeros(sizeIX(1),1);
% Generate zeros and ones vector indicating where function is inside limits

for i = 1:sizeIX(1)
if IX(i,1)==1 && IX(i,2)==1
    IXV(i) = 1;
end
end
figure;
plot3(X(:,1),X(:,2),IXV,'r.'); grid on

% Copula for dual rework
Cpdf1 = copulapdf('Gaussian',[cdf2_Grid,cdf3_Grid],rho).*pdf2_Grid.*pdf3_Grid;
Ccdf1 = copulacdf('Gaussian',[cdf2_Grid,cdf3_Grid],rho);
Trunn= IXV.*(Cpdf1); Trunn = reshape(Trunn,length(xp2),length(xp3));
q_Trunn = trapz(xp3,trapz(xp2,Trunn));
Cft =  (f1s(4)+f2s(4)+pIC+pIS).*IXV.*(Cpdf1)./q_Trunn; % the denominator should really be like 
% line 237-275 in 'CopulaGaussianMixtureFourMeans_ve_TwoMeans in
% '\OptimalCMCDistribution'

% Cpdf1 = reshape(Cpdf1,length(xp2),length(xp3));
% Ccdf1 = reshape(Ccdf1,length(xp2),length(xp3));
% figure;
% mesh(xp2,xp3,Cpdf1)
% figure;
% mesh(xp2,xp3,Cpdf1)


Cft = reshape(Cft,length(xp2),length(xp3));
q_Cft  = trapz(xp3,trapz(xp2,Cft));


% Copula from single feature rework 
Cpdf1_rw = copulapdf('Gaussian',[cdf2_rw_Grid,cdf3_rw_Grid],0).*pdf2_rw_Grid.*pdf3_rw_Grid;
Trunn= IXV.*(Cpdf1_rw); Trunn = reshape(Trunn,length(xp2),length(xp3));
q_Trunn = trapz(xp3,trapz(xp2,Trunn));
Cft_rw = (f1s(2)+f1s(3)+f2s(2)+f2s(3)).*IXV.*(Cpdf1_rw)./q_Trunn; % the denominator should really the 
% difference in the CDFs i.e. copulacdf(U(1),U(2) - copulacdf(L(1),L(2)
% as it should for dual feature rework above

Cft_rw = reshape(Cft_rw,length(xp2),length(xp3));
q_Cft_rw  = trapz(xp3,trapz(xp2,Cft_rw))
%Cpdf1_rw = reshape(Cpdf1_rw,length(x1),length(x2));
%Ccdf1_rw = reshape(Ccdf1_rw,length(x1),length(x2));
Cft_rw = reshape(Cft_rw,length(xp2),length(xp3));

TOTCopula = Cft + Cft_rw;
figure(9)
m1 = mesh(xp2,xp3,TOTCopula,'EdgeColor',[33 64 154]./255,'LineWidth',1); hold on
%m1 = mesh(xp2,xp3,TOTCopula,'EdgeColor',[237 28 36]./255,'LineWidth',1); hold on
set(gca,'FontSize',15)
xlabel('x_{2} (cm)'); 
ylabel('x_{3} (cm)'); 
zlabel('Probability Density');
axis([6.7 7.3 3.7 4.2 0 60])
%q_Cpdf1  = trapz(xp3,trapz(xp2,Cpdf1))
%q_Cpdf1  = trapz(xp3,trapz(xp2,reshape(Cpdf1_rw,length(xp2),length(xp3))))
q_TOTCopula = trapz(xp3,trapz(xp2,TOTCopula))







