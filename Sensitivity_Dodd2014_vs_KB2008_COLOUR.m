
%Compare sensitivity of Dodd [2014] with K&B [2008]

clear all
close all
clc
SP = 120;
PC = 45;
RC = [15 12 20];
SC = [8 9 11 14];
%RC = [0 30 24 40];
%SC = [16 18 22 28];
sig11 = 1.0;
sig22 = 1.0;
SIGMA = [sig11^2 0; 0 sig22^2]
Lx = 8;
Ly = 13;
Ux = 12;
Uy = 17;
num = 30


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
%% Test for increased Scrap Cost
Ratio = linspace(1,5,num);
for i = 1:length(Ratio)
    % K and B 2008 method
    % First find optimal means for this scrap cost
    FUN1 = @(MU) -1*EP_KandB2008(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC*(Ratio(i)),RC);
    x0 = [10 15];
    options = optimset('TolFun',1e-15,'TolX',1e-12);
    MU_opt_vec1 = fminsearchcon(FUN1,x0,[Lx Ly],[Ux Uy],[],[],[],options);
    means1(i,:) = MU_opt_vec1 ;
    EP1(i) = -1*FUN1(MU_opt_vec1);
    
    
    % Dodd 2014 method
    % First find optimal means for this scrap cost
    FUN2 = @(MU) -1*EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC*(Ratio(i)),RC);
    x0 = [10 15];
    options = optimset('TolFun',1e-15,'TolX',1e-12);
    MU_opt_vec2 = fminsearchcon(FUN2,x0,[Lx Ly],[Ux Uy],[],[],[],options);
    means2(i,:) = MU_opt_vec2;
    EP2(i) = -1*FUN2(MU_opt_vec2);
    EP2c(i) = EP_Dodd2014(MU_opt_vec1,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC*(Ratio(i)),RC);
    [EPCheck(i) FeedIns(i,:)] = EP_Dodd2014_NonAutomated(means2(i,:),SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
end
figure;
detlaEP = EP2-EP1;
deltaMU1 = means2(:,1)-means1(:,1);
deltaMU2 = means2(:,2)-means1(:,2);
%plotyy(Ratio,EP2-EP1,Ratio,means2-means1); 
[AX,H1,H2] = plotyy(Ratio,deltaMU1,Ratio,detlaEP); hold on; grid on
set(AX(2),'XTickLabel',[])
%set(gca,'XTickLabel',[])
set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
set(get(AX(2),'Ylabel'),'String','\Delta E(PR)','FontSize',15,'Color',[0 0 0]);
set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
set(H1,'LineStyle','-','LineWidth',2.5,'Color',darkblue,'Marker','+','MarkerSize',10); 
set(H2,'LineStyle','-','LineWidth',2.5,'Color',darkgreen,'Marker','o','MarkerSize',7); 
plot(Ratio,deltaMU2,'k-','LineWidth',2.5,'Color',lightblue,'Marker','*','MarkerSize',10); 
Leg = legend('$$\Delta   \tilde{\mu}_{x_1}$$','$$\Delta \tilde{\mu}_{x_2}$$','$$\Delta E(PR)$$'); 
set(Leg,'FontSize',20);
set(Leg,'Interpreter','latex'); set(gca,'FontSize',15);
xlabel('Scrap Cost Ratio');

y1 = FeedIns(:,1); y2 = FeedIns(:,2); y3 = FeedIns(:,3);
y4 = FeedIns(:,4); y5 = FeedIns(:,5); y6 = FeedIns(:,6);
figure;
%[AX,H1,H2] = plotyy(rho,[y1.'y2.'],rho,FeedIns(:,4)); grid on
[AX, H1, H2] = plotyy(Ratio, [y1 y2 y3],Ratio,[y4 y5 y6]); grid on
% [AX,H5,H6] = plotyy(rho,FeedIns(:,3:3),rho,FeedIns(:,6:6)); hold on;
set(AX(2),'XTickLabel',[])
% %set(gca,'XTickLabel',[])
set(get(AX(1),'Ylabel'),'String','Case I terms (Probability)','FontSize',15,'Color',[0 0 0]); 
set(get(AX(2),'Ylabel'),'String','Case II terms (Probability)','FontSize',15,'Color',[0 0 0]);
set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
set(H1(1),'LineStyle','-','LineWidth',2.5,'Color',lightblue,'Marker','x','MarkerSize',10); 
set(H1(2),'LineStyle','-','LineWidth',2.5,'Color',darkblue,'Marker','d','MarkerSize',5); 
set(H1(3),'LineStyle','-','LineWidth',2.5,'Color',purple,'Marker','s','MarkerSize',5); 
set(H2(1),'LineStyle','-.','LineWidth',2.5,'Color',red,'Marker','x','MarkerSize',10);
set(H2(2),'LineStyle','-.','LineWidth',2.5,'Color',darkred,'Marker','d','MarkerSize',7); 
set(H2(3),'LineStyle','-.','LineWidth',2.5,'Color',orange,'Marker','s','MarkerSize',7); 
% set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.005:max([max(deltaMU1),max(deltaMU2)])])
Leg = legend('$$\mbox{Case II}: D_{2,S}$$','$$\mbox{Case II}: D_{3,S}$$','$$\mbox{Case II}: D_{4,S}$$','$$\mbox{Case I}: f_{2,S}$$','$$\mbox{Case I}: f_{3,S}$$','$$\mbox{Case I}: f_{4,S}$$'); set(Leg,'FontSize',15);
set(Leg,'FontSize',20);
set(Leg,'Interpreter','latex'); set(gca,'FontSize',15);
xlabel('Scrap Cost Ratio');


