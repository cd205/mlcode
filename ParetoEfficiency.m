% Pareto cooling hole efficiency 
clear all
close all
clc

rho = 0.0
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

MinEff = linspace(0.7728,0.77345,8);
MinEff_LV = [0.772521428571429 0.772614285714286 0.772707142857143];
OPTVALSA_2 = load('OPTVALSA_2');
fvalA = load('fvalA_2');

OPTVALSA_2HD = load('OPTVALSA_2HD');
fvalA_2HD = load('fvalA_2HD');

OPTVALSB = load('OPTVALSB');
fvalB = load('fvalB');

OPTVALSB1e7 = load('OPTVALSB1e7');
fvalB1e7 = load('fvalB1e7');


%fvalA_7725 = load('fvalA_7725');
fvalB_7725 = load('fvalB_7725');
%fvalA_7726 = load('fvalA_7726');
fvalA_LV2 = load('fvalA_LV2')
fvalB_7726 = load('fvalB_7726');
%fvalA_7727 = load('fvalA_7727');
fvalB_7727 = load('fvalB_7727');
fvalA_LV = fvalA_LV2.fvalA_LV2;
fvalB_LV = [fvalB_7725.fvalB_7725, fvalB_7726.fvalB_7726, fvalB_7727.fvalB_LV];

fvalA_77289 = load('fvalA_77289');
fvalB_77289 = load('fvalB_77289');
fvalA_77299 = load('fvalA_77299');
fvalB_77299 = load('fvalB_77299');
fvalA_77308 = load('fvalA_77308');
fvalB_77308 = load('fvalB_77308');
fvalA_77317 = load('fvalA_77317');
fvalB_77317 = load('fvalB_77317');
fvalA_77326 = load('fvalA_77326');
fvalB_77326 = load('fvalB_77326');
fvalA_77336 = load('fvalA_77336');
fvalB_77336 = load('fvalB_77336');

fvalB_rr = load('fvalB_rr');

fvalA_HD = [fvalA_77289.fvalA,fvalA_77299.fvalA,fvalA_77308.fvalA,...
    fvalA_77317.fvalA,fvalA_77326.fvalA,fvalA_77336.fvalA];
fvalB_HD = [fvalB_77289.fvalB,fvalB_77299.fvalB,fvalB_77308.fvalB,...
    fvalB_77317.fvalB,fvalB_77326.fvalB,fvalB_77336.fvalB];

%% consolidate all the results into vectors
MINEFF = [MinEff_LV MinEff];
FVALA = [-1*fvalA_LV -1*fvalA.fvalA_2];
FVALB = [-1*fvalB_LV -1*fvalB.fvalB];
MEANSA = [fvalA_LV2.OPTVALSA_LV2; fvalA.OPTVALSA_2]
MEANSB = [fvalB_7725.OPTVALSB_7725; fvalB_7726.OPTVALSB_7726; fvalB_7727.OPTVALSB_LV; fvalB.OPTVALSB]

%% Correlated inputs
fvalA_CorrP8 = load('fvalA_CorrP8');
fvalB_CorrP8 = load('fvalB_CorrP8');

figure;
[AX,H1,H2] = plotyy(fvalA_CorrP8.MinEff,-1*fvalA_CorrP8.fvalA_CorrP8,...
    fvalB_CorrP8.MinEff,-1*fvalB_CorrP8.fvalB_CorrP8); grid on; hold on
