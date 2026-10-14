clear global
clear all
close all
clc
global ModelInfo
% Number of variables
k=2;
data = load('Exp_2D_150_Refined.dat');
data2 = load('Exp_2D_150.dat');
data3 = load('Exp_2D_100_Refined.dat');
YCol = 7;
dia = data(:,1);
ang = data(:,2);
dia_n = (data(:,1)-6.25)./(10.5-6.25);
ang_n = (data(:,2)-27)./(42-27);

% Find the values that fit with the refined DOE
% 6.25 <= dia <= 10.5 and 27 <= ang <= 42
data2Pos = find(data2(:,1)>=6.25 & data2(:,2)<=42);
dia2 = data2(data2Pos,1);
ang2 = data2(data2Pos,2);
dia_n2 = (dia2-6.25)./(10.5-6.25);
ang_n2 = (ang2-27)./(42-27);

dia_n3 = data3(:,1);
ang_n3 = data3(:,2);
dia_n3 = (data3(:,1)-6.25)./(10.5-6.25);
ang_n3 = (data3(:,2)-27)./(42-27);

% Plot the DOE with the 2 data sets
figure;
plot(dia_n,ang_n,'r.'); hold on
plot(dia_n2,ang_n2,'.')
plot(dia_n3,ang_n3,'g.')

% Combine the 2 data sets
dia_nCombo = [dia_n; dia_n2; dia_n3];
ang_nCombo = [ang_n; ang_n2; ang_n3];
y_Combo = [data(:,YCol); data2(data2Pos,YCol); data3(:,YCol)];
% sampling plan
ModelInfo.X=[dia_nCombo ang_nCombo];
% observed data
ModelInfo.y=y_Combo ;

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
plot3(dia_nCombo,ang_nCombo,y_Combo,'g.','MarkerSize',15)
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