% %% Test for increased Rework Cost
% Ratio = linspace(1,5,num);
% for i = 1:length(Ratio)
%     % K and B 2008 method
%     % First find optimal means for this scrap cost
%     FUN1 = @(MU) -1*EP_KandB2008(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC*(Ratio(i)));
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec1 = fminsearchcon(FUN1,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means1(i,:) = MU_opt_vec1 ;
%     EP1(i) = -1*FUN1(MU_opt_vec1);
%     
%     
%     % Dodd 2014 method
%     % First find optimal means for this scrap cost
%     FUN2 = @(MU) -1*EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC*(Ratio(i)));
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec2 = fminsearchcon(FUN2,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means2(i,:) = MU_opt_vec2;
%     EP2(i) = -1*FUN2(MU_opt_vec2);
%     EP2c(i) = EP_Dodd2014(MU_opt_vec1,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC*(Ratio(i)));
% end
% figure;
% detlaEP = EP2-EP1;
% deltaMU1 = means2(:,1)-means1(:,1);
% deltaMU2 = means2(:,2)-means1(:,2);
% %plotyy(Ratio,EP2-EP1,Ratio,means2-means1); 
% [AX,H1,H2] = plotyy(Ratio,deltaMU1,Ratio,detlaEP); hold on; grid on
% set(AX(2),'XTickLabel',[])
% %set(gca,'XTickLabel',[])
% set(get(AX(2),'Ylabel'),'String','\Delta E(PR)','FontSize',15,'Color',[0 0 0]);
% set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
% set(H1,'LineStyle',':','LineWidth',2.5,'Color',[0.3 0.3 0.3]); 
% set(H2,'LineStyle','-','LineWidth',2.5,'Color',[0.4 0.4 0.4])
% plot(Ratio,deltaMU2,'k--','LineWidth',2.5,'Color',[0 0 0])
% set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.001:max([max(deltaMU1),max(deltaMU2)])])
% Leg = legend('\Delta\mu_{X_1}','\Delta\mu_{X_2}','\Delta E(PR)'); set(Leg,'FontSize',15)
% set(gca,'FontSize',15)
% xlabel('Rework Cost Ratio');
% 
% %% Test for increased Selling Proce
% Ratio = linspace(1,5,num);
% for i = 1:length(Ratio)
%     % K and B 2008 method
%     % First find optimal means for this scrap cost
%     FUN1 = @(MU) -1*EP_KandB2008(MU,SIGMA,Lx,Ly,Ux,Uy,SP*(Ratio(i)),PC,SC,RC);
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec1 = fminsearchcon(FUN1,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means1(i,:) = MU_opt_vec1 ;
%     EP1(i) = -1*FUN1(MU_opt_vec1);
%     
%     
%     % Dodd 2014 method
%     % First find optimal means for this scrap cost
%     FUN2 = @(MU) -1*EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP*(Ratio(i)),PC,SC,RC);
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec2 = fminsearchcon(FUN2,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means2(i,:) = MU_opt_vec2;
%     EP2(i) = -1*FUN2(MU_opt_vec2);
%     EP2c(i) = EP_Dodd2014(MU_opt_vec1,SIGMA,Lx,Ly,Ux,Uy,SP*(Ratio(i)),PC,SC,RC);
% end
% figure;
% detlaEP = EP2-EP1;
% deltaMU1 = means2(:,1)-means1(:,1);
% deltaMU2 = means2(:,2)-means1(:,2);
% %plotyy(Ratio,EP2-EP1,Ratio,means2-means1); 
% [AX,H1,H2] = plotyy(Ratio,deltaMU1,Ratio,detlaEP); hold on; grid on
% set(AX(2),'XTickLabel',[])
% %set(gca,'XTickLabel',[])
% set(get(AX(2),'Ylabel'),'String','\Delta E(PR)','FontSize',15,'Color',[0 0 0]);
% set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
% set(H1,'LineStyle',':','LineWidth',2.5,'Color',[0.3 0.3 0.3]); 
% set(H2,'LineStyle','-','LineWidth',2.5,'Color',[0.4 0.4 0.4])
% plot(Ratio,deltaMU2,'k--','LineWidth',2.5,'Color',[0 0 0])
% set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.001:max([max(deltaMU1),max(deltaMU2)])])
% Leg = legend('\Delta\mu_{X_1}','\Delta\mu_{X_2}','\Delta E(PR)'); set(Leg,'FontSize',15)
% set(gca,'FontSize',15)
% xlabel('Selling Price Ratio');

