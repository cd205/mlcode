function [Profit,TC,S] = MinCMCFun_3var(MU3,MU2,MU1,U,L,SIGMA)
% call the MinCMCFun_3var function


% Example inputs 
% U = [5.5 5.5 5.5];
% L = [4.5 4.5 4.5];
% MU3 = [5 5 5];
% MU2 = [5.3 5.3 5.3]; 
% MU1 = [5.5 5.5 5.5];
% SIGMA = [1 0 0; 0 1 0; 0 0 1];


%% 2 variables using the Dodd [2014] method
SP = 600; PC = 75; 
N = 3; % Total number of features at stage
eta = 1;
for k = 1:N
    eta_c = factorial(N)/(factorial(k)*(factorial(N-k)));
    eta = eta + eta_c;
end
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

% calculate S-Matrix
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

[PIs, PCs, PSs, PRR, ptsCell] = Probs_3Var_MuMod(SMat_Cell,U,L,MU3,MU2,MU1,SIGMA);

R_Cost =  [25 25 25 50 50 50 75];

% Transition Matrix
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
M = (I-Q)^-1;           % M-matrix of average time in rework
F = M*R;                % F matrix of final probabilities

%% Rework Costs
for i = 1:eta-1
    rw(i) = R_Cost(i)*M(1,i+1);
end
% Scrap cost is based on on number of reworks.  therefore is a components
% is reworked many times value is added for each iteration
S_Cost = [175 175 175 175 175 175 175 175];
%S_Cost = [100, 100+25*(1+M(1,2)), 100+25*(1+M(1,3)), 100+25*(1+M(1,4)),...
%    100+50*(1+M(1,5)), 100+50*(1+M(1,6)), 100+50*(1+M(1,7)), 100+75*(1+M(1,8))];
% Scrap costs
SCP_Cost = 0; % initilize Scrap cost
c=1;
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
        a = alpha + j -2;
        % Scrap cost eqn (Eqn 22 in MarkovChainPaper Dodd 2014)
        % SDMat = SDMat_Cell{k};
        kSCPi = S_Cost(a+1)*sum([SDMat(:,j).*(PSs(a+1)/(1-PRR(a)))]);
        ScrapCostPerState(c) = kSCPi;
        c = c+1;
        SCP_Cost = SCP_Cost + kSCPi;
    end
end


ScrapCostPerState;
Sri = SCP_Cost + PSs(1)*S_Cost(1);
Rwi = sum(rw);
TC = Sri+Rwi;
Profit = SP*F(1,1) - PC - TC;
S = struct('Profit',Profit,'TotalCost',TC,'Scrap',Sri,'Rwork',Rwi,...
           'Sc1',PSs(1)*S_Cost(1),'Sc2',ScrapCostPerState(1),...
           'Sc3',ScrapCostPerState(2),'Sc4',ScrapCostPerState(3),...
           'Sc5',ScrapCostPerState(4),'Sc6',ScrapCostPerState(5),...
           'Sc7',ScrapCostPerState(6),'Sc8',ScrapCostPerState(7),...
           'Rw1',rw(1),'Rw2',rw(2),'Rw3',rw(3),'Rw4',rw(4),'Rw5',rw(5),...
           'Rw6',rw(6),'Rw7',rw(7));

