% Plot the profit surfaces
clear all
close all
clc
tic
num = 10;
% xvec = linspace(8,12,num); yvec = linspace(13,17,num);
% L = [8, 13]; U = [12, 17];
% LB = L - 4;
% UB = U + 4;
xvec = linspace(4,8,num); yvec = linspace(4,8,num)
L = [4 4]; U = [6 6];
LB = L - 3;
UB = U + 3;
sig11 = 2; sig22 = 2;
rho = 0;
SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];
for i = 1:num
    i
    for j = 1:num
        FUNo = @(MU) -1*(ProfitFun_2var_CDodd(xvec(i),yvec(j),MU(1),MU(2),U,L,SIGMA));
        x0 = [xvec(i),yvec(j)];
        options = optimset('MaxIter',1000,'MaxFunEvals',5000,'TolFun',1e-7,'TolX',1e-7);
        SingleMU_opt_vec = fminsearchcon(FUNo,x0,LB,UB,[],[],[],options);
        

        EP1(j,i) = ProfitFun_2var_CDodd(xvec(i),yvec(j),...
            xvec(i),yvec(j),U,L,SIGMA);
        EP2(j,i) = ProfitFun_2var_CDodd(xvec(i),yvec(j),...
            SingleMU_opt_vec(1),SingleMU_opt_vec(2),U,L,SIGMA);
    end
end
toc
% 
% h1 = surf(xvec,yvec,EP1); hold on
% h2 = surf(xvec,yvec,EP2); hold on
% set(h1,'FaceColor',[1 0 0],'EdgeColor',[0.2 0.2 0.2],'FaceAlpha',0.5)
% set(h2,'FaceColor',[0 1 0],'EdgeColor',[0.2 0.2 0.2],'FaceAlpha',1)


%% Case 1
FUN1 = @(MU) -1*(ProfitFun_2var_CDodd(MU(1),MU(2),MU(1),MU(2),U,L,SIGMA));
x0 = [U(1),U(2)];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec1 = fminsearchcon(FUN1,x0,LB,UB,[],[],[],options)
Opt_val1 = -1*FUN1(MU_opt_vec1)
[Profit1,S1,PIs1,f1s1,f2s1] = ProfitFun_2var_CDodd_MultiOut(MU_opt_vec1(1),MU_opt_vec1(2),...
    MU_opt_vec1(1),MU_opt_vec1(2),U,L,SIGMA)
CheckVals = f1s1(2)+f1s1(3)+f1s1(4)+f2s1(2)+f2s1(3)+f2s1(4)+PIs1(4)+PIs1(5);

%% Case 2
FUN2 = @(MU) -1*(ProfitFun_2var_CDodd(MU(1),MU(2),MU(3),MU(4),U,L,SIGMA));
x0 = [U(1),U(2),U(1),U(2)];
options = optimset('MaxIter',2000,'MaxFunEvals',500000,'TolFun',1e-15,'TolX',1e-12);
MU_opt_vec2 = fminsearchcon(FUN2,x0,[LB LB],[UB UB],[],[],[],options)
Opt_val2 = -1*FUN2(MU_opt_vec2)
[Profit2,S2,PIs2,f1s2,f2s2] = ProfitFun_2var_CDodd_MultiOut(MU_opt_vec2(1),MU_opt_vec2(2),...
    MU_opt_vec2(3),MU_opt_vec2(4),U,L,SIGMA)

%%
CostDiffPerCent = 100 - Opt_val1/Opt_val2*100 % percentage difference between results 
CostDiffPerCent = 100 - Profit1/Profit2*100

figure;
m1 = mesh(xvec,yvec,EP1,'EdgeColor','black','LineWidth',1.2); hold on
m2 = mesh(xvec,yvec,EP2,'EdgeColor',[0.6 0.6 0.6]); hold on
set(m2,'FaceAlpha',0.7)
plot3(MU_opt_vec1(1),MU_opt_vec1(2),Opt_val1+5,'k.','MarkerSize',39); hold on
plot3(MU_opt_vec2(1),MU_opt_vec2(2),Opt_val2+9,'k V','MarkerSize',15,'MarkerFaceColor',[0 0 0])
view(-125, 16);  set(gca,'FontSize',15)
xlabel('\mu_{1,1}'); ylabel('\mu_{1,2}'); zlabel('Expected Profit (EP)');
legend('Case I surface','Case II surface','Case I \mu_{opt}','Case II \mu_{opt}');



figure;
X = [1,2,3,4,5,6,7];
Y = [S1.Sc1, S2.Sc1; S1.Sc2, S2.Sc2; S1.Sc3, S2.Sc3; S1.Sc4, S2.Sc4;...
     S1.Rw1, S2.Rw1; S1.Rw2, S2.Rw2; S1.Rw3, S2.Rw3;];
chart = bar(X,Y,'grouped'); grid on
set(chart(1),'facecolor','k'); set(chart(2),'facecolor',[0.6 0.6 0.6]); % set bar colors
set(gca,'XTickLabel',{'SrI';'Sr2';'Sr3';'Sr4';'Rw2';'Rw3';...
    'Rw4'})
set(gca,'FontSize',15)
ylabel('Scrap and Rework Cost')
Leg = legend('Case I','Case II'); set(Leg,'FontSize',15)

figure;
h1 = surf(xvec,yvec,EP1,'FaceColor','green','EdgeColor','none'); hold on
h2 = surf(xvec,yvec,EP2,'FaceColor','red','EdgeColor','none'); hold on
set(h2,'FaceAlpha',0.6)
%set(h2,'FaceColor',[0 1 0],'EdgeColor',[0.2 0.2 0.2],'FaceAlpha',1)
camlight left; lighting phong

%ProdCost1 = S1.Sc1+S1.Sc2+S1.Sc3+S1.Sc4+S1.Rw1+S1.Rw2+S1.Rw3
%ProdCost2 = sum([S2.Sc1,S2.Sc2,S2.Sc3,S2.Sc4,S2.Rw1,S2.Rw2,S2.Rw3])

ScrapCost1 =  - S1.Sc1 -S1.Sc2 - S1.Sc3 - S1.Sc4 
RworkCost1 = -S1.Rw1 - S1.Rw2 - S1.Rw3
ProdCost1 = ScrapCost1 + RworkCost1

ScrapCost2 =  - S2.Sc1 - S2.Sc2 - S2.Sc3 - S2.Sc4
RworkCost2 = -S2.Rw1 - S2.Rw2 - S2.Rw3
ProdCost2 = ScrapCost2 + RworkCost2