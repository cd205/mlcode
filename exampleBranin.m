clear all
clc
close all
global ModelInfo
% Number of variables
k=2;
ModelInfo.NumVars=k
% Number of sample points
n=50;
% Create sampling plan
ModelInfo.X=bestlh(n,k,50,20);
% Calculate observed data
for i=1:n
ModelInfo.y(i,1)=branin(ModelInfo.X(i,:));
end
% Set upper and lower bounds for search of log theta
UpperHyper=[ones(1,k).*2, ones(1,k).*3];
LowerHyper=[ones(1,k).*-3, ones(1,k).*0.05];

%% Run GA search of likelihood to determine hyper parameters: theta's and 
% P's (there is a theta foreach variable so if k=2 then there will be a 
% theta_1 and theta_2 and a P_1 and P_2.
% ModelInfo.Hyper contains the values of these parameters.  the first 2
% entries ModelInfo.Hyper(1,1:2) are theta_1 and theta_2 while
% ModelInfo.Hyper(1,2:4 ) P_1 and P_2 assuming k=2.
[ModelInfo.Hyper,MinNegLnLikelihood]=...
ga(@likelihood,k,[],[],[],[],LowerHyper,UpperHyper);
ModelInfo.Theta = ModelInfo.Hyper(1,1:k) % take theta hyperparameters
ModelInfo.P = ModelInfo.Hyper(1,k+1:k+k) % take P hyperparameters

%% Put Cholesky factorization of Psi, P and theta into ModelInfo
[NegLnLike,ModelInfo.Psi,ModelInfo.U]=likelihood(ModelInfo.Hyper);

%% Plot Surface
ModelInfo.Option='Pred';
Xplot=0:1/100:1;
for j=1:101
    for i=1:101
        BraninPred(j,i)=predictor([Xplot(i) Xplot(j)]);
    end
end

figure(1)
surf(Xplot,Xplot,BraninPred,'EdgeColor','none')
hold on
plot3(ModelInfo.X(:,1),ModelInfo.X(:,2),ModelInfo.y,'k.','MarkerSize',20)