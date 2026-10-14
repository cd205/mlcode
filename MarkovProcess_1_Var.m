% 1 var Markov Process

% conventional model Bowling 2004

clear all
close all
clc

% Costs
SP = 120; %selling price
PC1 = 45; RC1 = 3; SC1 = 3;


CUT = [4.5];
sig11 = 1.7;

LSLx1 = 3;
USLx1 = 7;

%% conventional model Bowling 2004
p11 = 1 - normcdf(USLx1,CUT(1),sig11);
p12 = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11);
p13 = normcdf(LSLx1,CUT(1),sig11);

m11 = 1/(1-p11);

f12 = p12/(1-p11);
f13 = p13/(1-p11);

EPR = SP*f12 - PC1 - SC1*f13 - RC1*(m11-1)


%% Alternative series model
pI2 = 1 - normcdf(USLx1,CUT(1),sig11);
pIC = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11);
pIS = normcdf(LSLx1,CUT(1),sig11);

p22 = pI2;
p2C = pIC;
p2S = pIS;


mI2 = pI2/(1-p22);
m22 = 1/(1-p22);

fIC = pIC + (pI2*p2C/(1-p22));
fIS = pIS + (pI2*p2S/(1-p22));
f2C = p2C/(1-p22);
f2S = p2S/(1-p22);

EPR = SP*fIC - PC1 - (SC1*pIS + SC1*pI2*(p2S/(1-p22))) - RC1*mI2

SC1*pIS + SC1*pI2*(p2S/(1-p22))
SC1*(pIS/(1-p22))