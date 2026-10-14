clear all
clc
global ModelInfo
% Number of variables 
k=1;
% Data vectors for the Milling width and associated milling time
Data_x = [273.55, 275.2, 277, 311, 341];
Data_y = [6.718, 7.019, 6.869, 8.926, 9.060];
p = 1
colors=['b' 'k' 'r' 'm' 'g' 'b' 'b' 'k' 'r' 'm' 'g' 'c'];
while p<=length(Data_x)+1
    length(Data_x)+1
    clear ModelInfo.X
    clear ModelInfo.y
    if p > 5
       ModelInfo.X = [Data_x]';
       ModelInfo.y = [Data_y]';
       
    elseif p==1
       ModelInfo.X = [Data_x(p+1:length(Data_x))]';
       ModelInfo.y = [Data_y(p+1:length(Data_y))]';
    elseif p==length(Data_x)
       ModelInfo.X = [Data_x(1:p-1)]';
       ModelInfo.y = [Data_y(1:p-1)'];
    else
       ModelInfo.X = [Data_x(1:p-1), Data_x(p+1:length(Data_x))]';
       ModelInfo.y = [Data_y(1:p-1), Data_y(p+1:length(Data_y))]';
    end
    
    n=length(ModelInfo.X);
    % Plot data points
    figure(1)
    subplot(2,3,p)
    plot(ModelInfo.X,ModelInfo.y,[colors(p) '.'],'MarkerSize',20)
    grid on
    hold on

    % Set upper and lower bounds for search of log theta
    count=1;
    neglogeimin=0;
    % while neglogeimin<4
    UpperTheta=ones(1,k).*2;
    LowerTheta=ones(1,k).*-3;
    % Run GA search of likelihood
    [ModelInfo.Theta,MinNegLnLikelihood]=...
        ga(@likelihood,k,[],[],[],[],LowerTheta,UpperTheta);
    % Put Cholesky factorization of Psi, and theta into ModelInfo
    [NegLnLike,ModelInfo.Psi,ModelInfo.U]=likelihood(ModelInfo.Theta);
    
    ModelInfo.Option='Pred';
    Xplot=273:1:350;
    for j=1:length(Xplot)
        % for i=1:21
        MillTimePred(j)=predictor([Xplot(j)]);
        % BraninTrue(j,i)=Branin([Xplot(i) Xplot(j)]);
    end
    figure(1)
    subplot(2,3,p)
    plot(Xplot,MillTimePred,[colors(p) '-'],'LineWidth',1.5)
    xlabel('Root Width')
    ylabel('Milling Time (hrs)')
    grid on
    hold on
    p = p + 1
    figure(2)
    plot(Xplot,MillTimePred,[colors(p) '-'],'LineWidth',2)
    title('Possible Variation')
    xlabel('Root Width')
    ylabel('Milling Time (hrs)')
    hold on
    grid on
end

