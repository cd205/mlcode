%% calculate the conformance of the design space of the pump changing the 
% Radius (R) and Bore Length (L).
clear all
close all
clc


mu_L_Range = linspace(20,60,180);
mu_R_Range = linspace(20,60,180);
mu_B = 0.002;
mu_N = 150;

sigma_L = 1;
sigma_R = 0.8;
sigma_N = 0;
sigma_B = 0;%5.0E-05;
USL = 11;
LSL = 9;
n = 100000;
P_success = zeros(length(mu_L_Range),length(mu_R_Range));
tic
parfor i = 1:length(mu_L_Range)
    mytemp1 = zeros(length(mu_L_Range),1);
    mu_L = mu_L_Range(i);
    for j = 1:length(mu_R_Range)
        mu_R = mu_R_Range(j);
            [mytemp1(j),~,~] = ConformanceCalc(mu_L,...
                mu_R,mu_N,mu_B,sigma_L,sigma_R,sigma_N,sigma_B,USL,LSL,n);
    end
    P_success(:,i) = mytemp1;
end
toc

Max_success = max(max(P_success))
[row col] = find(P_success==Max_success);
Max_L = mu_L_Range(col)
Max_R = mu_R_Range(row)
[L R] = meshgrid(mu_L_Range,mu_R_Range);

contourf(L,R,P_success,200,'LineStyle','none')
colorbar
c = colorbar;
ylabel(c,'Probability of conformance: ActFlow')
xlabel('L')
ylabel('R')
hold on
plot(Max_L,Max_R,'g.','MarkerSize',18)
%plot(24.9162,29.6089,'g.','MarkerSize',18)




