clear all 
close all
clc
%% 
n = 80
MU_0 = [6.8 5 3 4.5];
diff13 = (MU_0(1) + MU_0(3) - 10)/2
diff14 = (MU_0(1) + MU_0(4) - 10)/2
%% parameters for D1 and D2
sig11_D1 = 1.2;
sig22_D2 = 1.2;
c = 0.3;
SIGMA = [sig11_D1^2 c; c sig22_D2^2];
A = [3 3];
B = [7 7];
LD1 = A(1);
LD2 = A(2);
UD1 = B(1);
UD2 = B(2);
D1 = linspace(MU_0(1)-5,MU_0(1)+5,n);
D2 = linspace(MU_0(2)-5,MU_0(2)+5,n);
D3 = linspace(MU_0(3)-5,MU_0(3)+5,n);
D4 = linspace(MU_0(4)-5,MU_0(4)+5,n);

sig_D3 = 0.5;
sig_D4 = 0.5;
c2 = 0.1;
SIGMA2 = [sig_D3^2 c2; c2 sig_D4^2];
Lt = 0.5; % lower tolerance for thickness
Ut = 2; % upper tolerance for thickness
a = 0;    % Clayton's alpha parameter for Clyaton correlation


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

% %% compute the component mass distribution
% c = 1;
% for i = 1:length(D1)
%     for j = 1:length(D2)   
%             Parts = round(Cpdf1(i,j)*1000); % Calc numer of parts and round up to nearest integer
%             if Parts > 0
%                 Weights(c:Parts) = (pi*(D1(i)/2)^2 + pi*(D2(j)/2)^2);
%                 c = length(Weights)+1;
%             end
%     end
% end
% figure(4)
% bins = linspace(min(Weights),max(Weights),12);
% hist(Weights)
% xlabel('part mass')
% ylabel('number of parts')



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
D1D2D3_pdf = permute(D1D2D3_pdf,P); % permute swaps the rows (dimension 1) 
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %%% CONVOLUTION %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Work out T1 = D1 - D3
%      and T2 = D1 - D4
% remember Conv does Z = X + Y
% Therefore do T1 = D1 + (-D2) and same for T2.
% T1
D1D3 = linspace(-1*MU_0(3)+diff13,MU_0(1)-diff13,n);
D3n = -1*D3;
pdf_D3n = normpdf(D3n,-1*MU_0(3),sig_D3);
pdf_T1 = conv(pdf_D1,pdf_D3n)*(D1(2)-D1(1));
cdf_T1 = cumtrapz(D1D3*2,pdf_T1(1:2:end));
figure(2)
plot(D1,pdf_D1,'.-'); hold on; plot(D3n,pdf_D3n,'r.-'); hold on; 
plot(D1D3*2,pdf_T1(1:2:end),'g.-'); grid on
trapz(D1,pdf_D1)
trapz(D3,pdf_D3n)
trapz(D1D3*2,pdf_T1(1:2:end))
figure(3) 
plot(D1D3*2,cdf_T1,'g.-'); grid on
% T2
D1D4 = linspace(-1*MU_0(4)+diff14,MU_0(1)-diff14,n);
D4n = -1*D4;
pdf_D4n = normpdf(D4n,-1*MU_0(4),sig_D4);
pdf_T2 = conv(pdf_D1,pdf_D4n)*(D1(2)-D1(1));
cdf_T2 = cumtrapz(D1D4*2,pdf_T2(1:2:end));
figure(4)
plot(D1,pdf_D1,'.-'); hold on; plot(D4n,pdf_D4n,'r.-'); hold on; 
plot(D1D4*2,pdf_T2(1:2:end),'g.-'); grid on
trapz(D4,pdf_D4n)
trapz(D1D3*2,pdf_T2(1:2:end))
figure(5) 
plot(D1D4*2,cdf_T2,'g.-'); grid on

