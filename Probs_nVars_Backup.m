% use Nelsen method to determine the probabilities in the transition matrix
% for any number of features.  Note function for 1 2 and 3 features are
% given in:
% C:\RectangularProbabilities\Amir_CutMeasureCut\CMC Case Study Examples\MarkovCostofProduction
% the functions are 'Probs_2Var' and 'Probs_3Var'

clear all
close all
clc

rho = 0.2;

% MU = [5 5.2]
% U = [6.1 6.2]; L = [3 3.1];
% sigs = [1.4 1.9];
% SIGMA = [sigs(1)^2, rho*sigs(1)*sigs(2); rho*sigs(2)*sigs(1), sigs(2)^2];

MU = [5 5.2 4.8]
U = [6.1 6.2 6.3]; L = [3.1 3.2 3.3]
sigs = [1.2 1.5 1.8]; 
SIGMA = [sigs(1)^2 rho*sigs(1)*sigs(2) rho*sigs(1)*sigs(3);...
         rho*sigs(2)*sigs(1) sigs(2)^2 rho*sigs(2)*sigs(3);...
         rho*sigs(3)*sigs(1) rho*sigs(3)*sigs(2) sigs(3)^2];

MU_R = L+(U-MU); % reverse the axes 

num_vars = length(MU) % Number of variables 

for i = 1:num_vars
    eta_vec(i) = nchoosek(num_vars,i);
end
eta = sum(eta_vec)

pIC = mvncdf(L,U,MU_R,SIGMA)
pIS = 1-mvncdf(U,MU_R,SIGMA)
%% ---------- PIs probs  ---------- 
% This section determines the probabilities of the rework regions 
% e.g. in 3D:
%       pI2 = F([-inf L2 L3],[L1 U2 U3])      x_1 rework only 
%       pI3 = F([L1 -inf L3],[U1 L2 U3])      x_2 rework only 
%       pI4 = F([L1 L2 -inf],[U1 U2 L3])      x_3 rework only 
%       pI5 = F([-inf -inf L3],[L1 L2 U3])    x_1 & x_2 rework
%       pI6 = F([-inf L2 -inf],[L1 U2 L3])    x_1 & x_3 rework  
%       pI7 = F([L1 -inf -inf],[U1 L2 L3])    x_2 & x_3 rework
%       pI8 = F([-inf -inf -inf],[L1 L2 L3])  x_1, x_2 & x_3 rework
% these probabilities are complied in the pRWs vector
PIs = ones(1,eta+2);
c = 0; % counter
% 

%    %     for i = 1:num_vars
%             nvar = nchoosek(num_vars,i);
%             combins = combinator(num_vars,i,'c');
%  %           for j = 1:nvar
%                 c = c+1; % counter c++
%                 Llim = L; Llim(combins(j,:)) = -inf;  % substitute -inf for relevent lower limits
%                 Ulim = U; Ulim(combins(j,:)) = L(combins(j,:)); % subsitute L for relevent upper limits
%                 pRWs(c) = mvncdf(Llim,Ulim,MU_Ri,SIGMA);
%          
%     end
% end

% 'k' starts from the higest number of variables as the first operation is
% actually the processing of all features befroe rework occur on only some
% of the featuers
ic = 0
for i = num_vars:-1:2                     % determine all possilbe combinations of reworks
    ic = ic+1; % counter to define rows of pRWs
    disp(['-----------------START all possilbe RW combos ' num2str(i),'-----------------']);
    Rw_vars = combinator(num_vars,i,'c')  % e.g. x1,x2,x3 and x1,x2 or x1,x3 or x2,x3 etc 
    for j = 1:size(Rw_vars,1)
        '----------------- Define correct MUs and Sigmas -----------------'
        MU_Ri = MU_R(Rw_vars(j,:))        % only selct the mean for the relevant features
     %   Llim = L(Rw_vars(j,:)) 
     %  Ulim = U(Rw_vars(j,:)) 
        CorrMatrix = rho.*(ones(length(MU_Ri),length(MU_Ri)));% Build covariance matrix for 
        CorrMatrix(logical(eye(size(CorrMatrix))))=1;         % however many featuers there are
        SIGMA = corr2cov(sigs(Rw_vars(j,:)), CorrMatrix)     % including correlation (rho)
        for k = length(MU_Ri):-1:1
            '----------------- Length of MU_Ri - define Combins-----------------'
            k
            nvar = nchoosek(num_vars,k)
            combins = combinator(num_vars,k,'c')
           for l = 1:nvar
                '----------------- Build Limits -----------------'
               l
               c = c+1; % counter c++
               Llim = L;
               Ulim = U;
               if length(MU_Ri) < num_vars
                   LlimTemp = L(Rw_Vars(j,:)); UlimTemp = U(Rw_Vars(j,:));
                   Llim = NaN(1,length(MU_Ri)); Ulim = NaN(1,length(MU_Ri));
                   for m = 1:length(MU_Ri,2)
                       m
                       LlimTemp(combins(l,m)) = -inf
                       Llim(m) = -inf%LlimTemp(combins(l,m)) % ensure that the limits have correct number
                       Ulim(m) = L(combins(l,m)) % of elements, should be same as MU_Ri
                   end
               else 
                   Llim(combins(l,:)) = -inf  % substitute -inf for relevent lower limits
                   Ulim(combins(l,:)) = L(combins(l,:)) % subsitute L for relevent upper limits
               end

               pRWs(ic,c) = mvncdf(Llim,Ulim,MU_Ri,SIGMA)
           end
        end
         
    end
