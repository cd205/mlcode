% solve minimum of cmc dist
close all
clear all
clc
count = 1
psig = 0

MU3 = [5 5 5];
MU2 = [5.3 5.3 5.3]; 
MU1 = [5.5 5.5 5.5];
sig11 = 2;
sig22 = 2.0;
sig33 = 2
SIGMA = [sig11^2 0 0;0 sig22^2 0;0 0 sig33^2];
% SIGMA = [1 0 0; 0 1 0; 0 0 1];
U = [6 6 6]
L = [4 4 4];
C = 1;


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
FUN1 = @(MU) -1*(MinCMCFun_3var(MU,MU,MU,U,L,SIGMA));
x0 = [5,5,5];
options = optimset('TolFun',1e-15,'TolX',1e-12);
MU_opt_vec1 = fminsearchcon(FUN1,x0,LB,UB,[],[],[],options)
Opt_val1 = -1*(FUN1(MU_opt_vec1))
%[Profit1,TC1,S1] = MinCMCFun_3var(MU_opt_vec1,MU_opt_vec1,...
%    MU_opt_vec1,U,L,SIGMA)

%% Case 2
FUN2 = @(MU) -1*MinCMCFun_3var(MU(1:3),MU(4:6),MU(7:9),U,L,SIGMA);
x0 = [5 5 5, 5 5 5, 5 5 5];
options = optimset('MaxIter',2000,'MaxFunEvals',500000,'TolFun',1e-15,'TolX',1e-12);
MU_opt_vec2 = fminsearchcon(FUN2,x0,[LB LB LB],[UB UB UB],[],[],[],options)
Opt_val2 = FUN2(MU_opt_vec2);
[Profit2,TC2,S2] = MinCMCFun_3var(MU_opt_vec2(1:3),MU_opt_vec2(4:6),...
    MU_opt_vec2(7:9),U,L,SIGMA)

% CostDiffPerCent = 100 - TC2/TC1*100 % percentage difference between results 
% plot(psig,TC1,'b.-'); grid on; hold on;
% plot(psig,TC2,'r.-')
% 
% figure;
% X = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
% Y = [S1.Sc1, S2.Sc1; S1.Sc2, S2.Sc2; S1.Sc3, S2.Sc3; S1.Sc4, S2.Sc4;...
%      S1.Sc5, S2.Sc5; S1.Sc6, S2.Sc6; S1.Sc7, S2.Sc7; S1.Sc8, S2.Sc8;...
%      S1.Rw1, S2.Rw1; S1.Rw2, S2.Rw2; S1.Rw3, S2.Rw3;...
%      S1.Rw4, S2.Rw4; S1.Rw5, S2.Rw5; S1.Rw6, S2.Rw6; S1.Rw7, S2.Rw7];
% bar(X,Y,'grouped'); grid on
% set(gca,'XTickLabel',{'ScrI';'Scr2';'Scr3';'Scr4';'Scr5';'Scr6';'Scr7';'Scr8';'Rw2';'Rw3';...
%     'Rw4';'Rw5';'Rw6';'Rw7';'Rw8'})
% set(gca,'FontSize',15)
% ylabel('Scrap and Rework Cost')
% Leg = legend('Case 1','Case 2'); set(Leg,'FontSize',15)
