% Pareto cooling hole efficiency 
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

%_7727.OPTVALSB_LV; fvalB.OPTVALSB]

%% Correlated inputs
fvalA_CorrP8 = load('fvalA_CorrsP8_New');
fvalB_CorrP8 = load('fvalB_CorrsP8');
rho = [-0.8 0.8];
fvalA_CorrN8 = load('fvalA_CorrsN8_New');
fvalB_CorrN8 = load('fvalB_CorrsN8');

MEANSA = [fvalA_CorrN8.OPTVALSA_CorrsN8 ; fvalA_CorrP8.OPTVALSA_CorrsP8]

MEANSB = [fvalB_CorrN8.OPTVALSB_CorrsN8 ; fvalB_CorrP8.OPTVALSB_CorrsP8]
n = 2

%% plot on response surface
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');
Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;
sig11 = 0.109687; sig22 = 0.102564;
SIGMA = [sig11^2 rho(n)*sig11*sig22; rho(n)*sig11*sig22  sig22^2]
colormap Summer(8)
paints = colormap;

%% Define marginal distributions Case A - standard production
x = linspace(0,1,500);
USLA_dia = 100;%MEANSA(n,1)+MEANSA(n,3)*sig11;
USLA_ang = MEANSA(n,2)+MEANSA(n,4)*sig22;
TpdfA_dia = @(x) Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSA(n,1),sig11,...
    MEANSA(n,1)-MEANSA(n,3)*sig11,USLA_dia,USLA_dia,1);
TcdfA_dia = @(x) Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSA(n,1),sig11,...
    MEANSA(n,1)-MEANSA(n,3)*sig11,USLA_dia,USLA_dia,1);
TpdfA_ang = @(x) Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSA(n,2),sig22,...
    MEANSA(n,2)-MEANSA(n,4)*sig22,USLA_ang,USLA_ang,0);
TcdfA_ang = @(x) Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSA(n,2),sig22,...
    MEANSA(n,2)-MEANSA(n,4)*sig22,USLA_ang,USLA_ang,2);
figure(11)
plot(x,TpdfA_dia(x),'-'); hold on; grid on
plot(x,TcdfA_dia(x),'c-');
plot(x,TpdfA_ang(x),'r-')
plot(x,TcdfA_ang(x),'m-')

% Plot prob contours
[XPLOT YPLOT] = meshgrid(x,x);
FunZ = @(x,y) copulapdf('Gaussian',[TcdfA_dia(x') TcdfA_ang(y')],rho(n))...
    .*TpdfA_dia(x').*TpdfA_ang(y');
%Z = copulapdf('Gaussian',[TcdfA_dia(XPLOT(:)) TcdfA_ang(YPLOT(:))],rho(n))...
%    .*TpdfA_dia(XPLOT(:)).*TpdfA_ang(YPLOT(:));
[Z IXV]= tmvnorm_2var(XPLOT,YPLOT,[MEANSA(n,1) MEANSA(n,2)],sig11,sig22,rho(n),...
    [MEANSA(n,1)-MEANSA(n,3)*sig11,MEANSA(n,2)-MEANSA(n,4)*sig22],...
    [USLA_dia,USLA_ang]);
%Z = mvnpdf([XPLOT(:) YPLOT(:)],[MEANSA(n,1),MEANSA(n,2)],[sig11^2 0; 0 sig22^2]);
Z = reshape(Z,size(XPLOT)); 
figure(3);
[C1]= contourcs(x,x,Z,51);
[C2]= contour(x,x,Z,51);
%figure(99)
%surf(x,x,Z,'EdgeColor', 'none')


