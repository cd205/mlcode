clear global
clear all
close all
clc
global ModelInfo
% k = 2
% n = 35
% % Create sampling plan
% ModelInfo.X=bestlh(n,k,10,10);
% % Calculate observed data
% for i=1:n
% ModelInfo.y(i,1)=branin(ModelInfo.X(i,:));
% end
% count = 1;
% EIOpt = 0;
%while EIOpt<5
    
[alpha, beta, gamma, L_D, M0_5, M2_5, AR ] = textread('DoEData.txt', ...
'%f %f %f %f %f %f %f' );
% Normalise inputs 
alpha_n = (alpha-min(alpha))./(max(alpha) - min(alpha));
beta_n = (beta-min(beta))./(max(beta) - min(beta));
gamma_n = (gamma-min(gamma))./(max(gamma) - min(gamma));
L_D_n = (L_D-min(L_D))./(max(L_D) - min(L_D));
ModelInfo.X = [alpha_n beta_n gamma_n L_D_n ];
ModelInfo.y = [M2_5];
k = 4                        % number of variables point
n = size(ModelInfo.X,1) % number of sample point


% Set upper and lower bounds for search of log theta
UpperTheta=ones(1,k).*3;
LowerTheta=ones(1,k).*-3;
% Run GA search of likelihood
[ModelInfo.Theta,MinNegLnLikelihood]=...
ga(@likelihood,k,[],[],[],[],LowerTheta,UpperTheta);
% Put Cholesky factorization of Psi, and theta into ModelInfo
[NegLnLike,ModelInfo.Psi,ModelInfo.U]=likelihood(ModelInfo.Theta);




ModelInfo.Option='Pred';
predfun = @(X) -1*predictor(X)

[OptVar_n,OptPred]=ga(predfun,k,[],[],[],[],zeros(k,1),ones(k,1));
OptVar(1) = OptVar_n(1)*(max(alpha) - min(alpha)) + min(alpha);
OptVar(2) = OptVar_n(2)*(max(beta) - min(beta)) + min(beta);
OptVar(3) = OptVar_n(3)*(max(gamma) - min(gamma)) + min(gamma);
OptVar(4) = OptVar_n(4)*(max(L_D) - min(L_D)) + min(L_D);

Thetas = ModelInfo.Theta
OptVar
-1*OptPred

%% Check specific Point
% ALPHA = 30; BETA = 14; GAMMA = 15; LD = 6; % reference Geometry
% ALPHA = 36.78; BETA = 21.59; GAMMA = 5.23; LD = 7.01; % M = 0.5 geo
ALPHA = 39.30; BETA = 23.15; GAMMA = 1.74; LD = 7.61; % M = 2.5 geo
ALPHA = 32.2; BETA = 21.6; GAMMA = 2.6; LD = 8.000;
alpha_in = (ALPHA-min(alpha))./(max(alpha) - min(alpha));
beta_in = (BETA-min(beta))./(max(beta) - min(beta));
gamma_in = (GAMMA-min(gamma))./(max(gamma) - min(gamma));
L_D_in = (LD-min(L_D))./(max(L_D) - min(L_D));

TestInput = [alpha_in beta_in gamma_in L_D_in];
eta = predictor(TestInput)
