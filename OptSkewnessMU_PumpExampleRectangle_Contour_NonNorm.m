% clear all
% close all
% clc
% 
% %% Inputs 
% aa = 23.9162;    % lower tolerance for L
% bb = 25.9162;    % upper toleracne for L
% cc = 28.6089;    % lower toleracne for R
% dd = 30.6089;    % upper tolerance for R
% 
% %% Normailise data
% min1 = aa;
% max1 = bb;
% min2 = cc;
% max2 = dd;
% a = 0.3+(aa-min1)*(0.7-0.3)/(max1-min1);
% b = 0.3+(bb-min1)*(0.7-0.3)/(max1-min1);
% c = 0.3+(cc-min2)*(0.7-0.3)/(max2-min2);
% d = 0.3+(dd-min2)*(0.7-0.3)/(max2-min2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
clc

%% Inputs 
num1 = 9
num2 = 15
xi = linspace(0,1,num2);
yi = linspace(0,1,num2);
xxi = linspace(0,1,num1);
yyi = linspace(0,1,num1);
alpha_L = (6.*xi-3)-3;          % Skewness parameters for Length [-5,5]
alpha_R = (6.*yi-3)-3;          % Skewness parameters for Width [-5,5]
mu_L_delta = 0.2.*(xxi-0.5); % Shift mean for Length (-2)
mu_R_delta = 0.2.*(yyi-0.5); % Shift mean for Width  (+1)
mu_L = mu_L_delta + 0.5;     % Mean parameter for Length [0.2 0.4]
mu_R = mu_R_delta + 0.5;     % Mean parameter for Width [0.7 0.9]

a = 0.4;
b = 0.6;
c = 0.4;
d = 0.6;
sigma_L = 0.0201;
sigma_R = 0.0135;
SIGMA = [sigma_L^2 0; 0 sigma_R^2];

start1 = tic;
nrows = length(yi);
ncols = length(xi);
nnrows = length(yyi);
nncols = length(xxi);
for k = 1:nnrows
    disp(['k is ',num2str(k)])
    for l = 1:nncols
        MU = [mu_L(l) mu_R(k)];
        parfor i = 1:ncols
            mytemp1 = zeros(nrows,1);
            for j = 1:length(yi)
                ALPHA = [alpha_L(i), alpha_R(j)];
                [mytemp1(j)] = PumpCostDetailed_SNQuad2d(MU,SIGMA,ALPHA,a,b,c,d);
            end
            SkewCost(:,i) = mytemp1;
        end
        TotalCost{k,l} = SkewCost;
    end
end
       
toc(start1)
%% Find minimum
for i = 1:num1
    for j = 1:num1
        Mins(j,i) = min(min(TotalCost{i,j})); % find the mins for mu_L and mu_W
        Maxs(j,i) = max(max(TotalCost{i,j}));
    end
end
[min_mu_L min_mu_R] = find(Mins==min(min(Mins))); % find the mu_L and mu_W with the lowest cost
[min_alpha_R min_alpha_L] = find(TotalCost{min_mu_L,min_mu_R}==min(min(TotalCost{min_mu_L,min_mu_R})));
% find the skewness alpha_L and alpha_W values for min cost
MinCostVal = min(min(Mins));
MaxCostVal = max(max(Maxs));
opt_mu_L = mu_L(min_mu_L);
opt_mu_R = mu_R(min_mu_R);
opt_alpha_L = alpha_L(min_alpha_L);
opt_alpha_R = alpha_R(min_alpha_R);


%% Plotting
cc=0;
figure(1)
for m = num1:-1:1
    for v = 1:num1
        cc = cc + 1;
        A(cc) = subplot(num1,num1,cc);
        contourf(xi,yi,TotalCost{v,m},40,'LineStyle','none')
        hold on
        [numr numc] = find(TotalCost{v,m}==min(min(TotalCost{v,m})));
        mcL = xi(numr);
        mcR = yi(numc);
        plot(mcR,mcL,'g.','MarkerSize',20)
        hold on
        text(0.66,0.85,num2str(min(min(TotalCost{v,m}))),'FontSize',10,'color',[1 1 1])
        %set([A(cc)],'clim',[min(min(Mins)) max(max(Maxs))]);
        %set( findall(gca,'type','text') ,'FontUnits', 'Normalized');
    end
end
B = colorbar;
ylabel(B,'Cost')
set([A(1:cc)],'clim',[MinCostVal MaxCostVal]);
set(B, 'Position', [.87 .09 .0281 .8150])


for j = 1:cc
    p = get(A(j),'pos'); % get 4-element position vector for subplot 1
    p(1) = p(1) - 0.08;  % this is a vecotr [left, bottom, width, height]
    p(2) = p(2) - 0.03;  % resize this vecotr then replot it
    p(3) = p(3) + 0.018;  % p(1) = left,  p(2) = bottom
    p(4) = p(4) + 0.02;  % p(3) = width,  p(4) = height
    set(A(j),'pos',p)
    set(A(j), 'XTickLabel', [], 'XTick', [])
    set(A(j), 'YTickLabel', [], 'YTick', [])
    set(A(73), 'XTickLabel', [0 1], 'XTick', [0 1])
    set(A(73), 'YTickLabel', [0 1], 'YTick', [0 1])
end
text(0.5,-0.2,'1','FontSize',12,'color',[0 0 0])
text(-8.4,9.0,'1','FontSize',12,'color',[0 0 0])
text(-3.7,-0.25,'\mu_L','FontSize',12,'color',[0 0 0])
text(-8.5,4.8,'\mu_R','FontSize',12,'color',[0 0 0])
text(-7.9,-0.15,'\alpha_L','FontSize',12,'color',[0 0 0])
text(-8.452,0.44,'\alpha_R','FontSize',12,'color',[0 0 0])
%set( findall(gca,'type','text') ,'FontUnits', 'Normalized');
figure(2)
pdf_L = dsn([0:0.005:1],opt_mu_L,0.2,opt_alpha_L);
pdf_R = dsn([0:0.005:1],opt_mu_R,0.2,opt_alpha_R);
subplot(1,2,1)
plot([0:0.005:1],pdf_L,'b-','LineWidth',2)
grid on;
% set(gca,'Xcolor',[0.8 0.8 0.8]);  % This plots the grid
% set(gca,'Ycolor',[0.8 0.8 0.8]);  % line in grey but 
% Caxes = copyobj(gca,gcf);         % keeps the axis black
% set(Caxes, 'color', 'none', 'xcolor', 'k', 'xgrid', 'off', 'ycolor','k', 'ygrid','off');
hold on
line([0.5503 0.5503],[0 5],'color',[1 0 0],'LineWidth',1)
line([0.3 0.3],[0 5],'color',[0 0 0],'LineWidth',1,'LineStyle','--')
line([0.7 0.7],[0 5],'color',[0 0 0],'LineWidth',1,'LineStyle','--')
xlabel('L')
ylabel('density')
subplot(1,2,2)
plot([0:0.005:1],pdf_R,'b-','LineWidth',2)
grid on;
% set(gca,'Xcolor',[0.8 0.8 0.8]);  % This plots the grid
% set(gca,'Ycolor',[0.8 0.8 0.8]);  % line in grey but 
% Caxes = copyobj(gca,gcf);         % keeps the axis black
% set(Caxes, 'color', 'none', 'xcolor', 'k', 'xgrid', 'off', 'ycolor','k', 'ygrid','off');
hold on
line([0.4321 0.4321],[0 5],'color',[1 0 0],'LineWidth',1)
line([0.3 0.3],[0 5],'color',[0 0 0],'LineWidth',1,'LineStyle','--')
line([0.7 0.7],[0 5],'color',[0 0 0],'LineWidth',1,'LineStyle','--')

xlabel('R')
ylabel('density')
% contourf(xi,yi,SkewCost,80,'LineStyle','none')
% colorbar
% xlabel('\alpha - Length')
% ylabel('\alpha - Width')
% cc = colorbar;
% ylabel(cc,'Bar Manufacturing Cost')


% xnodes = linspace(0,1,80);
% ynodes = linspace(0,1,80);
% [X Y] = meshgrid(xi,yi);
% g = gridfit(X,Y,SkewCost,xnodes,ynodes)