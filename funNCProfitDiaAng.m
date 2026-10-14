function [Profit,Eff35_int,Eff35,npnts1,npnts2,ProdCost,PartsinHist] = funNCProfitDiaAng(MU,MU_rw,sig11,sig22,rho,z1l,z1u,z2,npnts,Xplot,Eff35,MinEff)
% find the profit and non conformance from given means and standard
% deviations and costs



PC = 0.0321;
SP = 0.03914 ;
SC = [1000 1000 1000 1000];
RC = [0 0.0321 0.0321 0.0642];

% MUs = [0.5 0.53]; % MU(1) = diameter  MU(2) = Angle
% MU_rw = [0.45];
% sig11 = 0.109687; sig22 = 0.102564;
% rho = 0.0;%  0.7052
% z1 = 2; z2 = 2;
L = [MU(1)-z1l*sig11 MU(2)-z2*sig22]; 
U = [MU(1)+z1u*sig11 MU(2)+z2*sig22];  % Upper limit is scrap as these are holes
Lrw = [MU_rw(1)-z1l*sig11]; 
Urw = [MU_rw(1)+z1u*sig11];

%MU(1) = MU(1);
%MU(2) = ((U(2)-L(2))/2)+L(2); % the angle is mid way beteeen the upper and lower limits




cd1 = @(lim) normcdf(lim,MU(1),sig11); 
cd1rw = @(lim) normcdf(lim,MU_rw(1),sig11);
cd2 = @(lim) normcdf(lim,MU(2),sig22); 
cd2rw = @(lim) normcdf(lim,MU(2),sig22);
x = linspace(0,1,100);

%% Markov Chain bit
SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];

Fb1b2 = copulacdf('Gaussian',[cd1(U(1)),cd2(U(2))],rho);
Fa1b2 = copulacdf('Gaussian',[cd1(L(1)),cd2(U(2))],rho);
Fb1a2 = copulacdf('Gaussian',[cd1(U(1)),cd2(L(2))],rho);
Fa1a2 = copulacdf('Gaussian',[cd1(L(1)),cd2(L(2))],rho);

pI2 = Fa1b2 - Fa1a2;
pI3 = 0; % no angle only rework the 'Fb1a2 - Fa1a2' becomes part of pI4;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pI4 = cd1(U(1)) - pIC - pI2; % this is different to standard as angle can be
% reworked if its USL or under LSL
pIS = 1 - cd1(U(1));


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

% ang_over = normrnd(MU(2),sig22,10000);
% ang_over = ang_over(ang_over>U(2));
% mean_ang_over = mean(ang_over) % the mean angle of those that are over U(2)

fpd = @(x) normpdf(x,MU(2),sig22);
intfpd = @(X) integral(fpd,U(2),X) - integral(fpd,X,1000);
fsolveopts = optimset('Diagnostics','off', 'Display','off');
mean_ang_over = fsolve(intfpd,U(2),fsolveopts); % the mean angle of those that are over U(2)



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
         RC(2)*m12 - RC(3)*m13 - RC(4)*m14 ;           
ProdCost = PC + SC(1)*pIS + ...
         SC(2)*f2s(2) + SC(3)*f2s(3) + SC(4)*f2s(4) +...
         RC(2)*m12 + RC(3)*m13 + RC(4)*m14; 
     
%% now compute the conformance given all rework has been done and we can
% specify the distributiuon of the finish geometry   
% dual feature rework form inital stage I and stage 4

% Truncated distribution from dual features
npnts1 = ceil(npnts*(f1s(4)+f2s(4)+pIC+pIS)) ; % number of items in inital or dual feature rework
[Crnd1] = rmvnrnd([MU(1) MU(2)], SIGMA, npnts1, [-eye(2); eye(2)], [-L(1); -L(2); inf; U(2)]);
% Crnd1 has 2 columns
% Truncated distribution from single features
npnts2 = floor(npnts*(f1s(2)+f1s(3)+f2s(2)+f2s(3)));  % number of items in rework
[Crnd2] = rmvnrnd([MU_rw(1) MU(2)], SIGMA, npnts2,[-eye(2); eye(2)], [-L(1); -L(2); inf; U(2)]);
% Crnd2 has 2 columns
TOTCrnd = [Crnd1;Crnd2];
PartsinHist=size(TOTCrnd);
%% Check conformance

[X,Y] = meshgrid(Xplot,Xplot); % create a grid of x,y cords (dia and angle)
Eff35_int = interp2(X,Y,Eff35,TOTCrnd(:,1),TOTCrnd(:,2));

NC = (sum(Eff35_int <MinEff))/npnts; % calculate non-conformance

% penelty is NC is more than constraint 
% if NC >0.00621
%     Profit = Profit - NC*1e9;
% end
% if plot==1
%     figure(999);
%     hist(Eff35_int,50)
% end