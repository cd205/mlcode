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
    '%f %f %f %f %f %f %f');

% Select the variable to plot
var1 = beta; var2 = gamma;


% Normalise inputs 
var1_n = (var1-min(var1))./(max(var1) - min(var1));
var2_n = (var2-min(var2))./(max(var2) - min(var2));
% alpha_n = (alpha-min(alpha))./(max(alpha) - min(alpha));
% beta_n = (beta-min(beta))./(max(beta) - min(beta));
% gamma_n = (gamma-min(gamma))./(max(gamma) - min(gamma));
% L_D_n = (L_D-min(L_D))./(max(L_D) - min(L_D));
% ModelInfo.X = [beta_n gamma_n];
ModelInfo.X = [var1_n, var2_n];
ModelInfo.y = [M0_5];
k = 2                        % number of variables point
n = size(ModelInfo.X,1) % number of sample point


% Set upper and lower bounds for search of log theta
UpperTheta=ones(1,k).*3;
LowerTheta=ones(1,k).*-3;
% Run GA search of likelihood
[ModelInfo.Theta,MinNegLnLikelihood]=...
ga(@likelihood,k,[],[],[],[],LowerTheta,UpperTheta);
ModelInfo.Theta
% Put Cholesky factorization of Psi, and theta into ModelInfo
[NegLnLike,ModelInfo.Psi,ModelInfo.U]=likelihood(ModelInfo.Theta);




ModelInfo.Option='Pred';

Xplot=0:1/40:1;
for j=1:41
for i=1:41
Eta(j,i)=predictor([Xplot(i) Xplot(j)]);
end
end

figure(1)
contourf(Xplot,Xplot,Eta,80,'LineColor','none'); hold on
colorbar
title('Krig Approximation to Eta')

predfun = @(X) -1*predictor(X);

[OptVar_n,OptPred]=ga(predfun,k,[],[],[],[],zeros(k,1),ones(k,1));
OptVar(1) = OptVar_n(1)*(max(var1) - min(var1)) + min(var1);
OptVar(2) = OptVar_n(2)*(max(var2) - min(var2)) + min(var2);
OptVar
-1*OptPred
figure(1)
plot(OptVar_n(1),OptVar_n(2),'g.','MarkerSize',20)
ModelInfo.Theta

% % Search model
% 	ModelInfo.Option='NegLogExpImp';
% 	[OptVar,EIOpt]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
    
%     % Add infill point
% 	ModelInfo.X(end+1,:)=OptVar;
% 	ModelInfo.y(end+1)=branin(ModelInfo.X(end,:)) 
%  OptVar_vec(count,:)=OptVar
%  OptPred_vec(count)=OptPred
%  count=count+1
% %end
