%% Plot cost over design space
clear all
close all
clc
%% Variables
mu_N = 150;
mu_B = 0.002;
sigma_L = 1;
sigma_R = 0.8;
sigma_N = 0;
sigma_B = 0;
USL = 11;
LSL = 9;

L_vec = linspace(22,32,30);
R_vec = linspace(22,32,30);

%% cost over design space
tic
for i = 1:length(L_vec)
    mu_L = L_vec(i);
    for j = 1:length(R_vec)
        mu_R = R_vec(j);
        [P_con(j,i),P_srp(j,i),P_rwk(j,i)] = fun_CostScrapRwork(mu_L,...
            mu_R,mu_N,mu_B,sigma_L,sigma_R,sigma_N,sigma_B,LSL,USL);
        [C_tot(j,i),C_srp(j,i),C_rwk(j,i)] = Pump_L_R_CostModel...
            (P_con(j,i),P_srp(j,i),P_rwk(j,i));
    end
end
toc

%% Find max conformance and min cost points
max_con = max(max(P_con));
min_cost = min(min(C_tot));
[row_con col_con] = find(P_con==max_con);
[row_cost col_cost] = find(C_tot==min_cost);

%% Plotting
[LL RR] = meshgrid(L_vec,R_vec);
figure(3)
subplot(1,2,1)
contourf(LL,RR,P_con,100,'LineStyle','none')
colorbar;
c=colorbar;
ylabel(c,'Probability of conformance')
xlabel('L')
ylabel('R')
hold on
plot(L_vec(col_con),R_vec(row_con),'w.','MarkerSize',18)  % plot max conformance point
hold on
plot(L_vec(col_cost),R_vec(row_cost),'g.','MarkerSize',18)% plot min cost point

subplot(1,2,2)
contourf(LL,RR,C_tot,100,'LineStyle','none')
colorbar;
c=colorbar;
ylabel(c,'Cost')
xlabel('L')
ylabel('R')
hold on
plot(L_vec(col_con),R_vec(row_con),'w.','MarkerSize',18)  % plot max conformance point
hold on
plot(L_vec(col_cost),R_vec(row_cost),'g.','MarkerSize',18)% plot min cost point




% %% Cost model
% ScrapCost1 = 10;
% ReworkCost1 = 7;
% TotalCost1 = ((1./(1-Scrap_Total)).*ScrapCost1) + ((1./(1-Rwork_Total)).*ReworkCost1);
% min_cost1 = min(min(TotalCost1));
% [row1 col1] = find(TotalCost1==min_cost1);
% 
% ScrapCost2 = 7.5;
% ReworkCost2 = 7.5;
% TotalCost2 = ((1./(1-Scrap_Total)).*ScrapCost2) + ((1./(1-Rwork_Total)).*ReworkCost2);
% min_cost2 = min(min(TotalCost2));
% [row2 col2] = find(TotalCost2==min_cost2);