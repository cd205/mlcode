
clear all
close all
clc
SP = 120;
PC = 45;
RC = [15 12 20];
SC = [8 9 11 14];
%RC = [0 30 24 40];
%SC = [16 18 22 28];
sig11 = 1.0;
sig22 = 1.0;
SIGMA = [sig11^2 0; 0 sig22^2]
Lx = 8;
Ly = 13;
Ux = 12;
Uy = 17;


%% Plot Surfaces 
x=linspace(8,13,30); y=linspace(12,17,30);

for i = 1:length(x)
    for j = 1:length(y)
        [F_stageC,pIC,Rwi,Sri] = StageCostFun([x(i) y(j)],SIGMA,[Ux Uy],[Lx Ly],RC,SC);
        EP2(j,i) = SP*F_stageC - (PC + Sri + Rwi);
        ProdCost(j,i) = (PC + Sri + Rwi);
        ScrapCost(j,i) = Sri;
        ReworkCost(j,i) = Rwi;
    end 
end

%surf(x,y,EP1)
%xlabel('x'); ylabel('y')
%%Find MAX PROFIT optimum x and y values

FUN1 = @(MU) -1*EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
x0 = [10 15];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec1 = fminsearchcon(FUN1,x0,[Lx Ly],[Ux Uy],[],[],[],options)
Opt_val1 = -1*FUN1(MU_opt_vec1)

FUN2 = @(MU) ProdCostFun(MU,SIGMA,[Ux Uy],[Lx Ly],RC,SC,PC)
x0 = [10 15];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec2 = fminsearchcon(FUN2,x0,[Lx Ly],[Ux Uy],[],[],[],options)
Opt_val2 = FUN2(MU_opt_vec2)
%% Plot Surfaces
figure(1)
surf(x,y,EP2,'FaceColor','blue'); hold on
surf(x,y,ProdCost,'FaceColor','black')
surf(x,y,ScrapCost,'FaceColor','red')
surf(x,y,ReworkCost,'FaceColor','green')
alpha  0.4

figure(1)
plot3(MU_opt_vec1(1),MU_opt_vec1(2),Opt_val1,'.','MarkerSize',40,'Color','red') 
plot3(MU_opt_vec2(1),MU_opt_vec2(2),Opt_val2+10,'V','MarkerSize',12,'MarkerFaceColor',[241 140 34]./255,'MarkerEdgeColor',[241 140 34]./255)
set(gca,'FontSize',15)
xlabel('\mu_{x_1}'); ylabel('\mu_{x_2}'); zlabel('Monetary Units')
Leg = legend('Profit','Production Cost','Scrap Cost','Rework Cost','Opt. Profit','Min Prod. Cost'); set(Leg,'FontSize',15)
view(-135,20)
axis([Lx Ux Ly Uy])