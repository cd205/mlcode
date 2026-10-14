% prod cost form copula
clear all
close all
clc
PC = 0.0321;
SP = 0.03914 ;
SC = [1000 1000 1000 1000];
RC = [0 0.0321 0.0321 0.0642];

MUs = [0.5 0.53]; % MU(1) = diameter  MU(2) = Angle
MU_rw = [0.45];
sig11 = 0.109687; sig22 = 0.102564;
rho = 0.0;%  0.7052
zl = 2; zu = 2;
L = [MUs(1)-zl*sig11 MUs(2)-zu*sig22]; 
U = [MUs(1)+zl*sig11 MUs(2)+zu*sig22];  % Upper limit is scrap as these are holes
Lrw = [MU_rw(1)-zl*sig11]; 
Urw = [MU_rw(1)+zl*sig11];

MU(1) = MUs(1);
MU(2) = ((U(2)-L(2))/2)+L(2); % the angle is mid way beteeen the upper and lower limits

npnts = 1e4
%% statistical moments
%MU = [7.3  33.8920]; % MU(1) = diameter  MU(2) = Angle
%MU_rw = [7.79 33.8920]
%L = [7.22367 30.93197]; 
%U = [8.44563 36.85205];  % Upper limit is scrap as these are holes
%sig11 = 0.5; sig22 = 2;
%rho = 0;%  0.7052
%% Marginals distributions 

cd1 = @(lim) normcdf(lim,MU(1),sig11); 
cd1rw = @(lim) normcdf(lim,MU_rw(1),sig11);
cd2 = @(lim) normcdf(lim,MU(2),sig22); 
cd2rw = @(lim) normcdf(lim,MU(2),sig22);
x = linspace(0,1,100);

% pd2 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
% pd2rw = makedist('tLocationScale','mu',MU_rw(2),'sigma',sig22,'nu',2.2522);
% cd2 = @(lim) cdf(pd2,lim);        
% cd2rw = @(lim) cdf(pd2rw,lim);

%% Markov Chain bit
SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];

Fb1b2 = copulacdf('Gaussian',[cd1(U(1)),cd2(U(2))],rho);
Fa1b2 = copulacdf('Gaussian',[cd1(L(1)),cd2(U(2))],rho);
Fb1a2 = copulacdf('Gaussian',[cd1(U(1)),cd2(L(2))],rho);
Fa1a2 = copulacdf('Gaussian',[cd1(L(1)),cd2(L(2))],rho);

pI2 = Fa1b2 - Fa1a2;
pI3 = 0; % no angle only rework the 'Fb1a2 - Fa1a2' becomes part of pI4;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pI4 = cd1(U(1)) - pIC - pI2;  % this is different to standard as angle can be
% reworked if its USL or under LSL
pIS = 1 - cd1(U(1));
pI2 + pI3 + pI4 + pIC + pIS % shuld be 1

