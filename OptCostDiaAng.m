clear all
close all
clc
format short
Xplot = load('Eff35DoE.Mat','Xplot');
Eff35 = load('Eff35DoE.Mat','Eff35');

Xplot = Xplot.Xplot;
Eff35 = Eff35.Eff35;

npnts = 1e6
MU = [0.53 0.5]; % MU(1) = diameter  MU(2) = Angle
MU_rw = [0.4];
sig11 = 0.109687; sig22 = 0.102564;
rho = 0.8;%  0.7052
z1l = .5; z1u = 0.5; z2 = .5;
MinEff = linspace(0.7728,0.77345,8)
%MinEff = [0.7735429,  0.7736357]
%MinEff = [0.772521428571429 0.772614285714286 0.772707142857143]
tic
[Profit,Eff35A] = funNCProfitDiaAng([MU(1) MU(2)],MU_rw,sig11,sig22,...
    rho,z1l,z1u,z2,npnts,Xplot,Eff35,MinEff(1));
toc
%% Standard production
tic
parfor i = 1:length(MinEff)
FUN1 = @(INPUT) -1*funNCProfitDiaAng([INPUT(1) INPUT(2)],INPUT(1),sig11,sig22,rho,...
    INPUT(3),INPUT(3),INPUT(4),npnts,Xplot,Eff35,MinEff(i));
LB = [sig11*3 sig22*3 0.001 0.001];
UB = [1-sig11*3 1-sig22*3 10 10];
x0 = [0.53 0.6 1 1];
[bestvar1(i,:),bestobj1(i),history,eval_count]=ga(FUN1,x0,[],[],[],[],LB,UB)
options = optimset('TolFun',1e-4,'TolX',1e-4,'MaxFunEvals',800,'Display','iter')
[OPTVALSA_CorrP8(i,:), fvalA_CorrP8(i)] = fminsearchcon(FUN1,x0,[LB],[UB],[],[],[],options);

%[ProfitA(i),Eff35A] = funNCProfitDiaAng([OPTVALSA(1) OPTVALSA(2)],OPTVALSA(3),...
%    sig11,sig22,rho,OPTVALSA(4),OPTVALSA(4),OPTVALSA(5),npnts,Xplot,Eff35,MinEff(i));
end
OPTVALSA_CorrP8
fvalA_CorrP8

save('OPTVALSA_CorrP8')
save('fvalA_CorrP8')
% figure;
% hist(Eff35A,50); grid on
% title('A')
% 
% figure;
% contourf(Xplot,Xplot,Eff35); hold on; grid on
% colorbar
% plot(OPTVALSA(1),OPTVALSA(2),'g.')
% line([OPTVALSA(1)-OPTVALSA(4)*sig11 OPTVALSA(1)-OPTVALSA(4)*sig11],[0 1],'Color',[0 0 1])
% line([OPTVALSA(1)+OPTVALSA(4)*sig11 OPTVALSA(1)+OPTVALSA(4)*sig11],[0 1],'Color',[0 0 1])
% line([0 1],[OPTVALSA(2)-OPTVALSA(5)*sig22 OPTVALSA(2)-OPTVALSA(5)*sig22],'Color',[0 0 1])
% line([0 1],[OPTVALSA(2)+OPTVALSA(5)*sig22 OPTVALSA(2)+OPTVALSA(5)*sig22],'Color',[0 0 1])

%% Optimal mean setting
parfor i = 1:length(MinEff)
FUN2 = @(INPUT) -1*funNCProfitDiaAng([INPUT(1) INPUT(2)],INPUT(3),sig11,sig22,rho,...
    INPUT(4),INPUT(5),INPUT(6),npnts,Xplot,Eff35,MinEff(i));

LB = [sig11*3 sig22*3 sig11*3 0.001 0.001 0.001];
UB = [1-sig11*3 1-sig22*3 1-sig11*3 10 10 10];
x0 = [0.45 0.52 0.4 1 1 1];
[bestvar2(i,:),bestobj2(i),history,eval_count]=ga(FUN2,x0,[],[],[],[],LB,UB)
options = optimset('TolFun',1e-4,'TolX',1e-4,'MaxFunEvals',800,'Display','iter');
[OPTVALB_CorrP8(i,:) fvalB_CorrP8(i)] = fminsearchcon(FUN2,bestvar2(i,:),[LB],[UB],[],[],[],options);

%[ProfitB(i),Eff35B] = funNCProfitDiaAng([OPTVALSB(1) OPTVALSB(2)],OPTVALSB(3),...
%    sig11,sig22,rho,OPTVALSB(4),OPTVALSB(5),OPTVALSB(6),npnts,Xplot,Eff35,MinEff(i));
end
toc
OPTVALSB_CorrP8
fvalB_CorrP8
save('OPTVALSB_CorrP8')
save('fvalB_CorrP8')
% figure;
% %plot(fvalA,'-.'); hold on
% plot(fvalB,'r-.'); grid on
% figure;
% plotyy(MinEff,fvalA,MinEff,fvalB); grid on
% % figure;
% % hist(Eff35B,50); grid on
% % title('B')
% % 
% % figure;
% % contourf(Xplot,Xplot,Eff35); hold on; grid on
% % colorbar
% % plot(OPTVALSB(1),OPTVALSB(2),'g.')
% % line([OPTVALSB(1)-OPTVALSB(4)*sig11 OPTVALSB(1)-OPTVALSB(4)*sig11],[0 1],'Color',[0 0 1])
% % line([OPTVALSB(1)+OPTVALSB(5)*sig11 OPTVALSB(1)+OPTVALSB(5)*sig11],[0 1],'Color',[0 0 1])
% % line([0 1],[OPTVALSB(2)-OPTVALSB(6)*sig22 OPTVALSB(2)-OPTVALSB(6)*sig22],'Color',[0 0 1])
% % line([0 1],[OPTVALSB(2)+OPTVALSB(6)*sig22 OPTVALSB(2)+OPTVALSB(6)*sig22],'Color',[0 0 1])