figure(3);
contourf(Xplot,Xplot,Eff35,100); hold on; grid on
colorbar
plot(MEANSA(n,1),MEANSA(n,2),'g.','Markersize',25)
line([MEANSA(n,1)-MEANSA(n,3)*sig11 MEANSA(n,1)-MEANSA(n,3)*sig11],[0 1],'Color',[1 1 1],'linewidth',2)
line([MEANSA(n,1)+MEANSA(n,3)*sig11 MEANSA(n,1)+MEANSA(n,3)*sig11],[0 1],'Color',[1 1 1],'linewidth',2)
line([0 1],[MEANSA(n,2)-MEANSA(n,4)*sig11 MEANSA(n,2)-MEANSA(n,4)*sig11],'Color',[1 1 1],'linewidth',2)
line([0 1],[MEANSA(n,2)+MEANSA(n,4)*sig11 MEANSA(n,2)+MEANSA(n,4)*sig11],'Color',[1 1 1],'linewidth',2)
set(gca,'FontSize',15)
xlabel('Diameter (d)')
ylabel('Inclination angle (\alpha)')
colormap jet
figure(3)
% %%STANDARD CONTOURS
% clabel(C2,'Color',[1 1 1],'FontSize',12)
% for i=1:size(C1,1)
% plot(C1(i).X,C1(i).Y,'-','Color',paints(i,:)); hold on
% end
%% ALTERNATIVE CONTOURS
count = 1;
cvec = [1 11 21 31 41 51];
Klen = 0;
for i=1:length(cvec)
    KX = [C1(cvec(i)).Level, C1(cvec(i)).X];
    KY = [size(C1(cvec(i)).X,2), C1(cvec(i)).Y];
    K(1,Klen+1:Klen+KY(1)+1) = KX;
    K(2,Klen+1:Klen+KY(1)+1) = KY;
    Klen = size(K,2); % this is the length of the KX and KY vecots already written to K
    % K(2,:) = C1(1).Y
    %C1(i)
    plot(C1(cvec(i)).X,C1(cvec(i)).Y,'-','Color',paints(count,:)); hold on
    count = count+1;
end
%clabel(K,'Color',[1 1 1],'FontSize',12)
%clabel(K,'manual','Color',[1 1 1],'FontSize',12)

axis([0.1 0.9 0.1 0.9])

%% Define marginal distributions Case B - Optimal Mean Setting
% find out the proportion of components that were manufactured using mean_1
% and the number that were reowrk and were centred around mean_2
MINEFF = 0.773357142857143
[Profit,Eff35_intOMS,Eff35OMS,npnts1,npnts2] = funNCProfitDiaAng([MEANSB(n,1) MEANSB(n,2)],...
    MEANSB(n,3),sig11,sig22,rho(n),MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),1e6,Xplot,Eff35,MINEFF);
W1 = npnts1/1e6
W2 = npnts2/1e6
x = linspace(0,1,1000);
USLB_dia = 100%MEANSB(n,1)+MEANSB(n,5)*sig11;
USLB_ang = MEANSB(n,2)+MEANSB(n,6)*sig22; 
TpdfB_dia = @(x) W1.*(Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSB(n,1),sig11,...
    MEANSB(n,1)-MEANSB(n,4)*sig11,USLB_dia,USLB_dia,1)) + ...
                 W2.*(Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSB(n,3),sig11,...
    MEANSB(n,1)-MEANSB(n,4)*sig11,USLB_dia,USLB_dia,1));
TcdfB_dia = @(x) W1.*(Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSB(n,1),sig11,...
    MEANSB(n,1)-MEANSB(n,4)*sig11,USLB_dia,USLB_dia,1)) + ...
                 W2.*(Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSB(n,3),sig11,...
    MEANSB(n,1)-MEANSB(n,4)*sig11,USLB_dia,USLB_dia,1));
TpdfB_ang = @(x) Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSB(n,2),sig22,...
   MEANSB(n,2)-MEANSB(n,6)*sig22,USLB_ang,USLB_ang,0);
TcdfB_ang = @(x) Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSB(n,2),sig22,...
   MEANSB(n,2)-MEANSB(n,6)*sig22,USLB_ang,USLB_ang,2);
figure(12)
plot(x,TpdfB_dia(x),'-'); hold on; grid on
plot(x,TcdfB_dia(x),'c-');
plot(x,TpdfB_ang(x),'r-')
plot(x,TcdfB_ang(x),'m-')
figure(4)
%% Plot prob contours

[XPLOT YPLOT] = meshgrid(x,x);
%Z = copulapdf('Gaussian',[TcdfB_dia(XPLOT(:)) TcdfB_ang(YPLOT(:))],rho(n))...
%    .*TpdfB_dia(XPLOT(:)).*TpdfB_ang(YPLOT(:));
%Z = mvnpdf([XPLOT(:) YPLOT(:)],[MEANSB(n,1),MEANSB(n,2)],[sig11^2 0; 0 sig22^2]);
[Z_mu1] = W1.*(tmvnorm_2var(XPLOT,YPLOT,[MEANSB(n,1) MEANSB(n,2)],sig11,sig22,rho(n),...
    [MEANSB(n,1)-MEANSB(n,4)*sig11,MEANSB(n,2)-MEANSB(n,6)*sig22],...
    [USLA_dia,USLB_ang]));
