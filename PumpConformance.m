clear all
%close all
clc
%% Do a MC run to establish how many parts fail and how many meet the 
% functional specification (9.0 < actflow < 11.0) based on initial
% parameter values for L, R, B and N and manufacturing variations:
% sigma_L, sigma_R, sigma_B and sigma_N.

mu_L = 35.11;
mu_R = 24.95;
mu_N = 150;
mu_B = 0.002;
sigma_L = 1;
sigma_R = 0.8;
sigma_N = 0;
sigma_B = 0;%5.0E-05;
USL = 11;
LSL = 9;
num = 100000;
mu = [mu_L mu_R mu_N mu_B];
SIGMA = [sigma_L^2 0 0 0; 0 sigma_R^2 0 0; 0 0 sigma_N^2 0; 0 0 0 sigma_B^2];
data = mvnrnd(mu,SIGMA,num);
actflow = (pi.*data(:,2).*data(:,2).*data(:,1)./1E6 - data(:,4)).*data(:,3);
N_USL = length(find(actflow>USL))
N_LSL = length(find(actflow<LSL))
N_S = length(find(actflow>LSL & actflow<USL))
P_USL = N_USL/num
P_LSL = N_LSL/num
P_fail = (N_USL+N_LSL)/num
P_success = N_S/num
S = capability(actflow,[LSL,USL])
clear actflow

%% define tolerance limits
cpk = S(1).Cpk;
sigma = 3*cpk

tolL = sigma_L*sigma
tolR = sigma_R*sigma

B = mu_B;
N = mu_N;
%% Function 
TolL_Range = linspace(-1*tolL,tolL,50);
TolR_Range = linspace(-1*tolR,tolR,50);
L_vec = mu_L + TolL_Range;
R_vec = mu_R + TolR_Range;
for i = 1:length(TolL_Range)
    L = L_vec(i);
    for j = 1:length(TolR_Range)
        R = R_vec(j);
        actflow(j,i) = ( pi()*R*R*L/1E6 - B)*N;
    end
end

[LL RR] = meshgrid(L_vec,R_vec);

figure(1)
subplot(1,2,2)
contourf(LL,RR,actflow,50)
colorbar
c=colorbar
ylabel(c,'Actflow (ltrs/min)')
title('ActFlow output on nominal L and R within specified tols') 
xlabel('L')
ylabel('R')

%% This bigger picture %%
L_vec = linspace(20,60,50);
R_vec = linspace(20,60,50);
for i = 1:length(L_vec)
    L = L_vec(i);
    for j = 1:length(R_vec)
        R = R_vec(j);
        actflow(j,i) = ( pi()*R*R*L/1E6 - B)*N;
    end
end

[LL RR] = meshgrid(L_vec,R_vec);
figure(1)
subplot(1,2,1)
contourf(LL,RR,actflow,50)
colorbar
title('ActFlow output vs. L and R showing upper and lower performance bounds and tolerance box')
xlabel('L')
ylabel('R')
line([mu_L-tolL mu_L-tolL],[mu_R-tolR mu_R+tolR],'Color','r','LineWidth',1)
line([mu_L-tolL mu_L+tolL],[mu_R+tolR mu_R+tolR],'Color','r','LineWidth',1)
line([mu_L+tolL mu_L+tolL],[mu_R+tolR mu_R-tolR],'Color','r','LineWidth',1)
line([mu_L+tolL mu_L-tolL],[mu_R-tolR mu_R-tolR],'Color','r','LineWidth',1)
hold on
contour(LL,RR,actflow,[9,11],'Color','w')
c=colorbar
ylabel(c,'Actflow (ltrs/min)')