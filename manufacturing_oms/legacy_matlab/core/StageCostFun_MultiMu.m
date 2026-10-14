function [F_stageC,pIC,Rwi,Sri] = StageCostFun_MultiMu(MU,sigs,rho,U,L,...
                                                       R_Cost,S_Cost)
% Computes the final probability items through a manufacturing process with 
% rework will conform. 
% Christopher Dodd - 2014 - Chris.S.Dodd@Gmail.com
% INPUTS -  MU:     A 1 by n vector of process means
%           sigs:   Correlation matrix with size n by n
%           rho:    Correlation parameter 
%           U:      A 1 by n vector of upper specification limits
%           L:      A 1 by n vector of lower specification limits
%           R_Cost: The rework costs for each rework stage
%           S_Cost: The scrap costs for each rework stage and inital stage
%
% OUTPUTS - F_stageC:   Final probability of conformance
%           pIC:        Probability of conformance from the inital
%                       operation
%           Rwi:        Vector of rework probabilities
%           Sri:        Vector of scrap probabilities

N = size(MU,2); % Total number of features at stage
eta = 1;        % Initiate eta value
for k = 1:N     % eta for given N and k 
    eta_c = factorial(N)/(factorial(k)*(factorial(N-k)));
    eta = eta + eta_c;
end
% Determine all possible permutations 
for k = 1:N
    UP{k} = combinator(N,k,'c'); % Equation 2.48 Dodd [2014]
end

% create an Upsilon vector with all the combinations 
% i.e.  [1]
%       [2]
%       [3]
%       [1 2]
%       :
%       [1 2 3]     
c = 1;
for k = 1:N
    Coms = combinator(N,k,'c');
    sizeComs = size(Coms);
    for j = 1:sizeComs(1)
        UPv{c,:} = Coms(j,:);
        c = c+1;
    end
    k=k+1;
end

%% calculate S-Matrix
beta = 0;
for k = 1:N % Generate S-matrix for each k- value
    for i = 1:k-1 % Calculate beta
        beta_c = factorial(N)/(factorial(i)*(factorial(N-i)));
        beta = beta + beta_c; 
    end
    alpha_l = 0;
    for i = N:-1:k % Calculate alpha 
        alpha_c = (factorial(N)/(factorial(i)*(factorial(N-i))));
        alpha_l = alpha_l + alpha_c; % Determine last term in alpha eqn
    end                              % alpha is k-dependent 
    alpha = 2 + (eta-1) - alpha_l;   % alpha eqn
    m = (factorial(N)/(factorial(k)*(factorial(N-k)))); % m equation
    delta = beta+m;
    SMat = kSMatrix(k,alpha,eta,m,UP,UPv); % S-Matrix function
    SMat_Cell{k} = SMat;                % Store S-Matrices in a cell array
    beta = 0; % reset beta to zero

end

%% probability vecotrs 
[PIs PSs PMat] = Probs_nVars_MultiMu(MU,L,U,sigs,rho);
%% Transition Matrix
P=PMat;
Q = P(1:eta,1:eta);     % Q Matrix (prob of transient to transient)
R = P(1:eta,eta+1:end); % R Matrix (prob of transient to absorbing)
I = eye(length(Q));     % Identiy matrix
M = (I-Q)^-1;           % average time in transient states
F = M*R;                % Final probabilities of absorbtion
temp = Q.*eye(eta,eta); PRR = temp(temp>0)'; % Determine the 
                                             % state-back-to-state rework 
                                             % vector from Q matrix

%% Scrap costs
SCP_Cost = 0; % initilize Scrap cost
for k = 1:N
    for i = 1:k-1 % Calculate beta 
        beta_c = factorial(N)/(factorial(i)*(factorial(N-i)));
        beta = beta + beta_c;
    end
    alpha_l = 0;
    for i = N:-1:k % Calculate alpha
        alpha_c = (factorial(N)/(factorial(i)*(factorial(N-i))));
        alpha_l = alpha_l + alpha_c; % Determine last term in alpha eqn
    end                              % alpha is k-dependent 
    alpha = 2 + (eta-1) - alpha_l;   % alpha eqn
    m = (factorial(N)/(factorial(k)*(factorial(N-k)))); % m equation 
    delta = beta+m;                                     % delta equation
    DMat = kDMatrix(m,PIs,alpha,delta,eta); % compute the D-matrix
   % JMat = kJMatrix(m,PIs,alpha,delta,eta)
    SDMat = SMat_Cell{k}.*DMat;
    beta = 0; % reset beta to zero
    for j = 1:m
        a = alpha + j - 2;
        % Scrap cost Equation 
        % Note for 1 state (p_Is/(1-p_Ir))*p_Ir + p_Is = p_Is/(1-p_Ir)
        % where p_Is: prob from I to scrap, p_Ir: prob from I to rework
        kSCPi = S_Cost(a+1)*sum([SDMat(:,j).*(PSs(a+1)/(1-PRR(a)))]); 
        % Scrap cost for each k
        SCP_Cost = SCP_Cost + kSCPi; % total scrap cost for all k
    end
end

%% Rework Costs
for i = 1:eta-1 % Rework cost
    rw(i) = R_Cost(i)*M(1,i+1);
end
SCPCOST = SCP_Cost;
Sri = SCP_Cost + PSs(1)*S_Cost(1);
Rwi = sum(rw);
pIC = 1-PSs(1);
F_stageC = F(1,1);