[Z_mu2] = W2.*(tmvnorm_2var(XPLOT,YPLOT,[MEANSB(n,3) MEANSB(n,2)],sig11,sig22,rho(n),...
    [MEANSB(n,1)-MEANSB(n,4)*sig11,MEANSB(n,2)-MEANSB(n,6)*sig22],...
    [USLA_dia,USLB_ang]));
Z = [Z_mu1 + Z_mu2];
Z = reshape(Z,size(XPLOT)); 
figure(4)
[C3]= contourcs(x,x,Z,51);
[C4]= contour(x,x,Z,51);


figure(4);
contourf(Xplot,Xplot,Eff35,100); hold on; grid on
colorbar
plot(MEANSB(n,1),MEANSB(n,2),'g.','Markersize',25)
plot(MEANSB(n,3),MEANSB(n,2),'g*','Markersize',12)
line([MEANSB(n,1)-MEANSB(n,4)*sig22 MEANSB(n,1)-MEANSB(n,4)*sig22],[0 1],'Color',[1 1 1],'linewidth',2)
line([MEANSB(n,1)+MEANSB(n,5)*sig22 MEANSB(n,1)+MEANSB(n,5)*sig22],[0 1],'Color',[1 1 1],'linewidth',2)
line([0 1],[MEANSB(n,2)-MEANSB(n,6)*sig22 MEANSB(n,2)-MEANSB(n,6)*sig22],'Color',[1 1 1],'linewidth',2)
line([0 1],[MEANSB(n,2)+MEANSB(n,6)*sig22 MEANSB(n,2)+MEANSB(n,6)*sig22],'Color',[1 1 1],'linewidth',2)
set(gca,'FontSize',15)
xlabel('Diameter (d)')
ylabel('Inclination angle (\alpha)')
% % STANDARD CONTOURS 
% for i=1:size(C3,1)
% plot(C3(i).X,C3(i).Y,'-','Color',paints(i,:)); hold on
% end
% ALTERNATIVE CONTOURS
count = 1;
cvec = [1 11 21 31 41 51];
Klen = 0; clear Kx; clear KY; clear K
for i=1:length(cvec)
    KX = [C3(cvec(i)).Level, C3(cvec(i)).X];
    KY = [size(C3(cvec(i)).X,2), C3(cvec(i)).Y];
    K(1,Klen+1:Klen+KY(1)+1) = KX;
    K(2,Klen+1:Klen+KY(1)+1) = KY;
    Klen = size(K,2); % this is the length of the KX and KY vecots already written to K
    % K(2,:) = C1(1).Y
    %C1(i)
    plot(C3(cvec(i)).X,C3(cvec(i)).Y,'-','Color',paints(count,:)); hold on
    count = count+1;
end
%clabel(K,'Color',[1 1 1],'FontSize',12)
%clabel(K,'manual','Color',[1 1 1],'FontSize',12)
axis([0.1 0.9 0.1 0.9])


%% Production Cost
[ProfitA,Eff35_int,Eff35,npnts1,npnts2,ProdCostA] = funNCProfitDiaAng([MEANSA(n,1) MEANSA(n,2)],...
    MEANSA(n,1),sig11,sig22,rho(n),MEANSA(n,3),MEANSA(n,3),MEANSA(n,4),1e6,Xplot,Eff35,MINEFF);

[ProfitB,Eff35_int,Eff35,npnts1,npnts2,ProdCostB] = funNCProfitDiaAng([MEANSB(n,1) MEANSB(n,2)],...
    MEANSB(n,3),sig11,sig22,rho(n),MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),1e6,Xplot,Eff35,MINEFF);
ProfitA = ProfitA
ProdCostA=ProdCostA
ProfitB = ProfitB
ProdCostB=ProdCostB


%% Performance variation

