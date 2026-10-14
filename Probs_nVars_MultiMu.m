function [PIs PSs PMat] = Probs_nVars_MultiMu(MU,L,U,sigs,rho)

% use Nelsen method to determine the probabilities in the transition matrix
% for any number of features.  Note function for 1 2 and 3 features are
% given in:
% C:\RectangularProbabilities\Amir_CutMeasureCut\CMC Case Study Examples\MarkovCostofProduction
% the functions are 'Probs_2Var' and 'Probs_3Var'

% clear all
% close all
% clc

%rho = 0.0;
%% EXAMPLEES 
%    2 features
%     MU = [5 5; 6.1224 6.64654]
%     U = [6 6]; L = [4 4];
%     sigs = [1.4 1.9]; rho = 0;
%     SIGMA = [sigs(1)^2, rho*sigs(1)*sigs(2); rho*sigs(2)*sigs(1), sigs(2)^2];


%   3 features
%   MU = [5.1 5.2 5.3]
%   U = [6.1 6.2 6.3]; L = [3.1 3.2 3.3]
%   sigs = [1.2 1.5 1.8]; 
%   SIGMA = [sigs(1)^2 rho*sigs(1)*sigs(2) rho*sigs(1)*sigs(3);...
%           rho*sigs(2)*sigs(1) sigs(2)^2 rho*sigs(2)*sigs(3);...
%           rho*sigs(3)*sigs(1) rho*sigs(3)*sigs(2) sigs(3)^2];

%   4 features
%   MU = [5.1 5.2 5.3 5.4]
%   U = [6.1 6.2 6.3 6.4]; L = [3.1 3.2 3.3 3.4]
%   sigs = [1.2 1.5 1.8 2.1]; 


num_vars = size(MU,2); % Number of variables
%% Determine the Multi feature means through to single feature means
% e.g. 2 features MU = [mu1_2f, mu2_2f;
%                       mu1_1f, mu2_1f] where f:=feature

for i=1:size(MU,1)
    MU_R(i,:) = L+(U-MU(i,:)); % reverse the axes 
end
 
eta = 1;
for i = 1:num_vars
    eta_c = factorial(num_vars)/(factorial(i)*(factorial(num_vars-i)));
    eta = eta + eta_c;
end
eta;


%pIC = mvncdf(L,U,MU_R,SIGMA)
%pIS = 1-mvncdf(U,MU_R,SIGMA)
%% ---------- Pps probs  ---------- 
% This section determines the probabilities of the rework regions 
% e.g. in 3D:
%       pI2 = F([-inf L2 L3],[L1 U2 U3])      x_1 rework only 
%       pI3 = F([L1 -inf L3],[U1 L2 U3])      x_2 rework only 
%       pI4 = F([L1 L2 -inf],[U1 U2 L3])      x_3 rework only 
%       pI5 = F([-inf -inf L3],[L1 L2 U3])    x_1 & x_2 rework
%       pI6 = F([-inf L2 -inf],[L1 U2 L3])    x_1 & x_3 rework  
%       pI7 = F([L1 -inf -inf],[U1 L2 L3])    x_2 & x_3 rework
%       pI8 = F([-inf -inf -inf],[L1 L2 L3])  x_1, x_2 & x_3 rework


ic = 1;  % initiate 'ic' counter
Rw_vars{1,:} = combinator(num_vars,num_vars,'c');
for i = 1:num_vars-1    % determine all possilbe combinations of reworks
    ic = ic+1; % counter to define rows of pRWs
    %'----------------- All possilbe RW combos-----------------'
    Rw_vars{ic,:} = combinator(num_vars,i,'c');  % e.g. x1,x2,x3 and x1,x2 or x1,x3 or x2,x3 etc 
