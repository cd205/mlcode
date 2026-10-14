clear global
clear all
close all
clc
global ModelInfo
% Number of variables
k=2;
data = load('Exp_2D_150.dat');

dia = data(:,1);
ang = data(:,2);
dia_n = (data(:,1)-4)./(9-4);
ang_n = (data(:,2)-28)./(60-28);

% sampling plan
ModelInfo.X=[dia_n ang_n];
% observed data
ModelInfo.y=data(:,7);

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
Xplot=0:1/60:1;
for j=1:61
for i=1:61
Pred(j,i)=predictor([Xplot(i) Xplot(j)]);
end
end
figure;
surf(Xplot,Xplot,Pred); hold on
colorbar
title('Krig Approximation')
plot3(dia_n,ang_n,data(:,7),'g.','MarkerSize',15)
xlabel('Diameter'); ylabel('Angle')


% 
% [OptVar,OptPred]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
% 
% % Search model
% 	ModelInfo.Option='NegLogExpImp';
% 	[OptVar,EIOpt]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
%     
%     % Add infill point
% 	ModelInfo.X(end+1,:)=OptVar;
% 	ModelInfo.y(end+1)=branin(ModelInfo.X(end,:)) 
%  OptVar_vec(count,:)=OptVar
%  OptPred_vec(count)=OptPred
%  count=count+1
% %end