% %% Test for increased variance
% Ratio = linspace(1,2,num);
% for i = 1:length(Ratio)
%     % K and B 2008 method
%     % First find optimal means for this scrap cost
%     sig11 = Ratio(i)*1.0;
%     sig22 = Ratio(i)*1.0;
%     SIGMA = [sig11^2 0; 0 sig22^2];
%     FUN1 = @(MU) -1*EP_KandB2008(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC);
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec1 = fminsearchcon(FUN1,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means1(i,:) = MU_opt_vec1 ;
%     EP1(i) = -1*FUN1(MU_opt_vec1);
%     
%     
%     % Dodd 2014 method
%     % First find optimal means for this scrap cost
%     FUN2 = @(MU) -1*EP_Dodd2014(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC);
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec2 = fminsearchcon(FUN2,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means2(i,:) = MU_opt_vec2;
%     EP2(i) = -1*FUN2(MU_opt_vec2);
%     [EPCheck(i) FeedIns(i,:)] = EP_Dodd2014_NonAutomated(means2(i,:),SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
% end
% figure;
% detlaEP = EP2-EP1;
% deltaMU1 = means2(:,1)-means1(:,1);
% deltaMU2 = means2(:,2)-means1(:,2);
% %plotyy(Ratio,EP2-EP1,Ratio,means2-means1); 
% [AX,H1,H2] = plotyy(Ratio,deltaMU1,Ratio,detlaEP); hold on; grid on
% set(AX(2),'XTickLabel',[])
% %set(gca,'XTickLabel',[])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(get(AX(2),'Ylabel'),'String','\Delta E(PR)','FontSize',15,'Color',[0 0 0]);
% set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
% set(H1,'LineStyle','-','LineWidth',2.5,'Color',darkblue,'Marker','+','MarkerSize',10); 
% set(H2,'LineStyle','-','LineWidth',2.5,'Color',darkgreen,'Marker','o','MarkerSize',7); 
% plot(Ratio,deltaMU2,'-','LineWidth',2.5,'Color',lightblue,'Marker','*','MarkerSize',10); 
% set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.02:max([max(deltaMU1),max(deltaMU2)])])
% Leg = legend('$$\Delta \tilde{\mu}_{x_1}$$','$$\Delta \tilde{\mu}_{x_2}$$','$$\Delta E(PR)$$'); 
% set(Leg,'FontSize',20);
% set(Leg,'Interpreter','latex'); set(gca,'FontSize',15);
% xlabel('Standard deviaiton of process (\sigma)');
% 
% y1 = FeedIns(:,1); y2 = FeedIns(:,2); y3 = FeedIns(:,3);
% y4 = FeedIns(:,4); y5 = FeedIns(:,5); y6 = FeedIns(:,6);
% figure;
% %[AX,H1,H2] = plotyy(rho,[y1.'y2.'],rho,FeedIns(:,4)); grid on
% [AX, H1, H2] = plotyy(Ratio, [y1 y2 y3],Ratio,[y4 y5 y6]); grid on
% % [AX,H5,H6] = plotyy(rho,FeedIns(:,3:3),rho,FeedIns(:,6:6)); hold on;
% set(AX(2),'XTickLabel',[])
% % %set(gca,'XTickLabel',[])
% set(get(AX(1),'Ylabel'),'String','Case I terms (Probability)','FontSize',15,'Color',[0 0 0]); 
% set(get(AX(2),'Ylabel'),'String','Case II terms (Probability)','FontSize',15,'Color',[0 0 0]);
% set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
% set(H1(1),'LineStyle','-','LineWidth',2.5,'Color',lightblue,'Marker','x','MarkerSize',10); 
% set(H1(2),'LineStyle','-','LineWidth',2.5,'Color',darkblue,'Marker','d','MarkerSize',5); 
% set(H1(3),'LineStyle','-','LineWidth',2.5,'Color',purple,'Marker','s','MarkerSize',5); 
% set(H2(1),'LineStyle','-.','LineWidth',2.5,'Color',red,'Marker','x','MarkerSize',10);
% set(H2(2),'LineStyle','-.','LineWidth',2.5,'Color',darkred,'Marker','d','MarkerSize',7); 
% set(H2(3),'LineStyle','-.','LineWidth',2.5,'Color',orange,'Marker','s','MarkerSize',7); 
% % set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% % set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% % set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.005:max([max(deltaMU1),max(deltaMU2)])])
% Leg = legend('$$\mbox{Case II}: D_{2,S}$$','$$\mbox{Case II}: D_{3,S}$$','$$\mbox{Case II}: D_{4,S}$$','$$\mbox{Case I}: f_{2,S}$$','$$\mbox{Case I}: f_{3,S}$$','$$\mbox{Case I}: f_{4,S}$$'); set(Leg,'FontSize',15);
% set(Leg,'Interpreter','latex'); set(gca,'FontSize',15);
% xlabel('Standard deviaiton of process (\sigma)');
% 