[Profit,Eff35_intStdProd,Eff35StdProd,npntsa,npntsb] = funNCProfitDiaAng([MEANSA(n,1) MEANSA(n,2)],...
    MEANSA(n,1),sig11,sig22,rho(n),MEANSA(n,3),MEANSA(n,3),MEANSA(n,4),1e6,Xplot,Eff35,MINEFF(1));

[Profit,Eff35_intOMS,Eff35OMS,npnts1,npnts2] = funNCProfitDiaAng([MEANSB(n,1) MEANSB(n,2)],...
    MEANSB(n,3),sig11,sig22,rho(n),MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),1e6,Xplot,Eff35,MINEFF(1));

figure;
hist(Eff35_intStdProd,100); MH = max(hist(Eff35_intStdProd,100));
MeanStdProd = mean(Eff35_intStdProd(isfinite(Eff35_intStdProd(:))))
%ModeStdProd = mode(Eff35_intStdProd(isfinite(Eff35_intStdProd(:))))
h = findobj(gca,'Type','patch');
set(h,'FaceColor','r','EdgeColor','k','facealpha',1)
line([MeanStdProd MeanStdProd],[0 MH],'color',[1 0 0],'Linewidth',2.5,'LineStyle','-.'); 
%line([ModeStdProd ModeStdProd],[0 MH],'color',[1 0 0],'Linewidth',2.5,'LineStyle',':'); 
hold on

hist(Eff35_intOMS,100); grid on
MeanOMS = mean(Eff35_intOMS(isfinite(Eff35_intOMS(:))))
h = findobj(gca,'Type','patch');
set(h,'facealpha',0.5);
line([MeanOMS MeanOMS],[0 MH],'color',[0 0 1],'Linewidth',2.5,'LineStyle','-.'); 
axis([0.7728 0.7737 0 MH])
set(gca,'FontSize',15)
xlabel('Cooling Effectiveness (\eta)')
ylabel('Number of Components')
legend('Std. Production','Std. Production Mean \eta','Optimal Mean Setting','Optimal Mean Setting Mean \eta')

% 
% % x = linspace(0,1,100);
% % TpdfA_dia = Fun_TruncatedNormalDist_pdf(x,MEANSA(n,1),sig11,...
% %     MEANSA(n,1)-MEANSA(n,3)*sig11,MEANSA(n,1)+MEANSA(n,3)*sig11,...
% %     MEANSA(n,1)+MEANSA(n,3)*sig11,1);
% % TpdfA_ang = Fun_TruncatedNormalDist_pdf(x,MEANSA(n,2),sig11,...
% %     MEANSA(n,2)-MEANSA(n,4)*sig11,MEANSA(n,2)+MEANSA(n,4)*sig11,...
% %     MEANSA(n,2)+MEANSA(n,4)*sig11,0);
% % 
% % figure;
% % plot(x,TpdfA_dia,'-'); grid on; hold on
% % plot(x,TpdfA_ang,'r-'); 
% % figure;
% % hist(RV_DiaAng(:,1),50); hold on
% % figure;
% % hist(RV_DiaAng(:,2),50);
% % %% Standard production details
% % Xplot = load('Eff35DoE.Mat','Xplot');
% % Eff35 = load('Eff35DoE.Mat','Eff35');
% % 
% % Xplot = Xplot.Xplot;
% % Eff35 = Eff35.Eff35;
% % 
% % sig11 = 0.109687; sig22 = 0.102564;
% % rho = 0.0; npnts = 1e6;
% % for n = 1:length(FVALA)
% % n
% % [Profit1,NC,Eff,ProdCost1] = funNCProfitDiaAng_DETAIL([MEANSA(n,1) MEANSA(n,2)],MEANSA(n,1),sig11,sig22,...
% %     rho,MEANSA(n,3),MEANSA(n,3),MEANSA(n,4),npnts,Xplot,Eff35,MINEFF(n));
% % Profit_StandProd(n) = Profit1
% % ProdCost_StandProd(n) = ProdCost1
% % %% Standard production details
% % [Profit2,NC,Eff,ProdCost2] = funNCProfitDiaAng_DETAIL([MEANSB(n,1) MEANSB(n,2)],MEANSB(n,3),sig11,sig22,...
% %     rho,MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),npnts,Xplot,Eff35,MINEFF(n));
% % Profit_OMSProd(n) = Profit2
% % ProdCost_OMSProd(n) = ProdCost2
% % end
