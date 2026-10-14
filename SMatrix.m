clear all
clc

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

%PIs = [0.11803, 0.11803, 0.01393, 0.5, 0.25] % 2 var PIs
%PIs = [0.077217, 0.077217, 0.077217, 0.005962, 0.005962, 0.005962, 0.00046, 0.5, 0.25] % 3 var PIs
PIs = [12, 13, 14, 15, 16, 17, 18, 0.5, 0.25] % 3 var PIs
%PIs = [12, 13, 14, 15, 16, 17, 18, 19, 110, 111, 112, 113, 114, 115, 116, 0.5, 0.25]

beta = 0;
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
    SMat = kSMatrix(k,alpha,eta,m,UP,UPv) % S-Matrix function
    DMat = kDMatrix(m,PIs,alpha,delta,eta)
    beta = 0; % reset beta to zero
end


%%