% 
% %% Test for increased correlation
% rho = linspace(-0.9999,0.9999,num);
% for i = 1:length(rho)
%     %% K and B 2008 method
%     % First find optimal means for this scrap cost
%     sig11 = 1.0;
%     sig22 = 1.0;
%     SIGMA = [sig11^2 rho(i)*sig11*sig22; rho(i)*sig11*sig22 sig22^2];
%     FUN1 = @(MU) -1*EP_KandB2008(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC);
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec1 = fminsearchcon(FUN1,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means1(i,:) = MU_opt_vec1 ;
%     EP1(i) = -1*FUN1(MU_opt_vec1);
%     
%     
%     %% Dodd 2014 method
%     % First find optimal means for this scrap cost
%     FUN2 = @(MU) -1*EP_Dodd2014_NonAutomated(MU,SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC);
%     x0 = [10 15];
%     options = optimset('TolFun',1e-15,'TolX',1e-12);
%     MU_opt_vec2 = fminsearchcon(FUN2,x0,[Lx Ly],[Ux Uy],[],[],[],options);
%     means2(i,:) = MU_opt_vec2;
%     EP2(i) = -1*FUN2(MU_opt_vec2);
%     [EPCheck(i) FeedIns(i,:)] = EP_Dodd2014_NonAutomated(means2(i,:),SIGMA,Lx,Ly,Ux,Uy,SP,PC,SC,RC)
%     
% end
% 
% figure;
% detlaEP = EP2-EP1;
% deltaMU1 = means2(:,1)-means1(:,1);
% deltaMU2 = means2(:,2)-means1(:,2);
% %plotyy(Ratio,EP2-EP1,Ratio,means2-means1); 
% [AX,H1,H2] = plotyy(rho,deltaMU1,rho,detlaEP); hold on; grid on
% set(AX(2),'XTickLabel',[])
% %set(gca,'XTickLabel',[])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(get(AX(2),'Ylabel'),'String','\Delta E(PR)','FontSize',15,'Color',[0 0 0]);
% set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
% set(H1,'LineStyle','-','LineWidth',2.5,'Color',darkblue,'Marker','+','MarkerSize',10); 
% set(H2,'LineStyle','-','LineWidth',2.5,'Color',darkgreen,'Marker','o','MarkerSize',7); 
% plot(rho,deltaMU2,'-','LineWidth',2.5,'Color',lightblue,'Marker','*','MarkerSize',10); 
% set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.005:max([max(deltaMU1),max(deltaMU2)])])
% Leg = legend('$$\Delta \tilde{\mu}_{x_1}$$','$$\Delta \tilde{\mu}_{x_2}$$','$$\Delta E(PR)$$'); 
% set(Leg,'FontSize',15);
% set(Leg,'Interpreter','latex'); set(gca,'FontSize',15);
% xlabel('Correlation (\rho)');
% 
% 
% y1 = FeedIns(:,1); y2 = FeedIns(:,2); y3 = FeedIns(:,3);
% y4 = FeedIns(:,4); y5 = FeedIns(:,5); y6 = FeedIns(:,6);
% figure;
% %[AX,H1,H2] = plotyy(rho,[y1.'y2.'],rho,FeedIns(:,4)); grid on
% [AX, H1, H2] = plotyy(rho, [y1 y2 y3],rho,[y4 y5 y6]); grid on
% % [AX,H5,H6] = plotyy(rho,FeedIns(:,3:3),rho,FeedIns(:,6:6)); hold on;
% set(AX(2),'XTickLabel',[])
% % %set(gca,'XTickLabel',[])
% set(get(AX(1),'Ylabel'),'String','Case I terms (Probability)','FontSize',15,'Color',[0 0 0]); 
% set(get(AX(2),'Ylabel'),'String','Case II terms (Probability)','FontSize',15,'Color',[0 0 0]);
% set(AX,{'ycolor'},{'k';'k'},'FontSize',15) % set the left and right y axis to black and pnt 15 font
% set(H1(1),'LineStyle','-','LineWidth',2.5,'Color',lightblue,'Marker','x','MarkerSize',10); 
% set(H1(2),'LineStyle','-','LineWidth',2.5,'Color',darkblue,'Marker','d','MarkerSize',5); 
% set(H1(3),'LineStyle','-','LineWidth',2.5,'Color',purple,'Marker','s','MarkerSize',5); 
% set(H2(1),'LineStyle','-.','LineWidth',2.5,'Color',red,'Marker','x','MarkerSize',10);
% set(H2(2),'LineStyle','-.','LineWidth',2.5,'Color',darkred,'Marker','d','MarkerSize',7); 
% set(H2(3),'LineStyle','-.','LineWidth',2.5,'Color',orange,'Marker','s','MarkerSize',7); 
% % set(AX(1),'YLim',[min([min(deltaMU1),min(deltaMU2)]) max([max(deltaMU1),max(deltaMU2)])])
% % set(get(AX(1),'Ylabel'),'String','\Delta\mu_{X}','FontSize',15,'Color',[0 0 0]); 
% % set(AX(1),'YTick',[min([min(deltaMU1),min(deltaMU2)]):0.005:max([max(deltaMU1),max(deltaMU2)])])
% Leg = legend('$$\mbox{Case II}: D_{2,S}$$','$$\mbox{Case II}: D_{3,S}$$','$$\mbox{Case II}: D_{4,S}$$','$$\mbox{Case I}: f_{2,S}$$','$$\mbox{Case I}: f_{3,S}$$','$$\mbox{Case I}: f_{4,S}$$'); set(Leg,'FontSize',15);
% set(Leg,'FontSize',20);
% set(Leg,'Interpreter','latex'); set(gca,'FontSize',15);
% xlabel('Correlation (\rho)');