clear global
clear all
close all
clc
global ModelInfo
% Number of variables
k=2;
% Number of sample points
n=20;


[X1 X2 Y]= textread('BraninDoE.txt','%f %f %f',21)
% sampling plan
ModelInfo.X = [X1, X2]
%  observed data
ModelInfo.y= Y

count = 1;
EIOpt = 0;
%while EIOpt<5
    
% Set upper and lower bounds for search of log theta
UpperTheta=ones(1,k).*2;
LowerTheta=ones(1,k).*-3;
UpperTheta=[0.51453161322176370 0.26753044089773350]
LowerTheta=[0.51453161322176370 0.26753044089773350]
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
BraninTrue(j,i)=branin([Xplot(i) Xplot(j)]);
end
end
figure(1)
contourf(Xplot,Xplot,BraninPred,80); hold on
colorbar
title('Krig Approximation')
plot(X1,X2,'r.','MarkerSize',15)
figure(2)
contourf(Xplot,Xplot,BraninTrue,80)
colorbar
title('True Branin Function')

[OptVar,OptPred]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))

% Search model
	ModelInfo.Option='NegLogExpImp';
	[OptVar,EIOpt]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
    
    % Add infill point
	ModelInfo.X(end+1,:)=OptVar;
	ModelInfo.y(end+1)=branin(ModelInfo.X(end,:)) 
 OptVar_vec(count,:)=OptVar
 OptPred_vec(count)=OptPred
 count=count+1
%end
