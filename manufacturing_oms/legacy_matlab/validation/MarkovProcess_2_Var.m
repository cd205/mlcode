clear all
close all
clc
% Costs
SP = 100; %selling price
PC1 = 4; PC2 = 6; RC1 = 1; RC2 = 2; SC1 = 5; SC2 = 3;

CUT = [5 6.9];
sig11 = 1.5;
sig22 = 3.9;
SIGMA = [sig11^2 0; 0 sig22^2];

LSLx1 = 1;
LSLx2 = 3;
USLx1 = 7;
USLx2 = 6;

%% conventional model Bowling 2004
p11 = 1 - normcdf(USLx1,CUT(1),sig11);
p12 = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11);
p14 = normcdf(LSLx1,CUT(1),sig11);
p22 = 1 - normcdf(USLx2,CUT(2),sig22);
p23 = normcdf(USLx2,CUT(2),sig22) - normcdf(LSLx2,CUT(2),sig22);
p24 = normcdf(LSLx2,CUT(2),sig22);

disp('Conventional Approach')
m11 = 1/(1-p11)
m22 = 1/(1-p22)

f13 = p12*p23/((1-p11)*(1-p22))
f24 = p24/(1-p22)

EPR = SP*f13 -(PC1 + PC2*p12/(1-p11))...
    - (SC1*p14/(1-p11) + SC2*(p12/(1-p11))*f24)...
    - (RC1*(m11-1) +RC2*(m22-1)*(p12/(1-p11)))


%% Alternative series model %%
% This is what you get by considering the the series set up for have the
% same form as the parallel set up (see Maple sheet 2StageSerial.mw in
% RollsRoyce/Report/MarvokChainPaper folder
pI2 = 1 - normcdf(USLx1,CUT(1),sig11);
pIC = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11);
pIS = normcdf(LSLx1,CUT(1),sig11);
ip22 = pI2;
ip2C = pIC;
ip2S = pIS;

pII2 = 1 - normcdf(USLx2,CUT(2),sig22);
pIIC = normcdf(USLx2,CUT(2),sig22) - normcdf(LSLx2,CUT(2),sig22);
pIIS = normcdf(LSLx2,CUT(2),sig22);
iip22 = pII2;
iip2C = pIIC;
iip2S = pIIS;

disp('Modified Approach')
mItoI = 1
mIi2 = pI2/(1-ip22)
%mIII = -((ip2C*pI2 - ip22*pIC + pIC)/(-1+ip22))
%mIii2 = (pII2*(ip2C*pI2 - ip22*pIC + pIC))/((-1+ip22)*(-1+iip22))
mIItoII = 1
mIIii2 = -pII2/(-1+iip22)

fIC = -(((pIC*pI2 - ip22*pIC + pIC)*pIIC)/(-1+ip22))...
    + (pII2*pIIC*(ip2C*pI2 - ip22*pIC + pIC))/((-1+ip22)*(-1+iip22))
fIIS = pIIS - ((pII2*iip2S)/(-1+iip22))

EPR = SP*fIC -(PC1 + PC2*(pIC+(pI2*ip2C/(1-ip22))))...
    - (SC1*(pIS+(pI2*ip2S/(1-ip22))) + SC2*(pIC+(pI2*ip2C/(1-ip22)))*fIIS)...
    - (RC1*(mIi2) + RC2*(mIIii2)*(pIC+(pI2*ip2C/(1-ip22))))

%% Alternative series model General Equation
% Consider a mulit-stage process, but instead of doing the markov chain for
% the process use a modified version os Eqn 2 Selim [2011].
disp('Generalised Multistage Approach')
% 2 stages, use the 'ALTERNATIVE 1 STAGE MODEL' TWICE %
%%%%%% FIRST STAGE %%%%%%
pI1_2 = 1 - normcdf(USLx1,CUT(1),sig11);
pI1_C = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11);
pI1_S = normcdf(LSLx1,CUT(1),sig11);
p1_22 = pI1_2;
p1_2C = pI1_C;
p1_2S = pI1_S;

mI1_2 = pI1_2/(1-p1_22);
%m21_2 = 1/(1-p1_22);
fI1_C = pI1_C + (pI1_2*p1_2C/(1-p1_22));
%fI1_S = pI1_S + (pI1_2*p1_2S/(1-p1_22));

SR_1 = SC1*pI1_S + SC1*pI1_2*(p1_2S/(1-p1_22))
RW_1 = RC1*mI1_2

%%%%%% SECOND STAGE %%%%%%
pI2_2 = 1 - normcdf(USLx2,CUT(2),sig22);
pI2_C = normcdf(USLx2,CUT(2),sig22) - normcdf(LSLx2,CUT(2),sig22);
pI2_S = normcdf(LSLx2,CUT(2),sig22);
p2_22 = pI2_2;
p2_2C = pI2_C;
p2_2S = pI2_S;

mI2_2 = pI2_2/(1-p2_22);
%m21_2 = 1/(1-p1_22);
fI2_C = pI2_C + (pI2_2*p2_2C/(1-p2_22));
%fI1_S = pI1_S + (pI1_2*p1_2S/(1-p1_22));

SR_2 = SC2*pI2_S + SC2*pI2_2*(p2_2S/(1-p2_22))
RW_2 = RC2*mI2_2

PC_Tot = PC1*1 + PC2*fI1_C
SR_Tot = SR_1*1 + SR_2*fI1_C
RW_Tot = RW_1*1 + RW_2*fI1_C
SP_Tot = SP*fI1_C*fI2_C

EPR = SP_Tot - PC_Tot - SR_Tot - RW_Tot
