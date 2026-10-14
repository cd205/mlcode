% solve minimum of cmc dist
close all
clear all
clc
count = 1
%psig = linspace(0.0,0.0,1)
%for nm = 1:length(psig)
mu1 = linspace(3,7,20);
mu2 = linspace(3,7,20);
sig11 =2;
sig22 = 2;
SIGMA = [sig11^2 0;0 sig22^2];
U = [6 6];
L = [4 4];
C = 1;
mu1_R = L(1)+(U(1)-mu1);
mu2_R = L(2)+(U(2)-mu2);


% for i = 1:length(mu1)
%     for j = 1:length(mu2)
%         mu1_rw = mu1(i);
%         mu2_rw = mu2(j);
%         [TC(j,i)] = MinCMCFun_2var(mu1(i),mu2(j),mu1_rw,mu2_rw,U,L,SIGMA);
%     end
% end
% 
% MinTC = min(TC);
% MinTC  = min(MinTC)
% [MinRow MinCol] = find(TC==MinTC);
% Min_mu1 = mu1(MinCol)
% Min_mu2 = mu2(MinRow)
% figure(1)
% contour(mu1,mu2,TC,50); hold on
% xlabel('\mu_1')
% ylabel('\mu_2')
% plot3(Min_mu1,Min_mu2,MinTC,'g.','MarkerSize',30)
% grid on


%% find true optimum
% requires DSOCS1 folder for the 'fminsearchcon' fucntion
'start constrained optimisation'
LB = L - 3;
UB = U + 3;
%% Case 1
FUN1 = @(MU) -1*(MinCMCFun_2var(MU(1),MU(2),MU(1),MU(2),U,L,SIGMA));
x0 = [5,5];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec1 = fminsearchcon(FUN1,x0,LB,UB,[],[],[],options)
Opt_val1 = -1*(FUN1(MU_opt_vec1))
[TC1,S1,PIs1,f1s1,f2s1] = MinCMCFun_2var(MU_opt_vec1(1),MU_opt_vec1(2),...
    MU_opt_vec1(1),MU_opt_vec1(2),U,L,SIGMA);
%CheckVals = f1s1(2)+f1s1(3)+f1s1(4)+f2s1(2)+f2s1(3)+f2s1(4)+PIs1(4)+PIs1(5)

%% Case 2
FUN2 = @(MU) -1*(MinCMCFun_2var(MU(1),MU(2),MU(3),MU(4),U,L,SIGMA));
x0 = [6,6,6,6];
options = optimset('MaxIter',2000,'MaxFunEvals',500000,'TolFun',1e-15,'TolX',1e-12);
MU_opt_vec2 = fminsearchcon(FUN2,x0,[LB LB],[UB UB],[],[],[],options)
Opt_val2 = -1*(FUN2(MU_opt_vec2))
%[TC2(nm),S2,PIs2,f1s2,f2s2] = MinCMCFun_2var(MU_opt_vec2(1),MU_opt_vec2(2),...
%    MU_opt_vec2(3),MU_opt_vec2(4),U,L,SIGMA);
%end
% CheckVals = f1s2(2)+f1s2(3)+f1s2(4)+f2s2(2)+f2s2(3)+f2s2(4)+PIs2(4)+PIs2(5)
% CostDiffPerCent = 100 - TC2/TC1*100 % percentage difference between results 
% plot(psig,TC1,'b.-'); grid on; hold on;
% plot(psig,TC2,'r.-')
% 
% figure;
% X = [1,2,3,4,5,6,7];
% Y = [S1.Sc1, S2.Sc1; S1.Sc2, S2.Sc2; S1.Sc3, S2.Sc3; S1.Sc4, S2.Sc4;...
%      S1.Rw1, S2.Rw1; S1.Rw2, S2.Rw2; S1.Rw3, S2.Rw3;];
% bar(X,Y,'grouped'); grid on
% set(gca,'XTickLabel',{'ScrI';'Scr2';'Scr3';'Scr4';'Rw2';'Rw3';...
%     'Rw4'})
% set(gca,'FontSize',15)
% ylabel('Scrap and Rework Cost')
% Leg = legend('Case 1','Case 2'); set(Leg,'FontSize',15)

% %% 1D cost
% RC = 25; SC = 100;
% Fun_1DCost = @(mu) (1 - normcdf(U(1),mu,sig11))*RC + (normcdf(L(1),mu,sig11))*SC;
% options = optimset('TolFun',1e-15,'TolX',1e-12);
% x0 = 5;
% MU_opt_1DCost = fminsearchcon(Fun_1DCost,x0,L(1),U(1),[],[],[],options)
% Opt_val3 = Fun_1DCost(MU_opt_1DCost)
% 
% %% 2D Cost
% Fun2DCost = @(MU) CostFun_2D(MU(1),MU(2),SIGMA,L,U);
% x0 = [5,5];
% options = optimset('TolFun',1e-15,'TolX',1e-12);
% MU_opt_2DCost = fminsearchcon(Fun2DCost,x0,LB,UB,[],[],[],options)
% Opt_val4 = FUN1(MU_opt_2DCost)