[AX2,H21,H22] = plotyy(MINEFF,FVALA,MINEFF,FVALB); grid on; hold on
%H3 = plot(MinEff(2:5),-1*fvalA_HD(1:4),'kv','MarkerSize',8,'MarkerFaceColor',[0 0 0]);
%H3 = plot(fvalA_2HD.MinEff,-1*fvalA_2HD.fvalA_2HD,'kv','MarkerSize',8,'MarkerFaceColor',[0 0 0])
%[AX3,H31,H32] = plotyy(MinEff(2:7),fvalA_HD,MinEff(2:7),fvalB_HD)
set(AX(2),'XTickLabel',[]);set(AX2(2),'XTickLabel',[]); %set(AX3(2),'XTickLabel',[]) ; 
set(AX2(2),'YTickLabel',[]); %set(AX3(2),'YTickLabel',[])
set(get(AX(1),'Ylabel'),'String','Currency Units (Std. Production)','FontSize',15,'Color',[237 28 36]./255); 
set(get(AX(2),'Ylabel'),'String','Currency Units (OMS Production)','FontSize',15,'Color',[33 64 154]./255);
set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
set(H1,'LineStyle','-','LineWidth',2.5,'Color',[237 28 36]./255); 
set(H2,'LineStyle','-','LineWidth',2.5,'Color',[33 64 154]./255); hold on
set(H21,'LineStyle',':','LineWidth',7.5,'Color',[237 28 36]./255); 
set(H22,'LineStyle','-.','LineWidth',2.5,'Color',[33 64 154]./255);


%figure;
%plot(fvalB,'r-.'); grid on
figure(1)
plot(MinEff_LV,-1*fvalA_LV,'.')%MinEff_LV,-1*fvalB_LV,'.')

figure;
[AX,H1,H2] = plotyy(MINEFF,FVALA,MINEFF,FVALB); grid on; hold on
[AX2,H21,H22] = plotyy(MINEFF,FVALA,MINEFF,FVALB); grid on; hold on
%H3 = plot(MinEff(2:5),-1*fvalA_HD(1:4),'kv','MarkerSize',8,'MarkerFaceColor',[0 0 0]);
H3 = plot(fvalA_2HD.MinEff,-1*fvalA_2HD.fvalA_2HD,'kv','MarkerSize',8,'MarkerFaceColor',[0 0 0])
%[AX3,H31,H32] = plotyy(MinEff(2:7),fvalA_HD,MinEff(2:7),fvalB_HD)
set(AX(2),'XTickLabel',[]);set(AX2(2),'XTickLabel',[]); %set(AX3(2),'XTickLabel',[]) ; 
set(AX2(2),'YTickLabel',[]); %set(AX3(2),'YTickLabel',[])
%set(gca,'XTickLabel',[])
set(get(AX(1),'Ylabel'),'String','Currency Units (Std. Production)','FontSize',15,'Color',[237 28 36]./255); 
set(get(AX(2),'Ylabel'),'String','Currency Units (OMS Production)','FontSize',15,'Color',[33 64 154]./255);
set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
set(H1,'LineStyle','-.','LineWidth',2.5,'Color',[237 28 36]./255); 
set(H2,'LineStyle',':','LineWidth',2.5,'Color',[33 64 154]./255); hold on
set(H21,'LineStyle','+','LineWidth',7.5,'Color',[237 28 36]./255); 
set(H22,'LineStyle','o','LineWidth',2.5,'Color',[33 64 154]./255);

%plot(rho,Profit2,'k--','LineWidth',2.5,'Color',[.3 .3 .3])


Leg = legend([H1,H2,H3],'Standard Production','Optimal Mean Setting Production','Verification Points'); set(Leg,'FontSize',15)
set(gca,'FontSize',15)
xlabel('Minimum cooling effectiveness (\eta)');
format short
Errors = (abs(fvalA_2HD.fvalA_2HD-fvalA.fvalA_2(2:7))./fvalA_2HD.fvalA_2HD)*100


%% plot on response surface
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');
Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;
sig11 = 0.109687; sig22 = 0.102564;

n = 4
colormap Summer(6)
paints = colormap;

%% Define marginal distributions Case A - standard production
x = linspace(0,1,1000);
USLA_dia = 100%MEANSA(n,1)+MEANSA(n,3)*sig11;
USLA_ang = MEANSA(n,2)+MEANSA(n,4)*sig11;
TpdfA_dia = @(x) Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSA(n,1),sig11,...
    MEANSA(n,1)-MEANSA(n,3)*sig11,USLA_dia,USLA_dia,0);
