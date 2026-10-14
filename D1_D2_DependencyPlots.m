% D1 D2 cost looking at the effect of correlation

clear all
close all
clc
%% parameters for D1 and D2

sig11_D1 = 1;
sig22_D2 = 1;
c = 0.0;
SIGMA = [sig11_D1^2 c; c sig22_D2^2];
A = [3 4];
B = [7 8];
LD1 = A(1);
LD2 = A(2);
UD1 = B(1);
UD2 = B(2);

fun = @(MU_0) -1*D1_D2_CostModel(MU_0,SIGMA,LD1,LD2,UD1,UD2)
% fun(MU_0)
% [x1 fval1] = fminsearch(fun,MU_0,options)

lb = [3 4]
ub = [7 8]
%GAOptions=gaoptimset('PopulationSize',2000,'Generations',20);
%[BestVar,BestObj,history,eval_count]=ga(fun,4,[],[],[],[],lb,ub,[],GAOptio
%ns)
mu = [5 6]
CostAt5 = fun([5,5])
BestVar = [5 5]
StartVar = BestVar;
SIMPOptions = optimset('MaxFunEvals',1000);
[BestVar, BestObj, ExitFlag, Output]=fminsearchcon(fun,StartVar,lb,ub,[],[],[],SIMPOptions) 
Output = struct2cell(Output);   % change output structure from fmincon into cell structure
Evals_Fmincon = cell2mat(Output(2));  % get number of func evals from fmincon (convert into matix)

MinValue = BestObj

%% PLot Dependency
figure(1)
r = mvnrnd(mu,SIGMA,3000);
plot(r(:,1),r(:,2),'+'); grid on; hold on
axis([0 10 0 10])
xlabel('d_1')
ylabel('d_2')
line([0,10], [lb(2) lb(2)],'color',[0 0 0],'linewidth',2)
line([0,10], [0 0],'color',[0 0 0],'linewidth',2)
line([10,10], [0 lb(2)],'color',[0 0 0],'linewidth',2)
line([0,0], [0 10],'color',[0 0 0],'linewidth',2)
line([lb(1),lb(1)], [0 10],'color',[0 0 0],'linewidth',2)
line([0,lb(1)], [10 10],'color',[0 0 0],'linewidth',2)
line([lb(1),10], [10 10],'color',[0 0 0],'linewidth',2)
line([10,10], [10 lb(2)],'color',[0 0 0],'linewidth',2)
line([10,ub(1)], [lb(2),lb(2)],'color',[0 0 0],'linewidth',2)
line([ub(1),ub(1)], [lb(2),10],'color',[0 0 0],'linewidth',2)
line([lb(1),10], [ub(2),ub(2)],'color',[0 0 0],'linewidth',2)
line([lb(1),lb(1)], [ub(2),10],'color',[0 0 0],'linewidth',2)
fill([0 0 10 10],[0 lb(2) lb(2) 0],'r','FaceAlpha',0.4);
fill([0,0,lb(1),lb(1)],[lb(2),10,10,lb(2)],'r','FaceAlpha',0.4);
fill([ub(1) ub(1) 10 10], [lb(2) 10 10 lb(2)],'g','FaceAlpha',0.4);
fill([lb(1) lb(1) ub(1) ub(1)], [ub(2) 10 10 ub(2)],'g','FaceAlpha',0.4);
fill([lb(1) lb(1) ub(1) ub(1)], [lb(2) ub(2) ub(2) lb(2)],'b','FaceAlpha',0.3);
text(1,2,'S_{d_1,d_2}','FontSize',25)
text(1,7,'S_{d_1}','FontSize',25)
text(6,2,'S_{d_2}','FontSize',25)
text(8,6,'R_{d_1}','FontSize',25)
text(4.5,9,'R_{d_2}','FontSize',25)
text(8,9,'R_{d_1,d_2}','FontSize',25)
text(4.5,6,'C','FontSize',25)
% h = area([0 lb(1)],[10 10])
% set(h(1),'FaceColor',[0 1 0]); hold on
% alpha 0.5

Sd1d2 = mvncdf([-inf,-inf],[lb(1),lb(2)],mu,SIGMA);
Sd1 = mvncdf([lb(1),-inf],[inf lb(2)],mu,SIGMA);
Sd2 = mvncdf([-inf lb(2)],[lb(1),inf],mu,SIGMA);
Rd1d2 = mvncdf([ub(1),ub(2)],[inf,inf],mu,SIGMA);
Rd1 = mvncdf([ub(1),lb(2)],[inf,ub(2)],mu,SIGMA);
Rd2 = mvncdf([lb(1),ub(2)],[ub(1),inf],mu,SIGMA);
Con = mvncdf([lb(1),lb(2)],[ub(1),ub(2)],mu,SIGMA);
Tot = Sd1d2+Sd1+Sd2+Rd1d2+Rd1+Rd2+Con;

S = struct('Sd1d2',Sd1d2,'Sd1',Sd1,'Sd2',Sd2,...
           'Rd1d2',Rd1d2,'Rd1',Rd1,'Rd2',Rd2,...
           'Con',Con,'Tot',Tot)






% figure(2)
% [X1,X2] = meshgrid(linspace(mu(1)-3,mu(1)+3,50)',linspace(mu(2)-3,mu(2)+3,50)');
% X = [X1(:) X2(:)];
% p = mvnpdf(X,mu,SIGMA);
% surf(X1,X2,reshape(p,50,50));
% alpha 0.5
% axis([mu(1)-3, mu(1)+3, mu(2)-3, mu(2)+3])
% view(3)
% xlabel('d_1')
% ylabel('d_2')
% zlabel('Probability density')
% line([mu(1)-3 mu(1)+3], [mu(2)-3 mu(2)-3], [0.005 0.005],'color',[1 0 0],'linewidth',3)
% line([lb(1) mu(1)+3], [lb(2) lb(2)], [0.005 0.005],'color',[1 0 0],'linewidth',3)
% line([mu(1)+3 mu(1)+3], [mu(2)-3 lb(2)], [0.005 0.005],'color',[1 0 0],'linewidth',3)
% line([mu(1)-3 mu(1)-3], [mu(2)-3 mu(2)+3], [0.005 0.005],'color',[1 0 0],'linewidth',3)
% line([lb(1) lb(1)], [lb(2) mu(2)+3], [0.005 0.005],'color',[1 0 0],'linewidth',3)
% line([mu(1)-3 lb(1)], [mu(2)+3 mu(2)+3], [0.005 0.005],'color',[1 0 0],'linewidth',3)
% 
% line([ub(1) mu(1)+3], [lb(2) lb(2)], [0.005 0.005],'color',[0 1 0],'linewidth',3)
% line([mu(1)+3 mu(1)+3], [lb(2) mu(2)+3], [0.005 0.005],'color',[0 1 0],'linewidth',3)
% line([ub(1) ub(1)], [lb(2) ub(2)], [0.005 0.005],'color',[0 1 0],'linewidth',3)
% line([lb(1) mu(1)+3], [mu(2)+3 mu(2)+3], [0.005 0.005],'color',[0 1 0],'linewidth',3)
% line([lb(1) ub(1)], [ub(2) ub(2)], [0.005 0.005],'color',[0 1 0],'linewidth',3)
% line([lb(1) lb(1)], [ub(2) mu(2)+3], [0.005 0.005],'color',[0 1 0],'linewidth',3)
