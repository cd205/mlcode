% Determine optimal D1 and D2 distributions (note there is correlation
% between D1 and D2

clear all
close all
clc



sig11 = 1.2;
sig22 = 1;
SIGMA = [sig11^2 -0.9; -0.9 sig22^2]
A = [3 3];
B = [7 7];
Lx = A(1);
Ly = A(2);
Ux = B(1);
Uy = B(2);
x = linspace(Lx-1,Ux+1,60);
y = linspace(Ly-1,Uy+1,60);


% [MU1 MU2] = meshgrid(x,y);
% MU1R = A(1)+(B(1)-MU1);  % convert cut1 from near to USL to near LSL
% MU2R = A(2)+(B(2)-MU2);  % convert cut2 from near to USL to near LSL
% MU = [MU1R(:) MU2R(:)];

[MU1 MU2] = meshgrid(x,y);
MU = [MU1(:) MU2(:)];

for i = 1:length(MU1(:))
     [EP(i),Scrap(i),Rwork(i)] = D1_D2_CostModel(MU(i,:),SIGMA,Lx,Ly,Ux,Uy);
%     [f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s] = Fun_Norm_Markov_DualChars(MU(i,:),SIGMA,Lx,Ly,Ux,Uy);
%     
%     f1s = [f15, f25*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
%         f35*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2))...
%         P1s(3)*(P1s(4)/(1-P1s(3)))];
%     f2s = [f16, f26*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
%         f36*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2)),...
%         P1s(3)*(P1s(5)/(1-P1s(3)))];
%     ms = [m12,m13,m14];
%     
%     Scrap = SC(1)*P1s(5) + SC(2)*f2s(2) + SC(3)*f2s(3) + SC(4)*f2s(4);
%     Rwork = RC(2)*m12 + RC(3)*m13 + RC(4)*m14;
%     EP(i) = SP*f15 - PC - Scrap - Rwork;
end

EP = reshape(EP,length(x),length(y));
EP_max = max(max(EP));
[row col] = find(EP==EP_max);
s = struct('EP_max',EP_max,'x',x(col),'y',y(row))



%% Find optimum 
Cost_Fun = @(MU) -1*D1_D2_CostModel(MU,SIGMA,Lx,Ly,Ux,Uy);
MU_0 = [5,5]
options = optimset('Display','iter','MaxFunEvals',1000,'OutputFcn', @outfun );
[x1 fval1] = fminsearch(Cost_Fun,MU_0,options)

MVNOpt = mvnpdf(MU,[x1(1),x1(2)],SIGMA);
MVNopt = reshape(MVNOpt,length(x),length(y));

%% Find final distribution shapes
pdf_x = Fun_TruncatedNormalDist_pdf(x,x1(1),sig11,A(1),B(1),B(1),0);
pdf_y = Fun_TruncatedNormalDist_pdf(x,x1(2),sig22,A(2),B(2),B(2),0);
cdf_x = Fun_TruncatedNormalDist_cdf(x,x1(1),sig11,A(1),B(1),B(1),0);
cdf_y = Fun_TruncatedNormalDist_cdf(x,x1(2),sig22,A(2),B(2),B(2),0);
%% Plot responce surface
% figure(1)
% surf(x,y,EP); hold on
% plot3(x(col),y(row),EP_max,'g.','MarkerSize',40); hold on
% plot3(x1(1),x1(2),-1*fval1,'c.','MarkerSize',40)
% xlabel('x-dim')
% ylabel('y-dim')
% zlabel('Profit')

figure(2)
surf(x,y,MVNopt); 
xlabel('x-dim')
ylabel('y-dim')
zlabel('probability density')

figure(3)
subplot(1,2,1)
plot(x,pdf_x,'.-'); grid on; hold on
plot(y,pdf_y,'r.-');
xlabel('dim')
ylabel('Probability Density')

subplot(1,2,2)
plot(x,cdf_x,'.-'); hold on 
plot(y,cdf_y,'r.-'); grid on; 
xlabel('dim')
ylabel('Cumulative Density')