function [F_stageC,pIC,Rwi,Sri] = StageCostFun(MU,SIGMA,U,L,R_Cost,S_Cost)
N = length(MU); % Total number of features at stage
eta = 1;
for k = 1:N
    eta_c = factorial(N)/(factorial(k)*(factorial(N-k)));
    eta = eta + eta_c;
end
eta;
for k = 1:N
    UP{k} = combinator(N,k,'c');
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
%SCP_Cost = 0; % initilize Scrap cost
for k = 1:N % Generate S-matrix for each k- value
    for i = 1:k-1
        beta_c = factorial(N)/(factorial(i)*(factorial(N-i)));
        beta = beta + beta_c;
    end
    alpha_l = 0;
    for i = N:-1:k
        alpha_c = (factorial(N)/(factorial(i)*(factorial(N-i))));
        alpha_l = alpha_l + alpha_c; % Determine last term in alpha eqn
    end                              % alpha is k-dependent 
    alpha = 2 + (eta-1) - alpha_l;   % alpha eqn
    m = (factorial(N)/(factorial(k)*(factorial(N-k)))); % m equation (k-dependent)
    delta = beta+m;
    SMat = kSMatrix(k,alpha,eta,m,UP,UPv);   % S-Matrix function
    SMat_Cell{k} = SMat;                     % Store S-Matrices in a cell array
    beta = 0; % reset beta to zero

end

%% probability vecotrs 
% 1 var
if N == 1
  [PIs, PCs, PSs, PRR, ptsCell] = Probs_1Var(SMat_Cell,U,L,MU,SIGMA);
end
%% 2 Var
if N == 2
    [PIs, PCs, PSs, PRR, ptsCell] = Probs_2Var(SMat_Cell,U,L,MU,SIGMA);
elseif N==3
%% 3 Var
    [PIs, PCs, PSs, PRR, ptsCell] = Probs_3Var(SMat_Cell,U,L,MU,SIGMA);
end

%% Scrap costs
SCP_Cost = 0; % initilize Scrap cost
for k = 1:N
    for i = 1:k-1
        beta_c = factorial(N)/(factorial(i)*(factorial(N-i)));
        beta = beta + beta_c;
    end
    alpha_l = 0;
    for i = N:-1:k
        alpha_c = (factorial(N)/(factorial(i)*(factorial(N-i))));
        alpha_l = alpha_l + alpha_c; % Determine last term in alpha eqn
    end                              % alpha is k-dependent 
    alpha = 2 + (eta-1) - alpha_l;   % alpha eqn
    m = (factorial(N)/(factorial(k)*(factorial(N-k)))); % m equation (k-dependent)
    delta = beta+m;
    DMat = kDMatrix(m,PIs,alpha,delta,eta); % compute the D-matrix
   % JMat = kJMatrix(m,PIs,alpha,delta,eta)
    SDMat = SMat_Cell{k}.*DMat;
    beta = 0; % reset beta to zero
    for j = 1:m
        a = alpha + j - 2;
        % Scrap cost eqn (Eqn 22 in MarkovChainPaper Dodd 2014)
        % Note for 1 state (p_Is/(1-p_Ir))*p_Ir + p_Is = p_Is/(1-p_Ir)
        % where p_Is: prob from I to scrap, p_Ir: prob from I to rework
        kSCPi = S_Cost(a+1)*sum([SDMat(:,j).*(PSs(a+1)/(1-PRR(a)))]); 
        SCP_Cost = SCP_Cost + kSCPi;
    end
end

%% Transition Matrix
P = zeros(eta+2,eta+2);  % initialise P-matrix with zeros
% Populate P-matrix borders (top row, C and S columns, ones and zeros) 
P(1,2:eta+2) = PIs; P(1:eta,eta+1) = PCs; P(1:eta,eta+2) = PSs;
P(eta+1,eta+1) = 1; P(eta+2,eta+2) = 1;

size_ptsCell  = size(ptsCell); % determine number of s matricies
r = 2; c = 2;   % inital starting ponts for k^GAMMA in tranistion matrix
                % eqn 23 in MarkovChainPaper
for i = 1:size_ptsCell(2)
    Size_kSMat = size(ptsCell{i});
    P(eta-Size_kSMat(1)+1:eta,c:c+Size_kSMat(2)-1) = ptsCell{i};
    c = c+Size_kSMat(2);
end

Q = P(1:eta,1:eta);
R = P(1:eta,eta+1:end);
I = eye(length(Q));
M = inv((I-Q));%^-1;
F = M*R;

%% Rework Costs
for i = 1:eta-1
    rw(i) = R_Cost(i)*M(1,i+1);
end
SCPCOST = SCP_Cost;
Sri = SCP_Cost + PSs(1)*S_Cost(1);
Rwi = sum(rw);
pIC = PCs(1);
F_stageC = F(1,1);
