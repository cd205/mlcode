% Selim 2 process model with Markov and numerical probabilities
clear all
close all
clc
% Costs
SP = 120; %selling price
PC1 = 25; PC2 = 20; RC1 = 15; RC2 = 12; SC1 = 10; SC2 = 17;

CUT = [10.466 15.575];
sig11 = 1.0;
sig22 = 1.0;
SIGMA = [sig11^2 0; 0 sig22^2];

sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));
LSLx1 = 8;
LSLx2 = 13;
USLx1 = 12;
USLx2 = 17;


p1r = 1 - normcdf(USLx1,CUT(1),sig11)
p1a = normcdf(USLx1,CUT(1),sig11) - normcdf(LSLx1,CUT(1),sig11)
p1s = normcdf(LSLx1,CUT(1),sig11)
p2r = 1 - normcdf(USLx2,CUT(2),sig22)
p2a = normcdf(USLx2,CUT(2),sig22) - normcdf(LSLx2,CUT(2),sig22)
p2s = normcdf(LSLx2,CUT(2),sig22)

Num1 = 10000000;
format Short
% 1st stage
[Scrap1, Conform1, Rework1] = SimNormRnd(CUT(1),sig11,Num1,LSLx1,USLx1)
RWK1 = Rework1;
ConformVec = Conform1;
count1 = 1;
while RWK1 > 0
    [SCR, CON1, RWK1] = SimNormRnd(CUT(1),sig11,RWK1,LSLx1,USLx1);
    Scrap1 = Scrap1 + SCR;
    Conform1 = Conform1 + CON1;
    Rework1 = Rework1 + RWK1;
    count1 = count1 + 1;
    ConformVec(count1) = CON1;
end
ConformAfterStage1 = sum(ConformVec)/Num1
stage1 = struct('Scrap1',Scrap1,'Conform1',Conform1,'Rework1',Rework1,'count1',count1);
% 2nd stage
Num2 = Conform1
[Scrap2, Conform2, Rework2] = SimNormRnd(CUT(2),sig22,Num2,LSLx2,USLx2);
RWK2 = Rework2;
Confrom2Count = Conform2
count2 = 1;
ScrapF = Scrap1 + Scrap2;
while RWK2 > 0
    [SCR2, CON2, RWK2] = SimNormRnd(CUT(2),sig22,RWK2,LSLx2,USLx2);
    ScrapF = ScrapF + SCR2;
    Scrap2 = Scrap2 + SCR2;
    Conform2 = Conform2 + CON2;
    Confrom2Count  = Confrom2Count + CON2;
    Rework2 = Rework2 + RWK2;
    count2 = count2 + 1;
end
Confrom2Count;
stage2 = struct('Scrap2',Scrap2,'Conform2',Conform2,'Rework2',Rework2,'count1',count2);
Final = struct('TotScrap',ScrapF,'TotConform',Conform2)

% Markov Chain Probs
m11 = 1/(1-p1r);
m12 = p1a/((1-p1r)*(1-p2r));
m22 = 1/(1-p2r);
f13 = (p1a*p2a)/((1-p1r)*(1-p2r));
f14 = p1s/(1-p1r) + (p1a*p2s/((1-p1r)*(1-p2r)));
f23 = p2a/(1-p2r);
f24 = p2s/(1-p2r);
M = struct('m11',m11,'m12',m12,'m22',m22)
ProbsM_num = struct('m11',(Rework1+Num1)/Num1,'m22',(Rework2+Num2)/Num2)
F = struct('f13',f13,'f14',f14,'f23',f23,'f24',f24)
ProbsF_num = struct('f13',Conform2/Num1,'f14',ScrapF/Num1,'f23',Conform2/Num2,'f24',Scrap2/Num2)

F_Stages = struct('Accept_Stg1',p1a/(1-p1r),'Scrap_Stage1',p1s/(1-p1r))
Probs_Stages = struct('Accept_Stg1',Conform1/Num1,'Scrap_Stage1',Scrap1/Num1)

% Numerical Cost
%format LongG
SellPrice = SP*(Conform2)/Num1
ProCost1 = PC1*Num1 % everything passes through stage1
ProCost2a = PC2*Num1*(p1a/(1-p1r)) % compoents processed through stage 2
% this is same as ProCost2 = PC2*Num2 
ProCost2a = PC2*Num1*(p1a/(1-p1r))
Scrap_s1= SC1*Scrap1/Num1 % scrap at 2 relative to inita5l batch
Scrap_s2 = SC2*Scrap2/Num1 % rework at 2 relative to inital batch
ScrapTot = (Scrap_s1 + Scrap_s2)
Rework1 = RC1*Rework1/Num1 % scrap at 2 relative to inital batch
Rework2 = RC2*Rework2/Num1 % rework at 2 relative to inital batch
RworkTot = (Rework1 + Rework2)

% Anylitical Cost
SellPriceA = SP*f13;
Scrap_s1A = SC1*p1s/(1-p1r) % scrap from 1st stage
Scrap_s2A = SC2*f24*p1a/(1-p1r)   % 2nd stage scrap:scrap from 2nd 
sfd = SC2*(p2s/(1-p2r))*(p1a/(1-p1r))
% stage (this is Scrap2/Num2) normalised by components that actually went into stage 2 (p1a/(1-p1r)) 
Scrap_s2Aa = SC2*(f14-p1s/(1-p1r)); % 2nd stage scrap: total scrap - scrap from 1st stage (p1s/(1-p1r))
Rework1A = RC1*(m11-1)
Rework2A = RC2*(m22-1)*(p1a/(1-p1r))

ProdCost =  PC1 + PC2*(p1a/(1-p1r)) + Scrap_s1A + Scrap_s2A + Rework1A + Rework2A
% EP_Selim below is Eqn (1) from Selim 2011 
EPa = (SP*(1-f14)) - (PC1 + PC2*(p1a/(1-p1r))) - (SC1*f14 + SC2*(p1a/(1-p1r))*f24)...
    - (RC1*(m11-1) + RC2*(m22-1)*(p1a/(1-p1r)))

% watch out for 2nd Scrap term as the SC = SC1 + SC2 in Dodd [2014] 
% SC = SC2.  To make them equivalent Dodd [2014] must make SC2 = SC1 + SC2
EP_Selim = SP*((p1a/(1-p1r))*(p2a/(1-p2r))) - ...
    ( (PC1 + SC1*(p1s/(1-p1r)) + RC1*(p1r/(1-p1r))) + ...
     (PC2 + (SC2)*(p2s/(1-p2r)) + RC2*(p2r/(1-p2r)))*(p1a/(1-p1r)) )

 
 EPc = (SP*(1-f14)) - (PC1 + PC2*(p1a/(1-p1r))) - (SC1*(p1s/(1-p1r)) + (SC1+SC2)*(p1a/(1-p1r))*f24)...
    - (RC1*(m11-1) + RC2*(m22-1)*(p1a/(1-p1r)))