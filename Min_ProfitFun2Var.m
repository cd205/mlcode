

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
L = [8 13]; U = [12 17];
LB = L ;
UB = U ;
SIGMA = [1 0; 0 1]

mu_x1 = linspace(LB(1),UB(1),30);
mu_x2 = linspace(LB(2),UB(2),30);
[MUx1 MUx2] = meshgrid(mu_x1,mu_x2);
MU = [MUx1(:) MUx2(:)];


for i = 1:length(MU)
    [ProdCost(i),Profit(i),S] = ProdCostFun_2Var(MU(i,:),SIGMA,U,L);
    ScrapCost(i) = S.Scrap; ReworkCost(i) = S.Rework;
end

Profit = reshape(Profit,length(mu_x1),length(mu_x2));
ProdCost = reshape(ProdCost,length(mu_x1),length(mu_x2));
ScrapCost = reshape(ScrapCost,length(mu_x1),length(mu_x2));
ReworkCost = reshape(ReworkCost,length(mu_x1),length(mu_x2));
figure(1)
surf(mu_x1,mu_x2,Profit,'FaceColor','blue'); hold on
surf(mu_x1,mu_x2,ProdCost,'FaceColor','black')
surf(mu_x1,mu_x2,ScrapCost,'FaceColor','red')
surf(mu_x1,mu_x2,ReworkCost,'FaceColor','green')
alpha  0.4

%% Maximise Profit
FUN1 = @(MU) -1*(ProfitCostFun_2Var(MU,SIGMA,U,L));
x0 = [U(1) U(2)];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec1 = fminsearchcon(FUN1,x0,LB,UB,[],[],[],options)
Opt_val1 = -1*FUN1(MU_opt_vec1)
[Profit1,S1] = ProfitCostFun_2Var(MU_opt_vec1,SIGMA,U,L)
%[Profit1,S1,PIs1,f1s1,f2s1] = ProfitFun_2var_CDodd_MultiOut(MU_opt_vec1(1),MU_opt_vec1(2),...
%    MU_opt_vec1(1),MU_opt_vec1(2),U,L,SIGMA)
%CheckVals = f1s1(2)+f1s1(3)+f1s1(4)+f2s1(2)+f2s1(3)+f2s1(4)+PIs1(4)+PIs1(5);

%% Minimise Production Cost
FUN2 = @(MU) (ProdCostFun_2Var(MU,SIGMA,U,L));
x0 = [U(1) U(2)]
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec2 = fminsearchcon(FUN2,x0,LB,UB,[],[],[],options)
Opt_val2 = FUN2(MU_opt_vec2)
[ProdCost2,Profit2,S2] = ProdCostFun_2Var(MU_opt_vec2,SIGMA,U,L)

figure(1)
plot3(MU_opt_vec1(1),MU_opt_vec1(2),Opt_val1,'.','MarkerSize',40,'Color','red') 
plot3(MU_opt_vec2(1),MU_opt_vec2(2),Opt_val2,'V','MarkerSize',10,'MarkerFaceColor',[241 140 34]./255,'MarkerEdgeColor',[241 140 34]./255)
set(gca,'FontSize',15)
xlabel('\mu_{x_1}'); ylabel('\mu_{x_2}'); zlabel('Monetary Units')
Leg = legend('Profit','Production Cost','Scrap Cost','Rework Cost','Opt. Profit','Min Prod. Cost'); set(Leg,'FontSize',15)
view(-135,20)
axis([L(1) U(1) L(2) U(2)])