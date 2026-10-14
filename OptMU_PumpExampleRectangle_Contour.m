clear all
close all
clc

%% Inputs 
aa = 23.9162;    % lower tolerance for L
bb = 25.9162;    % upper toleracne for L
cc = 28.6089;    % lower toleracne for R
dd = 30.6089;    % upper tolerance for R

%% Normailise data
min1 = aa;
max1 = bb;
min2 = cc;
max2 = dd;
a = 0+(aa-min1)*(1-0)/(max1-min1)
b = 0+(bb-min1)*(1-0)/(max1-min1)
c = 0+(cc-min2)*(1-0)/(max2-min2)
d = 0+(dd-min2)*(1-0)/(max2-min2)

num1 = 100
mu_L = linspace(0,1,num1);
mu_R = linspace(0,1,num1);
% mu_L_delta = 2.*(xxi-0.5); % Shift mean for Length
% mu_R_delta = 2.*(yyi-0.5); % Shift mean for Radius
% mu_L = mu_L_delta + 24.9162;     % Mean parameter for Length [0.4 0.6]
% mu_R = mu_R_delta + 29.6089;     % Mean parameter for Radius [0.4 0.6]

sigma_L = 0.2;
sigma_W = 0.2;
SIGMA = [sigma_L^2 0; 0 sigma_W^2];
ALPHA = [0 0];
start1 = tic;
nrows = length(mu_L);
ncols = length(mu_R);
parfor i = 1:ncols
    mytemp1 = zeros(nrows,1);
    for j = 1:length(mu_R)
        MU = [mu_L(i), mu_R(j)];
        [mytemp1(j)] = PumpCostDetailed_SNQuad2d(MU,SIGMA,ALPHA,a,b,c,d); 
    end
    MuCost(:,i) = mytemp1;
end
toc(start1)

figure(1)
contourf(mu_L,mu_R,MuCost,40,'LineStyle','none')
colorbar
xlabel('\Delta\mu - Length')
ylabel('\Delta\mu - Radius')
c = colorbar;
ylabel(c,'Pump Manufacturing Cost')
hold on
%% Find minimum 
minVal = min(min(MuCost))
[min_mu_L min_mu_R] = find(MuCost==minVal);
NormOpt_mu_L = mu_L(min_mu_L);
NormOpt_mu_R = mu_R(min_mu_R);
Opt_mu_L = NormOpt_mu_L*(max1-min1)+min1
Opt_mu_R = NormOpt_mu_R*(max2-min2)+min2

% L = linspace(0,1,60);
% W = linspace(0,1,60);
% prof=plot_dsn2_CDodd(L,W,MU,SIGMA,[5 5])

% xnodes = linspace(0,1,80);
% ynodes = linspace(0,1,80);
% [X Y] = meshgrid(xi,yi);
% g = gridfit(X,Y,SkewCost,xnodes,ynodes)