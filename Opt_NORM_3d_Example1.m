function [Prt_Total_Cost Prt_Rwork_Cost] = Opt_NORM_3d_Example1(means)
% accompanying file to Opt_CMC_3d_Example1 but with a normal CDF

MU = [means(1) means(2) means(3)];
sig11 = 1;
sig12 = 0;
sig13 = 0;

sig21 = 0;
sig22 = 1;
sig23 = 0;

sig31 = 0;
sig32 = 0;
sig33 = 1;

A = [3 3 3];
B = [7 7 7];

p = 0;
range = [0 10]; 
num = length(A);

SIGMA = [sig11^2 p*sig11*sig22 p*sig11*sig33;...
         p*sig22*sig11 sig22^2 p*sig22*sig33;...
         p*sig33*sig11 p*sig33*sig22 sig33^2];
     
Fa1a2a3 = mvncdf(A,MU,SIGMA);
Fa1a2b3 = mvncdf([A(1) A(2) B(3)],MU,SIGMA);
Fa1b2a3 = mvncdf([A(1) B(2) A(3)],MU,SIGMA);
Fa1b2b3 = mvncdf([A(1) B(2) B(3)],MU,SIGMA);
Fb1a2a3 = mvncdf([B(1) A(2) A(3)],MU,SIGMA);
Fb1a2b3 = mvncdf([B(1) A(2) B(3)],MU,SIGMA);
Fb1b2a3 = mvncdf([B(1) B(2) A(3)],MU,SIGMA);
Fb1b2b3 = mvncdf([B(1) B(2) B(3)],MU,SIGMA);

s1 = struct('Fa1a2a3',Fa1a2a3,...
            'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,'Fb1a2a3',Fb1a2a3,...
            'Fa1b2b3',Fa1b2b3,'Fb1a2b3',Fb1a2b3,'Fb1b2a3',Fb1b2a3,...
            'Fb1b2b3',Fb1b2b3);
% Conformance
ConformPrt = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
          + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3   
% Scrap
ScrapPrt = 1 - Fb1b2b3
% Rework 
RworkPrt = Fb1b2b3 - ConformPrt


% PrtScrapProb = Fb1b2a3 + Fb1a2b3 + Fa1b2b3...
%              - Fb1a2a3 - Fa1b2a3 - Fa1a2b3...
%              + Fa1a2a3;
         
%% Markov Chain to correct conformance and scrap amounts from reworked items

m11 = 1/(1-RworkPrt)
f12 = ConformPrt/(1-RworkPrt)
f13 = ScrapPrt/(1-RworkPrt)
a_RW = 0
b_RW = 0
c_RW = 0;
%% Cost model
[Prt_Cost Prt_Rwork_Cost Prt_Scrap_Cost Prt_Total_Cost] =...
    CostModel_CMC_Example1(a_RW,b_RW,c_RW,m11,f13)