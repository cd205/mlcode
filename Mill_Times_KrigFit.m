clear all
clc
global ModelInfo
% Number of variables 
k=1;
% Create sampling plan
ModelInfo.X=[275.2, 277, 311, 341]';%lhsdesign(4,1) 273.55, 
n=length(ModelInfo.X);


% Calculate observed data
for i=1:n
% ModelInfo.y(i,:)=Forrester(ModelInfo.X(i)); 6.718, 
vec = [7.019, 6.869, 8.926, 9.060];
ModelInfo.y(i,:) = vec(i);
figure(1)
plot(ModelInfo.X,vec,'r.','MarkerSize',20)
hold on
end
 %Forrester(ModelInfo.X(i));
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
    Xplot=273:1:341;
    for j=1:length(Xplot)
        % for i=1:21
        MillTimePred(j)=predictor([Xplot(j)]);
        % BraninTrue(j,i)=Branin([Xplot(i) Xplot(j)]);
    end
    %newpoint=zeros(1,2);
    colors=['b' 'k' 'r' 'm' 'g' 'c' 'b' 'k' 'r' 'm' 'g' 'c'];
    figure(1)
    plot(Xplot,MillTimePred,[colors(count) '-'])
    grid on
    hold on
%    % plot(newpoint(1),newpoint(2),[colors(count) '.'],'MarkerSize',20)
%    % hold on
%     [OptVar,OptPred]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))
%     
%     % Expected Improvement
%     % Search Model
%     ModelInfo.Option='NegLogExpImp'
%     [xmin,neglogeimin]=ga(@predictor,k,[],[],[],[],0,1)
%     
%     % Add infill point
%     ModelInfo.X(end+1,:)=xmin;
%     ModelInfo.y(end+1)=Forrester(ModelInfo.X(end,:));
%    
%     % [xmin,ymin]=fmincon(@predictor,OptVar(1),[],[],[],[],[0],[1])
%     count=count+1
% end
% figure(1)
% xlabel('x')
% ylabel('f(x)')
% title('Krig Approximation to Forrester Function')
% legend('Interation 1','Interation 2','Interation 3','Interation 4','Interation 5')
%     
% 
% end
%     subplot(1,2,1)
%     contourf(Xplot,Xplot,BraninPred,80)
%     colorbar
%     title('Krig Approximation')
%     subplot(1,2,2)
%     contourf(Xplot,Xplot,BraninTrue,80)
%     colorbar
%     title('True Branin Function')
%     
%     [OptVar,OptPred]=ga(@predictor,k,[],[],[],[],zeros(k,1),ones(k,1))