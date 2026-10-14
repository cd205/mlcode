clear all 
close all
clc

%% parameters for D1 and D2
sig11_D1 = 1.2;
sig22_D2 = 1.2;
c = 0.6;
SIGMA = [sig11_D1^2 c; c sig22_D2^2];
A = [3 3];
B = [7 7];
LD1 = A(1);
LD2 = A(2);
UD1 = B(1);
UD2 = B(2);
D1 = linspace(0,10,80);
D2 = linspace(0,10,80);
D3 = linspace(0,10,80);
D4 = linspace(0,10,80);

sig_D3 = 0.5;
sig_D4 = 0.5;
c2 = 0.1
SIGMA2 = [sig_D3^2 c2; c2 sig_D4^2];
Lt = 0.5; % lower tolerance for thickness
Ut = 2; % upper tolerance for thickness
a = 0;    % Clayton's alpha parameter for Clyaton correlation

%% 
MU_0 = [5 5 5 5];
Cost_Fun_D1D2 = @(MU_0) 1*D1_D2_CostModel(MU_0,SIGMA,LD1,LD2,UD1,UD2);
EP_D1D2 = Cost_Fun_D1D2(MU_0(1:2));
%% Inital first cut distribution
[X1 X2] = ndgrid(D1,D2);
X = [X1(:) X2(:)];
MVNOpt = mvnpdf(X,[MU_0(1),MU_0(2)],SIGMA);
MVNopt = reshape(MVNOpt,length(D1),length(D2))'; % transpose it beacuse it was created by ndgrid
% there is scrap produced here and from recutting the rework.  But this is
% removed on the next section as it will be taken out the system here.
%% Find final distribution shapes from first stage (outer diameters)
pdf_D1 = Fun_TruncatedNormalDist_pdf(D1,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
pdf_D2 = Fun_TruncatedNormalDist_pdf(D2,MU_0(2),sig22_D2,A(2),B(2),B(2),0);
cdf_D1 = Fun_TruncatedNormalDist_cdf(D1,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
cdf_D2 = Fun_TruncatedNormalDist_cdf(D2,MU_0(2),sig22_D2,A(2),B(2),B(2),0);
% The scrap produced initally is not taken through here since it 
%% Final distribtion (from D1, D2 cutting)
D1grid = X(:,1);
D2grid = X(:,2);
pdf_D1grid = Fun_TruncatedNormalDist_pdf(D1grid,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
pdf_D2grid = Fun_TruncatedNormalDist_pdf(D2grid,MU_0(2),sig22_D2,A(2),B(2),B(2),0);
cdf_D1grid = Fun_TruncatedNormalDist_cdf(D1grid,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
cdf_D2grid = Fun_TruncatedNormalDist_cdf(D2grid,MU_0(2),sig22_D2,A(2),B(2),B(2),0);
p1 = [1 c;c 1];
Cpdf1 = copulapdf('Gaussian',[cdf_D1grid,cdf_D2grid],p1).*pdf_D1grid.*pdf_D2grid;
Ccdf1 = copulacdf('Gaussian',[cdf_D1grid,cdf_D2grid],p1);
Cpdf1 = reshape(Cpdf1,length(D1),length(D2));
Ccdf1 = reshape(Ccdf1,length(D1),length(D2));

% plot outer diameter finish distributions
figure(1)
surf(D1,D2,Cpdf1); hold on
xlabel('Diameter 1')
ylabel('Diameter 2')

%% compute the component mass distribution
c = 1;
for i = 1:length(D1)
    for j = 1:length(D2)   
            Parts = round(Cpdf1(i,j)*1000); % Calc numer of parts and round up to nearest integer
            if Parts > 0
                Weights(c:Parts) = (pi*(D1(i)/2)^2 + pi*(D2(j)/2)^2);
                c = length(Weights)+1;
            end
    end
end
figure(4)
bins = linspace(min(Weights),max(Weights),12);
hist(Weights)
xlabel('part mass')
ylabel('number of parts')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Distribution of D3 and D4 which can be correlated like D1 and D2
%[Y1 Y2] = ndgrid(D3,D4);
[Y1,Y2,Y3] = ndgrid(D3,D4,D1);
Y = [Y1(:) Y2(:) Y3(:)];
D3grid = Y(:,1);
D4grid = Y(:,2);
D1grid = Y(:,3);
% D3D4pdf = mvnpdf(Y,[MU_0(3),MU_0(4)],SIGMA2);
% D3D4pdf = reshape(D3D4pdf,length(D3),length(D4));
% figure(11)
% surf(D3,D4,D3D4pdf')
% xlabel('Diameter 3')
% ylabel('Diameter 4')

% Combine D3 and D4 with D1
SIGMA3D = [1 c2 0; c2 1 0; 0  0 1];
pdf_D3grid = normpdf(D3grid,MU_0(3),sig_D3);
pdf_D4grid = normpdf(D4grid,MU_0(4),sig_D4);
pdf_D1grid = Fun_TruncatedNormalDist_pdf(D1grid,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
cdf_D3grid = normcdf(D3grid,MU_0(3),sig_D3);
cdf_D4grid = normcdf(D4grid,MU_0(4),sig_D4);
cdf_D1grid = Fun_TruncatedNormalDist_cdf(D1grid,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
D1D2D3_pdf = copulapdf('Gaussian',[cdf_D3grid,cdf_D4grid,cdf_D1grid],SIGMA3D).*...
                       pdf_D3grid.*pdf_D4grid.*pdf_D1grid;
D1D2D3_pdf = reshape(D1D2D3_pdf,length(D3),length(D4),length(D1));
F = griddedInterpolant(Y1,Y2,Y3,D1D2D3_pdf,'spline');
P = [2 1 3];
D1D2D3_pdf = permute(D1D2D3_pdf,P); % permute swpas the rows (dimension 1) 
% and columns (dimension 2) for plotting see the wepage reference for info
% (http://www.mathworks.co.uk/help/matlab/examples/grid-based-interpolation.html)
%% Plot D1D2D3_pdf
figure(22)
xslice = 5;
yslice = 3;
zslice = 6;
slice(D3,D4,D1,D1D2D3_pdf,xslice,yslice,zslice); hold on
view(3);
xlabel('Diameter 3'); ylabel('Diameter 4'); zlabel('Diameter 1')
axis on; grid on;
colormap (jet(64)); colorbar('vertical');
%light; lighting flat; camlight('left'); 
shading interp;
alpha 0.7
axis square
h = colorbar;
ylabel(h, 'Probability Density');

range = [0 10];
nums = 500; % use geometric sequence of factor 2, 10,20,40,80,160,320,640
xv1 = ((range(2)-range(1))/nums)*0.5;
xv2 = ((range(2)-range(1))/nums)*0.5;
xv3 = ((range(2)-range(1))/nums)*0.5;
x1t = linspace(range(1)+xv1,range(2)-xv1,nums); % xt and yt are where the Cpdf is evaluated, i.e. 
x2t = linspace(range(1)+xv2,range(2)-xv2,nums); % in the middle of each little cube.
x3t = linspace(range(1)+xv3,range(2)-xv3,nums);
[X1t X2t X3t] = ndgrid(x1t,x2t,x3t);
Vol = ((range(2)-range(1))/nums)*((range(2)-range(1))/nums)*((range(2)-range(1))/nums)
Vt = F(X1t,X2t,X3t);
PVt = Vt.*Vol;
TotalProb = sum(sum(PVt(:,:,1))) + sum(sum(PVt(:,:,2))) + sum(sum(PVt(:,:,3))) % should be 1
% 
% figure(22)
% for i = 1:length(x1t)
%     for j = 1:length(x2t)
%         for k = 1:length(x3t)
%             plot3(x1t(i),x2t(j),x3t(k),'g.','MarkerSize',25); hold on
%         end
%     end
% end




% CUT_D3 = MU_0(3);
% [T1,tvec, T1_Scrap,T1_Rwork,T1_Cform, pdf_D3,Cpdf2] = Fun_ThicknessDist(pdf_D1,D1,pdf_D1grid,cdf_D1grid,CUT_D3,D3,sig_D3,Lt,Ut,a);
% TotalCheck = T1_Scrap + T1_Rwork + T1_Cform  % should be 1 
% 
% figure(2)
% bar(tvec,T1); grid on
% title('Initial distribution before rework')
% xlabel('Thickness')
% ylabel('Number of Parts')
% 
% %% T2 istribution - first cut (no rework)
% % 'pdf_D2grid' and 'cdf_D2grid' need to be like pdf_D1grid as Digrid is the
% % second element of the ndgrid 
% CUT_D4 = MU_0(4);
% [T2,tvec2, T2_Scrap,T2_Rwork,T2_Cform, pdf_D4,Cpdf2] = Fun_ThicknessDist(pdf_D1,D1,pdf_D1grid,cdf_D1grid,CUT_D4,D4,sig_D4,Lt,Ut,a);
% TotalCheck = T2_Scrap + T2_Rwork + T2_Cform  % should be 1% we already have D1 (pdf_x) above
% 
% figure(3)
% bar(tvec2,T2); grid on
% title('Initial distribution before rework')
% xlabel('Thickness')
% ylabel('Number of Parts')
% 
% figure;
% plot(D1,pdf_D1,'.-'); hold on; grid on
% plot(D2,pdf_D2,'r-.')

% % MARKOV CHAIN
% m11_T1 = 1/(1-T1_Rwork);
% f12_T1 = T1_Cform/(1-T1_Rwork);
% f13_T1 = T1_Scrap/(1-T1_Rwork);
% %COST
% SP_T1 = 100; PC_T1 = 45; RC_T1 = 20; SC_T1 = 100;
% EP_T1 = SP_T1*f12_T1 - PC_T1 - SC_T1*f13_T1 - RC_T1*(m11_T1-1);
% 
% %% Determine the final distribution shape after rework.
% tvec_NR = tvec<=Ut;  % Everything except the reworked bins
% %T1_cut1 = tvec_NR.*T1;
% T1_DISTn(1,:) = T1;        % the distribution from the first cut before any rework
% i = 1;
% RW_num = sum(T1_Rwork.*T1);
% tvec_R = tvec>Ut;
% T1_RWn = T1.*T1_Rwork;
% 
% 
% 
% while RW_num > 1
%     %figure(i)
%     %bar(tvec,T1_DISTn(i,:)); grid on
%     T1_DISTn(i+1,:) = T1_RWn(i,:) + T1_DISTn(i,:).*(tvec_NR);
%     T1_RWn(i+1,:) = T1_RWn(i,:).*T1_Rwork; % Stored reworked dist in columns
%     % Add the reworked distribution to the previous distribution (not
%     % including the reworked parts)
%     RW_num = sum(tvec_R.*T1_DISTn(i+1,:));
%     i = i + 1;
% end
% 
% figure(3)
% bar(tvec,T1_DISTn(end,:)); grid on % this is the final rework shape of the Thickness distribution
% title('Final distribution after rework')
% xlabel('Thickness')
% ylabel('Number of Parts')
% 
% TOTALPROFIT = EP_D1D2 + EP_T1;
