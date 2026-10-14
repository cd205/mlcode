% Selim 3 process model 
clear all
close all
clc
% Costs
SP = 120; %selling price
PC1 = 25; PC2 = 20; PC3 = 12
RC1 = 15; RC2 = 12; RC3 = 8
SC1 = 10; SC2 = 17; SC3 = 5

CUT = [10.43 15.57 12.69];
sig11 = 1.0;
sig22 = 1.0;
sig33 = 1.0;

LSLx1 = 8;
LSLx2 = 13;
LSLx3 = 10;
USLx1 = 12;
USLx2 = 17;
USLx3 = 14;


p1r = 1 - normcdf(USLx1,CUT(1),sig11)
p1a = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11)
p1s = normcdf(LSLx1,CUT(1),sig11)
p2r = 1 - normcdf(USLx2,CUT(2),sig22)
p2a = normcdf(USLx2,CUT(2),sig22) - normcdf(LSLx2,CUT(2),sig22)
p2s = normcdf(LSLx2,CUT(2),sig22)
p3r = 1 - normcdf(USLx3,CUT(3),sig33)
p3a = normcdf(USLx3,CUT(3),sig33) - normcdf(LSLx3,CUT(3),sig33)
p3s = normcdf(LSLx3,CUT(3),sig33)



EPb = SP*((p1a/(1-p1r))*(p2a/(1-p2r))*(p3a/(1-p3r))) - ...
    ( (PC1 + SC1*(p1s/(1-p1r)) + RC1*(p1r/(1-p1r))) + ...
     (PC2 + (SC1+SC2)*(p2s/(1-p2r)) + RC2*(p2r/(1-p2r)))*(p1a/(1-p1r))+...
     (PC3 + (SC1+SC2+SC3)*(p3s/(1-p3r)) + RC3*(p3r/(1-p3r)))*((p1a/(1-p1r))*(p2a/(1-p2r)))  )