% Convert pdf_t1 and cdf_t1 into grid format
[X1 X2] = ndgrid(D1D3,D1D4);
X = [X1(:) X2(:)];
D1D3grid = X(:,1);
D1D4grid = X(:,2);
c = 1;
while c < length(D1D3)^2
    pdf_T1grid(c:c+length(D1D3)-1,1) = pdf_T1(1:2:end);
    cdf_T1grid(c:c+length(D1D3)-1,1) = cdf_T1;
    c = length(pdf_T1grid)+1;
end
pdf_T2 = pdf_T2(1:2:end);
c = 1;
for i = 1:length(D1D4)
    pdf_T2grid(c:c+length(D1D3)-1,1) = pdf_T2(i);
    cdf_T2grid(c:c+length(D1D3)-1,1) = cdf_T2(i);
    c = length(pdf_T2grid)+1;
end

% Copula to join T1 and T2 distributions together with correlation
c = 0.3;
p1 = [1 c;c 1];
CpdfT1T2 = copulapdf('Gaussian',[cdf_T1grid,cdf_T2grid],p1).*pdf_T1grid.*pdf_T2grid;
CcdfT1T2 = copulacdf('Gaussian',[cdf_T1grid,cdf_T2grid],p1);
CpdfT1T2 = reshape(CpdfT1T2,length(D1D3),length(D1D4));
CcdfT1T2 = reshape(CcdfT1T2,length(D1D3),length(D1D4));

% plot outer diameter finish distributions
figure(6)
surf(D1D3,D1D4,CpdfT1T2); hold on
xlabel('Thickness 1')
ylabel('Thickness 2')


range = [MU_0(3)-2,MU_0(3)+2, MU_0(4)-2,MU_0(4)+2 , MU_0(1)-4,MU_0(1)+4];
nums = 30; % use geometric sequence of factor 2, 10,20,40,80,160,320,640
d3v = ((range(2)-range(1))/nums)*0.5;
d4v = ((range(4)-range(3))/nums)*0.5;
d1v = ((range(6)-range(5))/nums)*0.5;
% x1t is Diameter 3, x2t is Diameter 4 and x3t is Diameter 1
d3t = linspace(range(1)+d3v,range(2)-d3v,nums); % xt and yt are where the Cpdf is evaluated, i.e. 
d4t = linspace(range(3)+d4v,range(4)-d4v,nums); % in the middle of each little cube.
d1t = linspace(range(5)+d1v,range(6)-d1v,nums);
[D3t, D4t, D1t] = ndgrid(d3t,d4t,d1t);
Vol = ((range(2)-range(1))/nums)*((range(4)-range(3))/nums)*((range(6)-range(5))/nums)
Vt = F(D3t,D4t,D1t);
PVt = Vt.*Vol;
S1 = sum(PVt,1); S2 = sum(S1,2); S3 = sum(S2,3) % S3 is the total probability and should be 1


% figure(22)
% for i = 1:length(d3t)
%     for j = 1:length(d4t)
%         for k = 1:length(d1t)
%             plot3(d3t(i),d4t(j),d1t(k),'g.','MarkerSize',25); hold on
%         end
%     end
% end
% figure(22)
% plot3(d3t(2),d4t(1),d1t(1),'r.','MarkerSize',15)

% x1t is Diameter 3, x2t is Diameter 4 and x3t is Diameter 1

cc = 1;
nparts = 1000;
ns = 1;
nf = 0;
for i = 1:length(d1t)
    for j = 1:length(d3t)
        for k = 1:length(d4t)
            numbers = round(PVt(i,j,k)*nparts);
            pdf_T1 = d1t(i) - d3t(j);
            pdf_T2 = d1t(i) - d4t(k);
            T_Mat(cc,1) = pdf_T1;
            T_Mat(cc,2) = pdf_T2;
            if numbers >= 1
                nf = nf + numbers;
                T_Vecs(ns:nf,1) = pdf_T1.*ones(numbers,1);
                ns = length(T_Vecs) + 1;
            cc = cc + 1;
            end
        end
    end
end


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
