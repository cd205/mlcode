clear all
clc
global ModelInfo
% Number of variables 
k=1;
% Create sampling plan
Data_x = [273.55, 275.2, 277, 311, 341];
RePos_Data_x = Data_x - (min(Data_x));
Normailise_Data_x = RePos_Data_x./(max(RePos_Data_x));
ModelInfo.X=Normailise_Data_x';%lhsdesign(4,1)  
n=length(ModelInfo.X);

count = 1;
% Calculate observed data
for i=1:n
% ModelInfo.y(i,:)=Forrester(ModelInfo.X(i));  
Data_y = [6.718, 7.019, 6.869, 8.926, 9.060];
ModelInfo.y(i,:) = Data_y(i);

end
 %Forrester(ModelInfo.X(i));
% Set upper and lower bounds for search of log theta
while length(ModelInfo.X) < 8
    figure(1)
    subplot(2,1,1)
    plot(ModelInfo.X,ModelInfo.y,'r.','MarkerSize',20)
    hold on
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
    
    
    %%% PLotting
    Xplot=0:0.01:1;
    for j=1:length(Xplot)
        ModelInfo.Option='Pred';
        MillTimePred(j)=predictor([Xplot(j)]);
        ModelInfo.Option='RMSE';
        Uncertain_S(j)=predictor(Xplot(j));
    end


    colors=['b' 'k' 'r' 'm' 'g' 'c' 'b' 'k' 'r' 'm' 'g' 'c'];
    figure(1)
    subplot(2,1,1)
    plot(Xplot,MillTimePred,[colors(count) '-'])
    grid on
    hold on
    xlabel(['Normailise & Repositioned Root Width (multiply by ',num2str(max(Data_x)),' then add ',num2str(min(Data_x)),')'])
    ylabel('Milling Time')
    subplot(2,1,2)
    plot(Xplot,Uncertain_S,'r-')
    grid on
    xlabel(['Normailise & Repositioned Root Width (multiply by ',num2str(max(Data_x)),' then add ',num2str(min(Data_x)),')'])
    ylabel('Prediction error')
    
        
    %%% Update with new points %%%
    [Largest_S Largest_S_Pos] = max(Uncertain_S);
    Xplot_Update = Xplot(Largest_S_Pos)
    ModelInfo.X(end+1)=Xplot_Update
    
    disp(['Enter new milling time at Root Width=',num2str(Xplot_Update),])
    ModelInfo.y(end+1) = input('Enter a Milling time')
    
    
end

    