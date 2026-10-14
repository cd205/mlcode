function [Profit] = AngleDiaProfit(MUs,SP,sig11,sig22,rho,L,U,PC,SC,RC)

MU = MUs(1);
MU_rw = MUs(2);
MU(2) = ((U(2)-L(2))/2)+L(2); % the angle is mid way beteeen the upper and lower limits

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
cd2rw = @(lim) normcdf(lim,MU_rw(2),sig22);
x = linspace(2,10,100);

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
% pI2 + pI3 + pI4 + pIC + pIS % shuld be 1

% Limits are reversed becasue the lower limit causes rework
MU_Rrw = L+(U-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
cd1Rrw = @(lim) normcdf(lim,MU_Rrw(1),sig11);
%pd2_Rrw = makedist('tLocationScale','mu',MU_Rrw(2),'sigma',sig22,'nu',2.2522);
%fc3Rrw = @(lim) cdf(pd3_Rrw,lim)
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

cd1 = @(lim) normcdf(lim,avg_dia,sig11); 
cd2 = @(lim) normcdf(lim,MU(2),sig22); 
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

% p42 = pI2; 
% p43 = pI3; 
% p44 = pI4;
% p4C = pIC; 
% p4S = pIS;
% p5C = 1; 
% p5S = 0; 
 
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
        
%PC = 20;
%SP = 100 ;
%SC = [50 50 50 50];
%RC = [0 5 5 10];
Profit = SP*fIC - PC - SC(1)*pIS - ...
         SC(2)*f2s(2) - SC(3)*f2s(3) - SC(4)*f2s(4) -...
         RC(2)*m12 - RC(3)*m13 - RC(4)*m14;            
        