% Limits are reversed becasue the lower limit causes rework
MU_Rrw = L(1)+(U(1)-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
cd1Rrw = @(lim) normcdf(lim,MU_Rrw(1),sig11);
% pI2Rrwthis is needed for the truncated distribution for the single reature
% rework (due to different mean) 
pI2Rrw = copulacdf('Gaussian',[cd1Rrw(L(1)),cd2rw(U(2))],rho)...
       -copulacdf('Gaussian',[cd1Rrw(L(1)),cd2rw(L(2))],rho);


p22 = 1- cd1Rrw(U(1));
p2C = cd1Rrw(U(1)) - cd1Rrw(L(1));
p2S = cd1Rrw(L(1));

% these rework anlge probs don't exist can't rework just the angle so pI3
% is fed into pI4 such that all the angle only rework goes into dual
% feature rework 
p33 = 0;% 1- fc3Rrw(U(2))  % Angle to Angle rework
p3C = 0;%fc3Rrw(U(2)) - fc3Rrw(L(2)) % Angle to conform
p3S = 0;%fc3Rrw(L(2))     % Angle to scrap


% different Fb1b2, Fa1b2, Fb1a2 and Fa1a2 as angle rework alters diameter
% distributions of angle outside limits
thick = 12;  % thickness of airfoil (normal depth of hole (i.e. depth of hole is anlge was 90 degrees

ang_over = normrnd(MU(2),sig22,1000);
ang_over = ang_over(ang_over>U(2));
mean_ang_over = mean(ang_over); % the mean angle of those that are over U(2)


a_over = abs(mean_ang_over-MU(2));  % over average angle between manufacutured angle and correct angle MU(2)
Tot_ext_over =  2*(tan(a_over*(pi/180))*(thick/(cos((90-MU(2))*(pi/180)))));
avg_dia = MU(1)+ Tot_ext_over; % the average increase in diameter

cd1 = @(lim) normcdf(lim,avg_dia,sig11); % new cd1 as mean has changed

SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];
Fb1b2a = copulacdf('Gaussian',[cd1(U(1)),cd2(U(2))],rho);
Fa1b2a = copulacdf('Gaussian',[cd1(L(1)),cd2(U(2))],rho);
Fb1a2a = copulacdf('Gaussian',[cd1(U(1)),cd2(L(2))],rho);
Fa1a2a = copulacdf('Gaussian',[cd1(L(1)),cd2(L(2))],rho);

p42 = Fa1b2a - Fa1a2a;
p43 = 0; % no angle only rework the 'Fb1a2 - Fa1a2' becomes part of pI4;
p4C = Fb1b2a - Fa1b2a - Fb1a2a + Fa1a2a;
p44 = cd1(U(1)) - p4C - p42;
p4S = 1 - cd1(U(1));
 
m12 = pI2/((1-p22)*(1-p44));
m13 = pI3/((1-p33)*(1-p44));
m14 = pI4/(1-p44);
 
fIC = pIC + pI2*p2C/((1-p22)*(1-p44)) + pI3*p3C/((1-p33)*(1-p44)) + pI4*p4C/(1-p44);
f2C = (p2C/(1-p22));%*p12;
f3C = (p3C/(1-p33));%*p13;
f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;

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
        
%PC = 20;
%SP = 100 ;
%SC = [50 50 50 50];
%RC = [0 5 5 10];
Profit = SP*fIC - PC - SC(1)*pIS - ...
         SC(2)*f2s(2) - SC(3)*f2s(3) - SC(4)*f2s(4) -...
         RC(2)*m12 - RC(3)*m13 - RC(4)*m14            
        
     
%% now compute the conformance given all rework has been done and we can
% specify the distributiuon of the finish geometry   
% dual feature rework form inital stage I and stage 4

xp1 = linspace(0,1,80); xp2 = linspace(0,1,80);
[XP1 XP2] = meshgrid(xp1,xp2);
X = [XP1(:) XP2(:)];

pdf1_Grid = normpdf(X(:,1),MU(1),sig11);
pdf2_Grid = normpdf(X(:,2),MU(2),sig22);
cdf1_Grid = normcdf(X(:,1),MU(1),sig11);
cdf2_Grid = normcdf(X(:,2),MU(2),sig22);

% single feature rework form stage 2 and stage 3
pdf1_rw_Grid = normpdf(X(:,1),MU_Rrw(1),sig11);
pdf2_rw_Grid = normpdf(X(:,2),MU(2),sig22);
cdf1_rw_Grid = normcdf(X(:,1),MU_Rrw(1),sig11);
cdf2_rw_Grid = normcdf(X(:,2),MU(2),sig22);


% work out where function will be zero, i.e. outside the limits. Aim is to
% generate a vecotr of zeros and ones, zero where function is outside of
% limits and a one where it is inside
IX1 = (X(:,1)>=L(1) & X(:,1)<=inf); IX2 = (X(:,2)>=L(2) & X(:,2)<=U(2)); 
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
figure(1);
plot3(X(:,1),X(:,2),IXV,'r.'); grid on

% Copula for dual rework
npnts1 = ceil(npnts*(f1s(4)+f2s(4)+pIC+pIS))  % number of items in inital or dual feature rework
Cpdf1 = copulapdf('Gaussian',[cdf1_Grid,cdf2_Grid],rho).*pdf1_Grid.*pdf2_Grid;
Ccdf1 = copulacdf('Gaussian',[cdf1_Grid,cdf2_Grid],rho);
[Crnd1] = rmvnrnd([MU(1) MU(2)], SIGMA, npnts1, [-eye(2); eye(2)], [-L(1); -L(2); inf; U(2)]);
size(Crnd1)
figure(2)
plot(Crnd1(:,1),Crnd1(:,2),'.'); hold on
%Crnd1 = (Crnd1(:,1)>=L(1) & Crnd1(:,1)<=U(1)) & (Crnd1(:,2)>=L(2) & Crnd1(:,2)<=U(2)); 
size(Crnd1)
Trunn= IXV.*(Cpdf1); Trunn = reshape(Trunn,length(xp1),length(xp2));
q_Trunn = trapz(xp2,trapz(xp1,Trunn))
Cft =  (f1s(4)+f2s(4)+pIC+pIS).*((IXV.*(Cpdf1))./...
    (cd2(U(2))-cd2(L(2))-pI2));%The denominator is equal to the area displayed by figure 1

Cft = reshape(Cft,length(xp1),length(xp2));
q_Cft  = trapz(xp2,trapz(xp1,Cft))


% IX1 = (X(:,1)>=L(1) & X(:,1)<=inf); IX2 = (X(:,2)>=L(2) & X(:,2)<=U(2)); 
% %IX1 = (X(:,1)>=L(1)); IX2 = (X(:,2)>=L(2)); % includes scrap
% %X = [X1(:) X2(:)];
% IX = [IX1 IX2];
% sizeIX = size(IX);
% IXV = zeros(sizeIX(1),1);
% Generate zeros and ones vector indicating where function is inside limits

% % Redefine where function is zero as rework mean may be different to first
% % cut mean
% for i = 1:sizeIX(1)
% if IX(i,1)==1 && IX(i,2)==1
%     IXV(i) = 1;
% end
% end
% Copula from single feature rework 
npnts2 = floor(npnts*(f1s(2)+f1s(3)+f2s(2)+f2s(3)))  % number of items in rework
Cpdf1_rw = copulapdf('Gaussian',[cdf1_rw_Grid,cdf2_rw_Grid],0).*pdf1_rw_Grid.*pdf2_rw_Grid;
Trunnn= IXV.*(Cpdf1_rw); Trunnn = reshape(Trunnn,length(xp1),length(xp2));
[Crnd2] = rmvnrnd([MU_rw(1) MU(2)], SIGMA, npnts2,[-eye(2); eye(2)], [-L(1); -L(2); inf; U(2)]);
q_Trunnn2 = trapz(xp2,trapz(xp1,Trunnn))
Cft_rw = (f1s(2)+f1s(3)+f2s(2)+f2s(3)).*((IXV.*(Cpdf1_rw))./...
     (cd2rw(U(2))-cd2rw(L(2))-pI2Rrw));
figure(2)
plot(Crnd2(:,1),Crnd2(:,2),'r.'); hold on
% difference in the CDFs i.e. copulacdf(U(1),U(2) - copulacdf(L(1),L(2)
% as it should for dual feature rework above

Cft_rw = reshape(Cft_rw,length(xp1),length(xp2));
q_Cft_rw  = trapz(xp2,trapz(xp1,Cft_rw))
%Cpdf1_rw = reshape(Cpdf1_rw,length(x1),length(x2));
%Ccdf1_rw = reshape(Ccdf1_rw,length(x1),length(x2));
Cft_rw = reshape(Cft_rw,length(xp1),length(xp2));
Totalvol = q_Cft_rw + q_Cft
TOTCopula = Cft + Cft_rw;
q_TOTCopula = trapz(xp2,trapz(xp1,TOTCopula)) % this is same check as TotalVol

TOTCrnd = [Crnd1;Crnd2];
figure(11);
plot(TOTCrnd(:,1),TOTCrnd(:,2),'m.'); hold on


xp11 = linspace(0,1,500); xp22 = linspace(0,1,500);
[XP11 XP22] = meshgrid(xp11,xp22);
XX = [XP11(:) XP22(:)];
MU  = MU
MU_rw = MU_rw
[TOTCopula1]=AngDiaCopula(XX,f1s,f2s,pI2,pIC,pIS,sig11,sig22,MU,MU_rw,L,U,rho);
TOTCopula1 = reshape(TOTCopula1,length(xp11),length(xp22));
figure;
m1 = mesh(xp1,xp2,TOTCopula,'EdgeColor',[33 64 154]./255,'LineWidth',1); hold on
alpha 0.2
surf(xp11,xp22,TOTCopula1)
colorbar
set(gca,'FontSize',15)
xlabel('x_{1} (cm)'); 
ylabel('x_{2} (cm)'); 
zlabel('Probability Density');
f = @(X) AngDiaCopula(X,f1s,f2s,pI2,pIC,pIS,sig11,sig22,MU,MU_rw,L,U,rho)
x = slicesample([0.5 0.5],2000,'pdf',f,'thin',5,'burnin',1000);
figure(11);
plot(x(:,1),x(:,2),'.')
% [X,Y] = meshgrid(Xplot,Xplot); % create a grid of x,y cords (angle and dia)
% % define correlation matrix
% SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];
% % % generate points from normal distribtuion
% % x = mvnrnd(MU,SIGMA,pnts);
% % 
% Eff35_int = interp2(X,Y,Eff35,x(:,1),x(:,2));
% 
% NC = size(find(Eff35_int <MinEff),1)/pnts; % calculate non-conformance