TcdfA_dia = @(x) Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSA(n,1),sig11,...
    MEANSA(n,1)-MEANSA(n,3)*sig11,USLA_dia,USLA_dia,0);
TpdfA_ang = @(x) Fun_TruncatedNormalDist_Reversed_pdf(x,MEANSA(n,2),sig22,...
    MEANSA(n,2)-MEANSA(n,4)*sig22,USLA_ang,USLA_ang,0);
TcdfA_ang = @(x) Fun_TruncatedNormalDist_Reversed_cdf(x,MEANSA(n,2),sig22,...
    MEANSA(n,2)-MEANSA(n,4)*sig22,USLA_ang,USLA_ang,2);

% b = USLA_ang; a = MEANSA(n,2)-MEANSA(n,4)*sig11;  mu = MEANSA(n,2); sigma = sig11
% cdf = ((normcdf(b,mu,sigma) - normcdf(a,mu,sigma))./...
%             (normcdf(inf,mu,sigma) - normcdf(a,mu,sigma)))
% check =  ((normcdf(b,mu,sigma) - normcdf(a,mu,sigma))./...
%             (normcdf(inf,mu,sigma) - normcdf(a,mu,sigma)))

figure(11)
plot(x,TpdfA_dia(x),'-'); hold on; grid on
plot(x,TcdfA_dia(x),'c-');
plot(x,TpdfA_ang(x),'r-')
plot(x,TcdfA_ang(x),'m.')

figure(3)
% Plot prob contours
[XPLOT YPLOT] = meshgrid(Xplot,Xplot);
Z = copulapdf('Gaussian',[TcdfA_dia(XPLOT(:)) TcdfA_ang(YPLOT(:))],0)...
    .*TpdfA_dia(XPLOT(:)).*TpdfA_ang(YPLOT(:));
%Z = mvnpdf([XPLOT(:) YPLOT(:)],[MEANSA(n,1),MEANSA(n,2)],[sig11^2 0; 0 sig22^2]);
Z = reshape(Z,size(XPLOT)); 
[C1]= contourcs(Xplot,Xplot,Z,6);
[C2]= contour(Xplot,Xplot,Z,6);

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
for i=1:size(C1,1)
plot(C1(i).X,C1(i).Y,'-','Color',paints(i,:)); hold on
end
axis([0.1 0.9 0.1 0.9])
%clabel(C2,'manual','Color',[1 1 1],'FontSize',12)
%% Define marginal distributions Case B - Optimal Mean Setting
% find out the proportion of components that were manufactured using mean_1
% and the number that were reowrk and were centred around mean_2
[Profit,Eff35_intOMS,Eff35OMS,npnts1,npnts2] = funNCProfitDiaAng([MEANSB(n,1) MEANSB(n,2)],...
    MEANSB(n,3),sig11,sig22,rho,MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),1e6,Xplot,Eff35,MINEFF(n));
W1 = npnts1/1e6; 
W2 = npnts2/1e6;
x = linspace(0,1,1000);
USLB_dia = 100%MEANSB(n,1)+MEANSB(n,4)*sig11;
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
plot(x,TcdfB_ang(x),'m-.')
figure(4)
%% Plot prob contours

[XPLOT YPLOT] = meshgrid(Xplot,Xplot);
Z = copulapdf('Gaussian',[TcdfB_dia(XPLOT(:)) TcdfB_ang(YPLOT(:))],rho)...
    .*TpdfB_dia(XPLOT(:)).*TpdfB_ang(YPLOT(:));
%Z = mvnpdf([XPLOT(:) YPLOT(:)],[MEANSB(n,1),MEANSB(n,2)],[sig11^2 0; 0 sig22^2]);
Z = reshape(Z,size(XPLOT)); 
[C3]= contourcs(Xplot,Xplot,Z,6);
[C4]= contour(Xplot,Xplot,Z,6);

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
for i=1:size(C1,1)
plot(C3(i).X,C3(i).Y,'-','Color',paints(i,:)); hold on
end
%clabel(C4,'manual','Color',[1 1 1],'FontSize',12)
axis([0.1 0.9 0.1 0.9])

