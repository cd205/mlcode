clear all
clc
global ModelInfo
% Number of variables 
k=1;
% Create sampling plan
ModelInfo.X=lhsdesign(4,1) 
n=length(ModelInfo.X);


% Calculate observed data
for i=1:n
ModelInfo.y(i,:)=Forrester(ModelInfo.X(i));

end
figure(1)
plot(ModelInfo.X,ModelInfo.y,'b.','MarkerSize',20)
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
    
    % plot models 
    
    Xplot=0:0.01:1;
    counter = 1;
    for j=1:length(Xplot)
        ModelInfo.Option='Pred';
        ForresterPred(j)=predictor([Xplot(j)]);
        ForresterTrue(j)=Forrester([Xplot(j)]);
        ModelInfo.Option='RMSE';
        Uncertain_S(j)=predictor(Xplot(j))
        % BraninTrue(j,i)=Branin([Xplot(i) Xplot(j)]);
    end
    
%    % Plot surrogate models
% 	X=0:1/20:1;
% 	for i=1:21
%         for j=1:21
%             ModelInfo.Option='Pred';
%             atten(i,j)=predictor([X(j) X(i)]);
%             ModelInfo.Option='NegLogExpImp';
%             ei(i,j)=predictor([X(j) X(i)]);
%         end
%     end
%     
     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
    
    
    
    %newpoint=zeros(1,2);
    colors=['b' 'k' 'r' 'm' 'g' 'c' 'b' 'k' 'r' 'm' 'g' 'c'];
    figure(1)
    plot(Xplot,ForresterPred,'k-')
    plotyy(Xplot,ForresterTrue,Xplot,Uncertain_S)
   
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