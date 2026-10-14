clear all
close all

addpath('../Sampling Plans');
addpath('../Vibration Problem');
addpath('../Constructing a Surrogate');
addpath('../Exploring and Exploiting a Surrogate');

rand('state',2)
randn('state',2)

global ModelInfo   

%Create sampling plan
count  = 1
n=150;
k=2;
ModelInfo.X=bestlh(n,k,20,10);
for i=1:n
	ModelInfo.y(i,1)=attenuation(ModelInfo.X(i,:));
end

% iterate for n*2 infill points
for I=1:n*2     
    
	% Set upper and lower bounds for search of log theta
	UpperTheta=ones(1,k).*2;
	LowerTheta=ones(1,k).*-3;
    
	% Run GA search of likelihood
	[ModelInfo.Theta,MinNegLnLikelihood]=ga(@likelihood,k,[],[],[],[],LowerTheta,UpperTheta);
    
	% Put Cholesky factorisation of Psi into ModelInfo
	[NegLnLike,ModelInfo.Psi,ModelInfo.U]=likelihood(ModelInfo.Theta);     
    
    % Plot surrogate models
	X=0:1/20:1;
	for i=1:21
        for j=1:21
            ModelInfo.Option='Pred';
            atten(i,j)=predictor([X(j) X(i)]);
            ModelInfo.Option='NegLogExpImp';
            ei(i,j)=predictor([X(j) X(i)]);
        end
    end
    subplot(2,1,1)
    contourf(X,X,-atten,20)
	colorbar
	hold on
	plot(ModelInfo.X(1:n,1),ModelInfo.X(1:n,2),'k.','MarkerSize',20)
	plot(ModelInfo.X(n+1:end,1),ModelInfo.X(n+1:end,2),'r.','MarkerSize',20)
    title('Kriging prediction')
	axis square
    subplot(2,1,2)
	contourf(X,X,10.^-ei,20)
	colorbar
	hold on
	plot(ModelInfo.X(1:n,1),ModelInfo.X(1:n,2),'k.','MarkerSize',20)
	plot(ModelInfo.X(n+1:end,1),ModelInfo.X(n+1:end,2),'r.','MarkerSize',20)
    title('Expected improvement')
	axis square
   
	% Search model
	ModelInfo.Option='NegLogExpImp';
	[OptVar,EIOpt]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
    
    % Add infill point
	ModelInfo.X(end+1,:)=OptVar;
	ModelInfo.y(end+1)=attenuation(ModelInfo.X(end,:)) 
   
    plottruss(OptVar);
    
    % Display best attenuation so far
    disp(['Best attenuation so far is ',num2str(-min(ModelInfo.y))])
count = count +1
end
save expectedimprovement.mat
