% % Khasawneh and Bowling 2008 paper example
% clear all
% close all
% clc
% 
% 
% 
% %MU = [10.55137,15.60796];
% SP = 120;
% PC = 45;
% RC = [0 15 12 20];
% SC = [8 9 11 14];
% sig11 = 1;
% sig22 = 1;
% SIGMA = [sig11^2 0; 0 sig22^2]
% Lx = 8;
% Ly = 13;
% Ux = 12;
% Uy = 17;
% x = linspace(Lx,Ux,100);
% y = linspace(Ly,Uy,100);
% 
% [MU1 MU2] = meshgrid(x,y);
% MU = [MU1(:) MU2(:)];
% 
% 
% 
% for i = 1:length(MU1(:))
%         [f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s] = KandBMarkov_DualChars(MU(i,:),SIGMA,Lx,Ly,Ux,Uy);
%         f1s = [f15, f25*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
%                f35*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2))...
%                P1s(3)*(P1s(4)/(1-P1s(3)))];
%         f2s = [f16, f26*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
%                f36*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2)),...
%                P1s(3)*(P1s(5)/(1-P1s(3)))];
%         ms = [m12,m13,m14];
%         %Ps = [1 Ps];
%         Scrap = SC(1)*P1s(5) + SC(2)*f2s(2) + SC(3)*f2s(3) + SC(4)*f2s(4);
%         Rwork = RC(2)*m12 + RC(3)*m13 + RC(4)*m14;
% %         for j = 1:4
% %             Scrap(j) = SC(j)*(1-fs(j))*Ps(j);
% %         end
% %         for k = 1:3
% %             m = k+1;
% %             Rwork(k) = RC(m)*ms(k);
% %         end
%         EP(i) = SP*f15 - PC - Scrap - Rwork;
%         %EP(i) = SP*f15 - PC - sum(Scrap) - sum(Rwork);
% end
% EP = reshape(EP,length(x),length(y));
% EP_max = max(max(EP));
% [row col] = find(EP==EP_max);
% s = struct('EP_max',EP_max,'x',x(col),'y',y(row))
% figure(1)
% surf(x,y,EP); hold on
% plot3(x(col),y(row),EP_max,'g.','MarkerSize',40)
% xlabel('x-dim')
% ylabel('y-dim')
% zlabel('Profit')
% %%
clear all
close all
clc
SP = 120;
PC = 45;
RC = [0 15 12 20];
SC = [8 9 11 14];
sig11 = 1;
sig22 = 1;
SIGMA = [sig11^2 0; 0 sig22^2]
Lx = 8;
Ly = 13;
Ux = 12;
Uy = 17;
[f15,f25,f35,f45, m12,m13,m14] = KandBMarkov_DualChars([10.55137 15.60796],SIGMA,Lx,Ly,Ux,Uy)
fs = [f15,f25,f35,f45]
ms = [m12,m13,m14]
for j = 1:4
    Scrap(j) = SC(j)*(1-fs(j))
end
for k = 1:3
    m = k+1;
    Rwork(k) = RC(m)*ms(k)
end

EP = SP*f15 - PC - sum(Scrap) - sum(Rwork)


