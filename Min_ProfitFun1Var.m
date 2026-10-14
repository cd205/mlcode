
clear all
close all
clc

darkred = [127.5 0 0]./255;
red = [237 28 36]./255;
orange = [241 140 34]./255;
yellow = [255 222 23]./255; 
lightgreen = [173 209 54]./255;
darkgreen = [8 135 67]./255;
lightblue = [71 195 211]./255;
darkblue = [33 64 154]./255;
purple = [150 100 155]./255;
pink = [238 132 181]./255;

%Minimise Profit Fun 1 Var
L = [8]; U = [12];
LB = L - 5;
UB = U + 5;
sig = 1

mu_vec = linspace(L,U,200);

for i = 1:length(mu_vec)
    [ProdCost(i),Profit(i),S] = ProdCostFun_1Var(mu_vec(i),sig,U,L);
    ScrapCost(i) = S.Scrap; ReworkCost(i) = S.Rework; Conf(i) = S.fIC;
end
[v p] = min(ProdCost)
figure;
plot(mu_vec,ScrapCost,'k--s','MarkerSize',5,'Linewidth',1); hold on; grid on
plot(mu_vec,ReworkCost,'k--o','MarkerSize',5,'Linewidth',1); hold on
plot(mu_vec,ProdCost,'k-*','MarkerSize',5,'Linewidth',1); hold on
plot(mu_vec,Profit,'k-+','MarkerSize',5,'Linewidth',1); hold on
set(gca,'FontSize',15)
xlabel('\mu'); ylabel('Cost')
Leg = legend('Scrap Cost','Rework Cost','Production Cost','Profit'); set(Leg,'FontSize',15)

figure;
plot(mu_vec,Profit,'b-','MarkerSize',5,'Linewidth',3); hold on
plot(mu_vec,ProdCost,'k-','MarkerSize',5,'Linewidth',3); hold on
plot(mu_vec,ScrapCost,'-','MarkerSize',5,'Color','red','Linewidth',3); hold on; grid on
plot(mu_vec,ReworkCost,'-','MarkerSize',5,'Color',[8 135 67]./255,'Linewidth',3); hold on


%% Maximise Profit
FUN1 = @(mu) -1*(ProfitFun_1Var(mu,sig,U,L));
x0 = [U(1)];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec1 = fminsearchcon(FUN1,x0,LB,UB,[],[],[],options)
Opt_val1 = -1*FUN1(MU_opt_vec1)
[Profit1,ProdCost1,S1] = ProfitFun_1Var(MU_opt_vec1,sig,U,L)
%[Profit1,S1,PIs1,f1s1,f2s1] = ProfitFun_2var_CDodd_MultiOut(MU_opt_vec1(1),MU_opt_vec1(2),...
%    MU_opt_vec1(1),MU_opt_vec1(2),U,L,SIGMA)
%CheckVals = f1s1(2)+f1s1(3)+f1s1(4)+f2s1(2)+f2s1(3)+f2s1(4)+PIs1(4)+PIs1(5);

%% Minimise Production Cost
FUN2 = @(mu) (ProdCostFun_1Var(mu,sig,U,L));
x0 = [U(1)];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec2 = fminsearchcon(FUN2,x0,LB,UB,[],[],[],options)
Opt_val2 = FUN2(MU_opt_vec2)
[ProdCost2,Profit2,S2] = ProdCostFun_1Var(MU_opt_vec2,sig,U,L)

figure(2)
plot(MU_opt_vec1,Opt_val1,'.','MarkerSize',40,'Color','red'); hold on
plot(MU_opt_vec2,Opt_val2,'V','MarkerSize',15,'MarkerFaceColor',[241 140 34]./255,'MarkerEdgeColor',[241 140 34]./255)
set(gca,'FontSize',15)
xlabel('\mu'); ylabel('Monetary Units'); 
Leg = legend('Profit','Production Cost','Scrap Cost','Rework Cost','Opt. Profit','Min Prod. Cost'); set(Leg,'FontSize',15)

%% min just inital scrap and rework cost
FUN3 = @(mu) 100*normcdf(L,mu,sig) + (1-normcdf(U,mu,sig))*25
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec3 = fminsearchcon(FUN3,x0,LB,UB,[],[],[],options)
Opt_val1 = FUN3(MU_opt_vec3)

figure;
plot(mu_vec,100*normcdf(L,mu_vec,sig),'b.-'); hold on; grid on
plot(mu_vec,(1-normcdf(U,mu_vec,sig))*25,'r.-'); hold on
plot(mu_vec,FUN3(mu_vec),'k.-')


