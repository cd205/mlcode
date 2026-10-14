function [PIs PSs PMat] = Probs_nVars_MultiMu(MU,L,U,sigs,rho)
% Determine the probabilities in the transition matrix
% for any number of features. 
% Christopher Dodd - 2014 - Chris.S.Dodd@Gmail.com
% INPUTS -  MU:     A 1 by n vector of process means
%           U:      A 1 by n vector of upper specification limits
%           L:      A 1 by n vector of lower specification limits
%           sigs:   Correlation matrix with size n by n
%           rho:    Correlation parameter 
%
% OUTPUTS - PIs:    Vector of transistion probabilities, e.g for 2 
%                   features PIs = [pI2,pI3,pI4,pIC,pIS]   
%           PSs:    Vector of transition to scrap probabilities, eg for 2
%                   features PSs = [pIS,p2S,p3S,p4S]
%           PMat:   Transition matrix

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
    Rw_vars{ic,:} = combinator(num_vars,i,'c');  % e.g. x1,x2,x3 and x1,x2 
                                                 % or x1,x3 or x2,x3 etc 
end
c = 0;  % initiate 'c' counter  
cc = 0; % initiate 'cc' counter 
for j = 1:size(Rw_vars,1)

    %'----------------- Local Rw Operations -----------------'
    RwIter = Rw_vars{j};
    for k = 1:size(RwIter,1)
       %r = r+1
    %'----------------- Define Local MUs and Sigmas -----------------'
        MU_Ri = MU_R(j,RwIter(k,:));  % only selct the mean for the 
                                      % relevant features
        % Build covariance matrix for all featuers including correlation
        % (rho)
        CorrMatrix = rho.*(ones(length(MU_Ri),length(MU_Ri)));
        CorrMatrix(logical(eye(size(CorrMatrix))))=1;         
        SIGMA = corr2cov(sigs(RwIter(k,:)), CorrMatrix);      
        Lvars = L(RwIter(k,:));  % Get the right Lower and upper bounds for 
        Uvars = U(RwIter(k,:));  % the particular means.
        LocalVars = length(MU_Ri);% Length of the mean vector, for the 
                                  % relevant means
        cc = cc+1;
        % Probabilities from state to conformance
        PCs(cc) = mvncdf(Lvars,Uvars,MU_Ri,SIGMA); 
        % Probabilities from state to scrap  
        PSs(cc) = 1-mvncdf(Uvars,MU_Ri,SIGMA); 
        for m = 1:LocalVars%:-1:1
        %'----------------- Define Combins-----------------'
            nvar = nchoosek(LocalVars,m);
            combins = combinator(LocalVars,m,'c');
            for v = 1:nvar
                c = c+1; % counter i++
                % substitute -inf for relevent lower limits
                Llim = Lvars; Llim(combins(v,:)) = -inf; 
                % subsitute L for relevent upper limits
                Ulim = Uvars; Ulim(combins(v,:)) = Lvars(combins(v,:)); 
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
    % Compute the m equation (k-dependent)
    m = (factorial(num_vars)/(factorial(k)*(factorial(num_vars-k)))); 
    delta = beta+m;
    SMat = kSMatrix(k,alpha,eta,m,UP,UPv);   % S-Matrix function
    % Store S-Matrices in a cell array
    SMAT(alpha-1:eta-1,alpha-1:delta) = SMat;
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
% Conformance prob vector, e.g. 2 vars PSs = [pIC,p2C,p3C,p4C];
PCs = [PCs, PCs(1)]; 
% Scrap  vector, e.g. 2 vars PSs = [pIS,p2S,p3S,p4S];
PSs = [PSs, PSs(1)];  
PMat(1:eta,eta+1) = PCs;
PMat(1:eta,eta+2) = PSs;

%% Define PIs vector
% Define the PIs vec, e.g 2 vars PIs = [pI2,pI3,pI4,pIC,pIS];
PIs = [Pps(1:eta-1) PCs(1) PSs(1)];  