end

% PIs(1:eta) = pRWs; PIs(eta+1:end) = [pIC, pIS];
% PIs = PIs
% %% ----------  PCs, PSs and  PRR probs  ---------- 
% PCs = ones(1,eta+1);          % Preallocate the PCs vector (Prob of state to conformance)
% PCs(1) = pIC; PCs(end) = pIC; % The 1st PCs (prob from initial state to conformance
%                               % is pIC, the last PCs is the same as inital
%                               % process (i.e. it has smae featuers as
%                               % inital operation even though it is a rework
%                               % operation
% PSs = ones(1,eta+1);          % Preallocate the PSs vector (Prob of state to scrap)
% PSs(1) = pIS; PSs(end) = pIS; % Allocate the 1st and last terms of PSs vector
% PRR = ones(1,eta);            % Preallocate the PRR vector (Prob of state to rework in that state)
% PRR(end) = PIs(eta);
% % In the 'for loop':
% % Input the PRR vector (probability of Rw into themsleves),
% % the PCs vector (Prob of state to conformance
% % the PSs vecotr (Prob of state to Scrap)
% for i = 1:num_vars
%     PRR(i) = 1 - normcdf(U(i),MU(i),sigs(i));  % Not MU_R here as its just the single variable
%     PCs(i+1) =  normcdf(U(i),MU(i),sigs(i)) - normcdf(L(i),MU(i),sigs(i));
%     PSs(i+1) = normcdf(L(i),MU(i),sigs(i));
% end
% 
% PCs = PCs
% PRR = PRR
% PSs = PSs
% 
% % %% 2 variable check 
% % MU_R = L+(U-MU); % reverse the axes 
% % sig11 = sqrt(SIGMA(1));
% % sig22 = sqrt(SIGMA(2,2));
% % 
% % Fb1b2 = mvncdf([U(1),U(2)],MU_R,SIGMA);
% % Fa1b2 = mvncdf([L(1),U(2)],MU_R,SIGMA);
% % Fb1a2 = mvncdf([U(1),L(2)],MU_R,SIGMA);
% % Fa1a2 = mvncdf([L(1),L(2)],MU_R,SIGMA);
% % 
% % pI2a = Fa1b2 - Fa1a2;
% % pI3a = Fb1a2 - Fa1a2;
% % pI4a = Fa1a2;
% % pICa = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
% % pISa = 1 - Fb1b2;
% % 
% % 
% % p22a = 1 - normcdf(U(1),MU(1),sig11);
% % p2Ca = normcdf(U(1),MU(1),sig11) - normcdf(L(1),MU(1),sig11); % not used
% % p2Sa = normcdf(L(1),MU(1),sig11);
% % p33a = 1 - normcdf(U(2),MU(2),sig22);
% % p3Ca = normcdf(U(2),MU(2),sig22) - normcdf(L(2),MU(2),sig22); % not used
% % p3Sa = normcdf(L(2),MU(2),sig22);
% % 
% % p42a = pI2a; 
% % p43a = pI3a; 
% % p44a = pI4a;
% % p4Ca = pICa; 
% % p4Sa = pISa;
% % p5Ca = 1; 
% % p5Sa = 0; 
% % 
% % PIs2 = [pI2a,pI3a,pI4a,pICa,pISa]
% % PCs2 = [pICa,p2Ca,p3Ca,p4Ca]
% % PSs2 = [pISa,p2Sa,p3Sa,p4Sa]
% % PRR2 = [p22a,p33a,p44a]
% 
% 
% % 
% %% 3 variable check 
% MU_R = L+(U-MU); % reverse the axes 
% sig11 = sigs(1);
% sig22 = sigs(2);
% sig33 = sigs(3);
% 
% MU_R5 = [MU_R(1), MU_R(2)];
% SIGMA_5 = [sig11^2 0;0 sig22^2];
% MU_R6 = [MU_R(1), MU_R(3)];
% SIGMA_6 = [sig11^2 0;0 sig33^2];
% MU_R7 = [MU_R(2), MU_R(3)];
% SIGMA_7 = [sig22^2 0;0 sig33^2];
% 
% %%
% Fb1b2b3 = mvncdf([U(1),U(2),U(3)],MU_R,SIGMA);
% Fa1b2b3 = mvncdf([L(1),U(2),U(3)],MU_R,SIGMA);
% Fb1a2b3 = mvncdf([U(1),L(2),U(3)],MU_R,SIGMA);
% Fb1b2a3 = mvncdf([U(1),U(2),L(3)],MU_R,SIGMA);
% Fa1a2b3 = mvncdf([L(1),L(2),U(3)],MU_R,SIGMA);
% Fa1b2a3 = mvncdf([L(1),U(2),L(3)],MU_R,SIGMA);
% Fb1a2a3 = mvncdf([U(1),L(2),L(3)],MU_R,SIGMA);
% Fa1a2a3 = mvncdf([L(1),L(2),L(3)],MU_R,SIGMA);
% 
% pI2 = Fa1b2b3 - Fa1a2b3 - Fa1b2a3 + Fa1a2a3; % RW 1st Var
% pI3 = Fb1a2b3 - Fb1a2a3 - Fa1a2b3 + Fa1a2a3; % RW 2nd Var
% pI4 = Fb1b2a3 - Fb1a2a3 - Fa1b2a3 + Fa1a2a3; % RW 3rd Var
% pI5 = Fa1a2b3 - Fa1a2a3;                       % RW 1st & 2nd Var
% pI6 = Fa1b2a3 - Fa1a2a3;                       % RW 1st & 3rd Var
% pI7 = Fb1a2a3 - Fa1a2a3;                       % RW 2nd & 3rd Var
% pI8 = Fa1a2a3;                                  % RW 1st, 2nd & 3rd Var
% pIC = Fb1b2b3 - Fb1b2a3 - Fb1a2b3 - Fa1b2b3 + Fa1b2a3 + Fb1a2a3 + Fa1a2b3 - Fa1a2a3;  
% pIS = 1 - Fb1b2b3;
% 
% % From reworks to other reworks or Scrap
% p2S = normcdf(L(1),MU(1),sig11);
% p22 = 1 - normcdf(U(1),MU(1),sig11)
% p2C = 1 - p22 - p2S;
% p3S = normcdf(L(2),MU(2),sig22);
% p33 = 1 - normcdf(U(2),MU(2),sig22);
% p3C = 1 - p33 - p3S;
% p4S = normcdf(L(3),MU(3),sig33);
% p44 = 1 - normcdf(U(3),MU(3),sig33);
% p4C = 1 - p44 - p4S;
% % p5S is a 2D scrap prob S matrix would be useful here to determine the 
% % correct MUs e.g. mu1,mu2, then mu1,mu3 and mu2,mu3
% 
% F5b1b2 = mvncdf([U(1),U(2)],MU_R5,SIGMA_5);
% F5a1b2 = mvncdf([L(1),U(2)],MU_R5,SIGMA_5);
% F5b1a2 = mvncdf([U(1),L(2)],MU_R5,SIGMA_5);
% F5a1a2 = mvncdf([L(1),L(2)],MU_R5,SIGMA_5);
% p52 = F5a1b2 - F5a1a2;
% p53 = F5b1a2 - F5a1a2;
% p55 = F5a1a2;
% p5C = F5b1b2 - F5a1b2 - F5b1a2 + F5a1a2;
% p5S = 1 - F5b1b2;
% 
% F6b1b2 = mvncdf([U(1),U(3)],MU_R6,SIGMA_6);
% F6a1b2 = mvncdf([L(1),U(3)],MU_R6,SIGMA_6);
% F6b1a2 = mvncdf([U(1),L(3)],MU_R6,SIGMA_6);
% F6a1a2 = mvncdf([L(1),L(3)],MU_R6,SIGMA_6);
% p62 = F6a1b2 - F6a1a2;
% p64 = F6b1a2 - F6a1a2;
% p66 = F6a1a2;
% p6C = F6b1b2 - F6a1b2 - F6b1a2 + F6a1a2;
% p6S = 1 - F6b1b2;
% 
% F7b1b2 = mvncdf([U(2),U(3)],MU_R7,SIGMA_7);
% F7a1b2 = mvncdf([L(2),U(3)],MU_R7,SIGMA_7);
% F7b1a2 = mvncdf([U(2),L(3)],MU_R7,SIGMA_7);
% F7a1a2 = mvncdf([L(2),L(3)],MU_R7,SIGMA_7);
% p73 = F7a1b2 - F7a1a2;
% p74 = F7b1a2 - F7a1a2;
% p77 = F7a1a2;
% p7C = F7b1b2 - F7a1b2 - F7b1a2 + F7a1a2;
% p7S = 1 - F7b1b2;
%  
% p82 = pI2;
% p83 = pI3;
% p84 = pI4;
% p85 = pI5;
% p86 = pI6;
% p87 = pI7;
% p88 = pI8;
% p8C = pIC;
% p8S = pIS;
% 
% % Probability vectors
% PIsa = [pI2,pI3,pI4,pI5,pI6,pI7,pI8,pIC,pIS]
% PCsa = [pIC,p2C,p3C,p4C,p5C,p6C,p7C,p8C]
% PSsa = [pIS,p2S,p3S,p4S,p5S,p6S,p7S,p8S]
% PRRa = [p22,p33,p44,p55,p66,p77,p88]
% 
