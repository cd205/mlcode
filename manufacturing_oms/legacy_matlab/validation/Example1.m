clear global
clear all
clc
global ModelInfo
% Number of variables
k=2;
% Number of sample points
n=20;
% Create sampling plan
ModelInfo.X=bestlh(n,k,50,20);
% Calculate observed data
for i=1:n
ModelInfo.y(i,1)=branin(ModelInfo.X(i,:));
end
count = 1;
EIOpt = 0;
%while EIOpt<5
    
% Set upper and lower bounds for search of log theta
UpperTheta=ones(1,k).*2;
LowerTheta=ones(1,k).*-3;
% Run GA search of likelihood
[ModelInfo.Theta,MinNegLnLikelihood]=...
ga(@likelihood,k,[],[],[],[],LowerTheta,UpperTheta);
% Put Cholesky factorization of Psi, and theta into ModelInfo
[NegLnLike,ModelInfo.Psi,ModelInfo.U]=likelihood(ModelInfo.Theta);

ModelInfo.Option='Pred';
Xplot=0:1/20:1;
for j=1:21
for i=1:21
BraninPred(j,i)=predictor([Xplot(i) Xplot(j)]);
BraninTrue(j,i)=Branin([Xplot(i) Xplot(j)]);
end
end
subplot(1,2,1)
contourf(Xplot,Xplot,BraninPred,80)
colorbar
title('Krig Approximation')
subplot(1,2,2)
contourf(Xplot,Xplot,BraninTrue,80)
colorbar
title('True Branin Function')

[OptVar,OptPred]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))

% Search model
	ModelInfo.Option='NegLogExpImp';
	[OptVar,EIOpt]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
    
    % Add infill point
	ModelInfo.X(end+1,:)=OptVar;
	ModelInfo.y(end+1)=Branin(ModelInfo.X(end,:)) 
 OptVar_vec(count,:)=OptVar
 OptPred_vec(count)=OptPred
 count=count+1
%end
