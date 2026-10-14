function [PIs, PCs, PSs, PRR, ptsCell] = Probs_2Var(SMat_Cell,U,L,MU,SIGMA)
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
sig22 = sqrt(SIGMA(2,2));

Fb1b2 = mvncdf([U(1),U(2)],MU_R,SIGMA);
Fa1b2 = mvncdf([L(1),U(2)],MU_R,SIGMA);
Fb1a2 = mvncdf([U(1),L(2)],MU_R,SIGMA);
Fa1a2 = mvncdf([L(1),L(2)],MU_R,SIGMA);

pI2 = Fa1b2 - Fa1a2;
pI3 = Fb1a2 - Fa1a2;
pI4 = Fa1a2;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pIS = 1 - Fb1b2;


p22 = 1 - normcdf(U(1),MU(1),sig11);
p2C = normcdf(U(1),MU(1),sig11) - normcdf(L(1),MU(1),sig11); % not used
p2S = normcdf(L(1),MU(1),sig11);
p33 = 1 - normcdf(U(2),MU(2),sig22);
p3C = normcdf(U(2),MU(2),sig22) - normcdf(L(2),MU(2),sig22); % not used
p3S = normcdf(L(2),MU(2),sig22);

p42 = pI2; 
p43 = pI3; 
p44 = pI4;
p4C = pIC; 
p4S = pIS;
p5C = 1; 
p5S = 0; 

PIs = [pI2,pI3,pI4,pIC,pIS];
PCs = [pIC,p2C,p3C,p4C];
PSs = [pIS,p2S,p3S,p4S];
PRR = [p22,p33,p44];

% store the 'probability to' vectors.  These are the probabilitys of going
% form say state 4 to state 2 (p42) etc
ptCell = {[p22 p42]',[p33 p43]',[p44]'};

c = 1;
for k = 1:Size_SMat(2) % k goes from 1 to the number os S-matrices (2 for a 2 var case)
    SMatLog = SMat_Cell{k}; % Get the S-matrix for the given k value from the cell array
    size_SMatLog = size(SMatLog); % size of this S-Matrix
    % Calculate the GAMMA matrix
    for i = 1:size_SMatLog(2)      % number of columns in the S-Matrix (for a given k-value)
        r = 1;                     % row counter for 'pt' vector
        for j = 1:size_SMatLog(1)  % number of rows in the S-Matrix (for a given k-value)
            L = SMatLog(j,i);      % go down rows then columns
            if L == 1              % check if its a one or zero
                pt = ptCell{c};    % access relevent 'probability to' (pt) vector
                pts(j,i) = pt(r);  % entry into pts. NOTE: there will be 
                r = r + 1;         % zeros in this matrix if there are in the S-Matrix    
            elseif L == 0
                pts(j,i) = 0;      % enter zero if one is present in S-Matrix
            end
        end
        c = c + 1;                 % column counter for ptCell
    end
    ptsCell{k} = pts;              % put in Cell as pts vecotrs are different sizes
    clear pts; 
end 

% m12 = p12/((1-p22)*(1-p44));
% m13 = p13/((1-p33)*(1-p44));
% m14 = p14/(1-p44);