end
c = 0;  % initiate 'c' counter  
cc = 0; % initiate 'cc' counter 
for j = 1:size(Rw_vars,1)

    %'----------------- Local Rw Operations -----------------'
    RwIter = Rw_vars{j};
    for k = 1:size(RwIter,1)
       %r = r+1
    %'----------------- Define Local MUs and Sigmas -----------------'
        MU_Ri = MU_R(j,RwIter(k,:));       % only selct the mean for the relevant features
        %   Llim = L(Rw_vars(j,:))
        %  Ulim = U(Rw_vars(j,:))
        
        CorrMatrix = rho.*(ones(length(MU_Ri),length(MU_Ri)));% Build covariance matrix for
        CorrMatrix(logical(eye(size(CorrMatrix))))=1;         % all featuers 
        SIGMA = corr2cov(sigs(RwIter(k,:)), CorrMatrix);      % including correlation (rho)
        Lvars = L(RwIter(k,:));  % Get the right Lower and upper bounds for 
        Uvars = U(RwIter(k,:));  % the particular means.
        LocalVars = length(MU_Ri);% Length of the mean vector, for the relevant means
        cc = cc+1;
        PCs(cc) = mvncdf(Lvars,Uvars,MU_Ri,SIGMA);  % Probabilities from state to conformance  
        PSs(cc) = 1-mvncdf(Uvars,MU_Ri,SIGMA); % Probabilities from state to scrap  
        for m = 1:LocalVars%:-1:1
        %'----------------- Define Combins-----------------'
            nvar = nchoosek(LocalVars,m);
            combins = combinator(LocalVars,m,'c');
            for v = 1:nvar
                c = c+1; % counter i++
                Llim = Lvars; Llim(combins(v,:)) = -inf; % substitute -inf for relevent lower limits
                Ulim = Uvars; Ulim(combins(v,:)) = Lvars(combins(v,:)); % subsitute L for relevent upper limits
                Pps(c) = mvncdf(Llim,Ulim,MU_Ri,SIGMA); % these are all the
                % probability terms in the P-Matrix but just a long vector
                % not in the correct places
            end
        end 
    end
end


%% calculate S-Matrix
SMAT = zeros(eta-1,eta-1);
for k = 1:num_vars
    UP{k} = combinator(num_vars,k,'c');
end
% create an Upsilon vector with all the combinations 
% i.e.  [1]
%       [2]
%       [3]
%       [1 2]
%       :
%       [1 2 3]     
c = 1;
for k = 1:num_vars
    Coms = combinator(num_vars,k,'c');
    sizeComs = size(Coms);
    for j = 1:sizeComs(1)
        UPv{c,:} = Coms(j,:);
        c = c+1;
    end
    k=k+1;
end
beta = 0;
%SCP_Cost = 0; % initilize Scrap cost

for k = 1:num_vars % Generate S-matrix for each k- value
    for i = 1:k-1
        beta_c = factorial(num_vars)/(factorial(i)*(factorial(num_vars-i)));
        beta = beta + beta_c;
    end
    alpha_l = 0;
    for i = num_vars:-1:k
        alpha_c = (factorial(num_vars)/(factorial(i)*(factorial(num_vars-i))));
        alpha_l = alpha_l + alpha_c; % Determine last term in alpha eqn
    end                              % alpha is k-dependent 
    alpha = 2 + (eta-1) - alpha_l;   % alpha eqn
    m = (factorial(num_vars)/(factorial(k)*(factorial(num_vars-k)))); % m equation (k-dependent)
    delta = beta+m;
    SMat = kSMatrix(k,alpha,eta,m,UP,UPv);   % S-Matrix function
    SMAT(alpha-1:eta-1,alpha-1:delta) = SMat;                     % Store S-Matrices in a cell array
    beta = 0; % reset beta to zero

end


%% Compute the tranistion (Pmatrix)
[col row] = find(SMAT(1:eta-2,:)'==1);

PMat = zeros(eta+2,eta+2);
for i = 1:length(row)
    PMat(row(i)+1,col(i)+1) = Pps(eta-1+i);
end

PMat(1,2:eta) = Pps(1:eta-1);  %input the values for the first row
PMat(eta,2:eta) = Pps(1:eta-1); % input the values for the eta row
PMat(end,end) = 1; PMat(end-1,end-1) = 1; % Input 1s for absorbing states 

%% Now we need the Probs to conformance and probs to scrap
PCs = [PCs, PCs(1)];  % Conformance prob  vector, e.g. 2 vars PSs = [pIC,p2C,p3C,p4C];
PSs = [PSs, PSs(1)];  % Scrap  vector, e.g. 2 vars PSs = [pIS,p2S,p3S,p4S];
PMat(1:eta,eta+1) = PCs;
PMat(1:eta,eta+2) = PSs;

%% Define PIs vector
PIs = [Pps(1:eta-1) PCs(1) PSs(1)];  % Define the PIs vec, e.g 2 vars PIs = [pI2,pI3,pI4,pIC,pIS];
