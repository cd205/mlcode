function [PIs, PCs, PSs, PRR, ptsCell] = Probs_3Var(SMat_Cell,U,L,MU,SIGMA)
% INPUTS 
%        U     - upper limits
%        L     - lower limits
%        MU    - mean vector        
%        SIGMA - sigma matrix

%% Example 
% clear all
% clc
% U = [6.2 7.1 8.4];
% L = [2.1 3.5 2.7];
% MU = [6 5.5 5];
% SIGMA = [2 0 0; 0 2.5 0; 0 0 3];

Size_SMat = size(SMat_Cell);
%%
MU_R = L+(U-MU); % reverse the axes 
sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));
sig33 = sqrt(SIGMA(3,3));

MU_R5 = [MU_R(1), MU_R(2)];
SIGMA_5 = [sig11^2 0;0 sig22^2];
MU_R6 = [MU_R(1), MU_R(3)];
SIGMA_6 = [sig11^2 0;0 sig33^2];
MU_R7 = [MU_R(2), MU_R(3)];
SIGMA_7 = [sig22^2 0;0 sig33^2];

%%
Fb1b2b3 = mvncdf([U(1),U(2),U(3)],MU_R,SIGMA);
Fa1b2b3 = mvncdf([L(1),U(2),U(3)],MU_R,SIGMA);
Fb1a2b3 = mvncdf([U(1),L(2),U(3)],MU_R,SIGMA);
Fb1b2a3 = mvncdf([U(1),U(2),L(3)],MU_R,SIGMA);
Fa1a2b3 = mvncdf([L(1),L(2),U(3)],MU_R,SIGMA);
Fa1b2a3 = mvncdf([L(1),U(2),L(3)],MU_R,SIGMA);
Fb1a2a3 = mvncdf([U(1),L(2),L(3)],MU_R,SIGMA);
Fa1a2a3 = mvncdf([L(1),L(2),L(3)],MU_R,SIGMA);

pI2 = Fa1b2b3 - Fa1a2b3 - Fa1b2a3 + Fa1a2a3; % RW 1st Var
pI3 = Fb1a2b3 - Fb1a2a3 - Fa1a2b3 + Fa1a2a3; % RW 2nd Var
pI4 = Fb1b2a3 - Fb1a2a3 - Fa1b2a3 + Fa1a2a3; % RW 3rd Var
pI5 = Fa1a2b3 - Fa1a2a3;                       % RW 1st & 2nd Var
pI6 = Fa1b2a3 - Fa1a2a3;                       % RW 1st & 3rd Var
pI7 = Fb1a2a3 - Fa1a2a3;                       % RW 2nd & 3rd Var
pI8 = Fa1a2a3;                                  % RW 1st, 2nd & 3rd Var
pIC = Fb1b2b3 - Fb1b2a3 - Fb1a2b3 - Fa1b2b3 + Fa1b2a3 + Fb1a2a3 + Fa1a2b3 - Fa1a2a3;  
pIS = 1 - Fb1b2b3;

% From reworks to other reworks or Scrap
p2S = normcdf(L(1),MU(1),sig11);
p22 = 1 - normcdf(U(1),MU(1),sig11);
p2C = 1 - p22 - p2S;
p3S = normcdf(L(2),MU(2),sig22);
p33 = 1 - normcdf(U(2),MU(2),sig22);
p3C = 1 - p33 - p3S;
p4S = normcdf(L(3),MU(3),sig33);
p44 = 1 - normcdf(U(3),MU(3),sig33);
p4C = 1 - p44 - p4S;
% p5S is a 2D scrap prob S matrix would be useful here to determine the 
% correct MUs e.g. mu1,mu2, then mu1,mu3 and mu2,mu3

F5b1b2 = mvncdf([U(1),U(2)],MU_R5,SIGMA_5);
F5a1b2 = mvncdf([L(1),U(2)],MU_R5,SIGMA_5);
F5b1a2 = mvncdf([U(1),L(2)],MU_R5,SIGMA_5);
F5a1a2 = mvncdf([L(1),L(2)],MU_R5,SIGMA_5);
p52 = F5a1b2 - F5a1a2;
p53 = F5b1a2 - F5a1a2;
p55 = F5a1a2;
p5C = F5b1b2 - F5a1b2 - F5b1a2 + F5a1a2;
p5S = 1 - F5b1b2;

F6b1b2 = mvncdf([U(1),U(3)],MU_R6,SIGMA_6);
F6a1b2 = mvncdf([L(1),U(3)],MU_R6,SIGMA_6);
F6b1a2 = mvncdf([U(1),L(3)],MU_R6,SIGMA_6);
F6a1a2 = mvncdf([L(1),L(3)],MU_R6,SIGMA_6);
p62 = F6a1b2 - F6a1a2;
p64 = F6b1a2 - F6a1a2;
p66 = F6a1a2;
p6C = F6b1b2 - F6a1b2 - F6b1a2 + F6a1a2;
p6S = 1 - F6b1b2;

F7b1b2 = mvncdf([U(2),U(3)],MU_R7,SIGMA_7);
F7a1b2 = mvncdf([L(2),U(3)],MU_R7,SIGMA_7);
F7b1a2 = mvncdf([U(2),L(3)],MU_R7,SIGMA_7);
F7a1a2 = mvncdf([L(2),L(3)],MU_R7,SIGMA_7);
p73 = F7a1b2 - F7a1a2;
p74 = F7b1a2 - F7a1a2;
p77 = F7a1a2;
p7C = F7b1b2 - F7a1b2 - F7b1a2 + F7a1a2;
p7S = 1 - F7b1b2;
 
p82 = pI2;
p83 = pI3;
p84 = pI4;
p85 = pI5;
p86 = pI6;
p87 = pI7;
p88 = pI8;
p8C = pIC;
p8S = pIS;

% Probability vectors
PIs = [pI2,pI3,pI4,pI5,pI6,pI7,pI8,pIC,pIS];
PCs = [pIC,p2C,p3C,p4C,p5C,p6C,p7C,p8C];
PSs = [pIS,p2S,p3S,p4S,p5S,p6S,p7S,p8S];
PRR = [p22,p33,p44,p55,p66,p77,p88];

% store the 'probability to' vectors.  These are the probabilitys of going
% form say state 4 to state 2 (p42) etc
ptCell = {[p22 p52 p62 p82]',[p33 p53 p73 p83]',[p44 p64 p74 p84]',...
    [p55 p85]',[p66 p86]',[p77 p87]',[p88]'};

for k = 1:Size_SMat(2)-1
    SMatLog = SMat_Cell{k};
end
size_SMatLog = size(SMatLog);

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