%% Performance variation

[Profit,Eff35_intStdProd,Eff35StdProd] = funNCProfitDiaAng([MEANSA(n,1) MEANSA(n,2)],...
    MEANSA(n,1),sig11,sig22,rho,MEANSA(n,3),MEANSA(n,3),MEANSA(n,4),1e6,Xplot,Eff35,MINEFF(n));

[Profit,Eff35_intOMS,Eff35OMS,npnts1,npnts2] = funNCProfitDiaAng([MEANSB(n,1) MEANSB(n,2)],...
    MEANSB(n,3),sig11,sig22,rho,MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),1e6,Xplot,Eff35,MINEFF(n));

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

%% Production Cost
[ProfitA,Eff35_int,Eff35,npnts1,npnts2,ProdCostA,PartsLeftA] = funNCProfitDiaAng([MEANSA(n,1) MEANSA(n,2)],...
    MEANSA(n,1),sig11,sig22,rho,MEANSA(n,3),MEANSA(n,3),MEANSA(n,4),1e6,Xplot,Eff35,MINEFF(n));
PartsLeftA
[ProfitB,Eff35_int,Eff35,npnts1,npnts2,ProdCostB,PartsLeftB] = funNCProfitDiaAng([MEANSB(n,1) MEANSB(n,2)],...
    MEANSB(n,3),sig11,sig22,rho,MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),1e6,Xplot,Eff35,MINEFF(n));
PartsLeftB
% x = linspace(0,1,100);
% TpdfA_dia = Fun_TruncatedNormalDist_pdf(x,MEANSA(n,1),sig11,...
%     MEANSA(n,1)-MEANSA(n,3)*sig11,MEANSA(n,1)+MEANSA(n,3)*sig11,...
%     MEANSA(n,1)+MEANSA(n,3)*sig11,1);
% TpdfA_ang = Fun_TruncatedNormalDist_pdf(x,MEANSA(n,2),sig11,...
%     MEANSA(n,2)-MEANSA(n,4)*sig11,MEANSA(n,2)+MEANSA(n,4)*sig11,...
%     MEANSA(n,2)+MEANSA(n,4)*sig11,0);
% 
% figure;
% plot(x,TpdfA_dia,'-'); grid on; hold on
% plot(x,TpdfA_ang,'r-'); 
% figure;
% hist(RV_DiaAng(:,1),50); hold on
% figure;
% hist(RV_DiaAng(:,2),50);
% %% Standard production details
% Xplot = load('Eff35DoE.Mat','Xplot');
% Eff35 = load('Eff35DoE.Mat','Eff35');
% 
% Xplot = Xplot.Xplot;
% Eff35 = Eff35.Eff35;
% 
% sig11 = 0.109687; sig22 = 0.102564;
% rho = 0.0; npnts = 1e6;
% for n = 1:length(FVALA)
% n
% [Profit1,NC,Eff,ProdCost1] = funNCProfitDiaAng_DETAIL([MEANSA(n,1) MEANSA(n,2)],MEANSA(n,1),sig11,sig22,...
%     rho,MEANSA(n,3),MEANSA(n,3),MEANSA(n,4),npnts,Xplot,Eff35,MINEFF(n));
% Profit_StandProd(n) = Profit1
% ProdCost_StandProd(n) = ProdCost1
% %% Standard production details
% [Profit2,NC,Eff,ProdCost2] = funNCProfitDiaAng_DETAIL([MEANSB(n,1) MEANSB(n,2)],MEANSB(n,3),sig11,sig22,...
%     rho,MEANSB(n,4),MEANSB(n,5),MEANSB(n,6),npnts,Xplot,Eff35,MINEFF(n));
% Profit_OMSProd(n) = Profit2
% ProdCost_OMSProd(n) = ProdCost2
% end
