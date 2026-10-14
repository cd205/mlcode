function [PIs, PCs, PSs, PRR, ptsCell] = Probs_1Var(SMat_Cell,U,L,MU,SIGMA)
% INPUTS 
%        U     - upper limits
%        L     - lower limits
%        MU    - mean vector        
%        SIGMA - sigma matrix
% EXAMPLE
% clear all
% clc
% U = [6.5 8.1]
% L = [4.5 2.4]
% MU = [4.5 6.8]
% SIGMA = [2.5,0;0,1.9]

Size_SMat = size(SMat_Cell);

MU_R = L+(U-MU); % reverse the axes 
sig11 = sqrt(SIGMA(1));


pI2 = 1 - normcdf(U(1),MU(1),sig11);
pIS = normcdf(L(1),MU(1),sig11);
pIC = 1 - pI2 - pIS;

% look ant figure 4 in Markov chain paper and equation 27
PIs = [pI2,pIC,pIS];   % from inital to rework, scrap and conformance
PCs = [pIC,pIC];       % conformance probabilties. Note from 2nd stage (rework) is same a intial to conformance
PSs = [pIS,pIS];       % scrap probabilties. Note from 2nd stage (rework) is same a intial to scrap
PRR = [pI2];           % Rework to rework probabilities 

% store the 'probability to' vectors.  These are the probabilitys of going
% form say state 2 to state 2 (p22) 
pts = [pI2];
ptsCell = {pts};
