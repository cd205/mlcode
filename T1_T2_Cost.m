% Determine optimal D1 and D2 distributions (note there is correlation
% between D1 and D2

clear all
close all
clc



sig11_D1 = 1;
sig22_D2 = 1.2;
c = 0.4;
SIGMA = [sig11_D1^2 c; c sig22_D2^2];
A = [3 3];
B = [7 7];
LD1 = A(1);
LD2 = A(2);
UD1 = B(1);
UD2 = B(2);
D1 = linspace(0,10,80);
D2 = linspace(0,10,80);

%% Find optimum 
Cost_Fun = @(MU) -1*D1_D2_CostModel(MU,SIGMA,LD1,LD2,UD1,UD2);
MU_0 = [5 5];
options = optimset('Display','iter','MaxFunEvals',1000,'OutputFcn', @outfun );
[x1 fval1] = fminsearch(Cost_Fun,MU_0,options);

%% Inital first cut distribution
[MU1 MU2] = ndgrid(D1,D2);
MU = [MU1(:) MU2(:)];
MVNOpt = mvnpdf(MU,[x1(1),x1(2)],SIGMA);
MVNopt = reshape(MVNOpt,length(D1),length(D2))'; % transpose it beacuse it was created by ndgrid

%% Find final distribution shapes from first stage (outer diameters)
pdf_D1 = Fun_TruncatedNormalDist_pdf(D1,x1(1),sig11_D1,A(1),B(1),B(1),0);
pdf_D2 = Fun_TruncatedNormalDist_pdf(D2,x1(2),sig22_D2,A(2),B(2),B(2),0);
cdf_D1 = Fun_TruncatedNormalDist_cdf(D1,x1(1),sig11_D1,A(1),B(1),B(1),0);
cdf_D2 = Fun_TruncatedNormalDist_cdf(D2,x1(2),sig22_D2,A(2),B(2),B(2),0);

%% Final distribtion (from D1, D2 cutting)
D1grid = MU(:,1);
D2grid = MU(:,2);
pdf_D1grid = Fun_TruncatedNormalDist_pdf(D1grid,x1(1),sig11_D1,A(1),B(1),B(1),0);
pdf_D2grid = Fun_TruncatedNormalDist_pdf(D2grid,x1(2),sig22_D2,A(2),B(2),B(2),0);
cdf_D1grid = Fun_TruncatedNormalDist_cdf(D1grid,x1(1),sig11_D1,A(1),B(1),B(1),0);
cdf_D2grid = Fun_TruncatedNormalDist_cdf(D2grid,x1(2),sig22_D2,A(2),B(2),B(2),0);
p1 = [1 c;c 1]
Cpdf1 = copulapdf('Gaussian',[cdf_D1grid,cdf_D2grid],p1).*pdf_D1grid.*pdf_D2grid;
Ccdf1 = copulacdf('Gaussian',[cdf_D1grid,cdf_D2grid],p1);
Cpdf1 = reshape(Cpdf1,length(D1),length(D2));
Ccdf1 = reshape(Ccdf1,length(D1),length(D2));

% plot outer diameter distributions
figure(3)
surf(D1,D2,Cpdf1); hold on
xlabel('Diameter 1')
ylabel('Diameter 2')

% compute the component mass distribution
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
% [X1 X2] = ndgrid(D1,D2)
% G = griddedInterpolant(X1,X2,Cpdf1,'spline') % get the joint finish PDF of D1 and D2 as a response surface
% Xt = rand(10000,2).*10
% Gt = G(Xt(:,1),Xt(:,2))  % plot backwards because using ndgrid
% plot3(Xt(:,2),Xt(:,1),Gt,'c.','MarkerSize',6)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% T1 distribution - first cut (no rework)
CUT_D3 = 3.5;
D3 = linspace(0,10,80);
sig_D3 = 0.4;
Lt = 0.5; % lower tolerance for thickness
Ut = 2; % upper tolerance for thickness
a = 1;    % Clayton's alpha parameter for Clyaton correlation
[T1,tvec, T1_Scrap,T1_Rwork,T1_Cform, pdf_D3,Cpdf2] = Fun_ThicknessDist(pdf_D1,D1,pdf_D1grid,cdf_D1grid,CUT_D3,D3,sig_D3,Lt,Ut,a);
TotalCheck = T1_Scrap + T1_Rwork + T1_Cform  % should be 1% we already have D1 (pdf_x) above

% MARKOV CHAIN
m11_T1 = 1/(1-T1_Rwork)
f12_T1 = T1_Cform/(1-T1_Rwork)
f13_T1 = T1_Scrap/(1-T1_Rwork)
%COST
SP_T1 = 120; PC_T1 = 45; RC_T1 = 20; SC_T1 = 200;
EP_T1 = SP_T1*f12_T1 - PC_T1 - SC_T1*f13_T1 - RC_T1*(1-m11_T1)

%% Determine the final distribution shape after rework.
tvec_NR = tvec<=Ut;  % Everything except the reworked bins
%T1_cut1 = tvec_NR.*T1;
T1_DISTn(1,:) = T1;        % the distribution from the first cut before any rework
i = 1;
RW_num = sum(T1_Rwork.*T1);
tvec_R = tvec>Ut;
T1_RWn = T1.*T1_Rwork;
figure(5)
bar(tvec,T1); grid on
title('Initial distribution before rework')
xlabel('Thickness')
ylabel('Number of Parts')
while RW_num > 1
    %figure(i)
    %bar(tvec,T1_DISTn(i,:)); grid on
    T1_DISTn(i+1,:) = T1_RWn(i,:) + T1_DISTn(i,:).*(tvec_NR);
    T1_RWn(i+1,:) = T1_RWn(i,:).*T1_Rwork; % Stored reworked dist in columns
    % Add the reworked distribution to the previous distribution (not
    % including the reworked parts)
    RW_num = sum(tvec_R.*T1_DISTn(i+1,:));
    i = i + 1;
end
figure(6)
bar(tvec,T1_DISTn(end,:)); grid on % this is the final rework shape of the Thickness distribution
title('Final distribution after rework')
xlabel('Thickness')
ylabel('Number of Parts')
% T1_a = T1.*T1_Rwork;
% T1_cut2 = T1_a + T1_cut1;
% 
% T1_b = T1_a.*T1_Rwork;
% T1_cut3 = T1_b + (tvec_NR.*T1_cut2);
% 
% T1_c = T1_b.*T1_Rwork;
% T1_cut4 = T1_c + (tvec_NR.*T1_cut3);
% set up the D3 inner diameter (first run) the second run will be a 
% truncated distribution. 

% [X1 X3] = ndgrid(D1,D3);
% X = [X1(:) X3(:)];
% D1grid = X(:,1);
% D3grid = X(:,2);
% 
% C = [0.5]
% D = [1.5]
% sig11_D3 = 1.5
% p2 = 1
% 
% pdf_D3 = normpdf(D3,CUT_D3,sig_D3);
% pdf_D3grid = normpdf(D3grid,CUT_D3,sig_D3);
% cdf_D3grid = normcdf(D3grid,CUT_D3,sig_D3);
% %p2 = 1
% Cpdf2 = copulapdf('Clayton',[cdf_D1grid,cdf_D3grid],p2).*pdf_D1grid.*pdf_D3grid;
% Ccdf2 = copulacdf('Clayton',[cdf_D1grid,cdf_D3grid],p2);
% Cpdf2 = reshape(Cpdf2,length(D1),length(D3));
% Ccdf2 = reshape(Ccdf2,length(D1),length(D3));
% figure(10)
% plot(D1,pdf_D1,'.-'); hold on; grid on
% plot(D3,pdf_D3,'r.-')
% % tessalate the domain, divide into rectangles and record the probability
% % densit in each rectange 
% F = griddedInterpolant(X1,X3,Cpdf2,'spline');
% range = [0 10];
% nums = 160; % use geometric sequence of factor 2, 10,20,40,80,160,320,640
% xt1 = range(1)+(range(2)/nums)*0.5;
% yt1 = range(1)+(range(2)/nums)*0.5;
% xt = linspace(xt1,10-xt1,nums); % xt and yt are where the Cpdf is evaluated, i.e. 
% yt = linspace(yt1,10-yt1,nums); % in the middle of each little square.
% [Xt Yt] = ndgrid(xt,yt);
% Base = ((range(2)-range(1))/nums)*((range(2)-range(1))/nums);
% Vt = F(Xt,Yt);
% 
% figure(2)
% plot3(Xt,Yt,Vt,'g.','MarkerSize',8); hold on
% Int_density = sum(sum(Vt.*Base)) % should be 1
% nparts = 10000;
% 
% for i = 1:nums
%     for j = 1:nums
%         t(i,j) = (Xt(i,j)-Yt(i,j));
%         Numbers(i,j) = Vt(i,j)*Base*nparts;
%     %marginal_x1(i) = sum(Vt(i,:));
%     %marginal_y1(i) = sum(Vt(:,i));
%     end
% end
% %plot3(Xt,Yt,Numbers,'c+','MarkerSize',10)
% numsum = sum(sum(Numbers))
% Numbers = Numbers(:);
% tvec = min(min(t(:))):range(2)/nums:max(max(t(:)));
% for i = 1:length(tvec)
%     p = find(t(:)==tvec(i)); % 
%     T1(i) = sum(Numbers(p));
% end
% %% work out scrap rework and cofromance for Thickness 1
% tvec_S = tvec<C(1);
% tvec_R = tvec>D(1);
% tvec_C = tvec>=C(1) & tvec<=D(1);
% T1_Scrap = sum(tvec_S.*T1)/nparts
% T1_Rwork = sum(tvec_R.*T1)/nparts
% T1_Cform = sum(tvec_C.*T1)/nparts
% TotalCheck = T1_Scrap + T1_Rwork + T1_Cform  % should be 1

% % MARKOV CHAIN
% m11_T1 = 1/(1-T1_Rwork)
% f12_T1 = T1_Cform/(1-T1_Rwork)
% f13_T1 = T1_Scrap/(1-T1_Rwork)
% %COST
% SP_T1 = 120; PC_T1 = 45; RC_T1 = 20; SC_T1 = 200;
% EP_T1 = SP_T1*f12_T1 - PC_T1 - SC_T1*f13_T1 - RC_T1*(1-m11_T1)

% %% plotting 1
% figure(2)
% surf(D1,D3,Cpdf2'); 
% xlabel('Diameter 1')
% ylabel('Diameter 3')
% zlabel('Probability Density')
% 
% 
% figure(3)
% subplot(1,2,1)
% plot(D1,pdf_D1,'.-'); grid on; hold on
% plot(D2,pdf_D2,'r.-'); hold on
% plot(D3,pdf_D3,'k.-'); hold on
% %plot(D3,pdf_D3_Trun,'g.-');
% xlabel('Diameters')
% ylabel('Probability Density')
% subplot(1,2,2)
% plot(D1,cdf_D1,'.-'); hold on 
% plot(D2,cdf_D2,'r.-'); grid on; 
% xlabel('Diameters')
% ylabel('Cumulative Density')
% 
% figure(4)
% h = surf(D1,D2,Cpdf1'); hold on % invert the matrix for plotting hence Cpdf'
% %set(h,'edgecolor','none');%[0.7,0.7,0.7]);
% %colorbar
% xlabel('Diameter 1')
% ylabel('Diameter 2')
% zlabel('probability density')
% 
% figure(5)
% bar(tvec,T1); grid on; hold on  % what you get after cut 1
% %bar(tvec(1:length(T1_cut1)),T1_cut1,'g')
% xlabel('Thickness')
% ylabel('Frequency')
% sum_T1 = sum(T1)
% 
% figure(6)
% bar(tvec,T1_cut2,'m'); grid on; hold on % what you get after cut 2
% %bar(tvec,T1_a,'r')
% xlabel('Thickness')
% ylabel('Frequency')
% 
% figure(7)
% bar(tvec,T1_cut3); grid on; hold on % what you get after cut 3
% %bar(tvec,T1_b,'r')
% xlabel('Thickness')
% ylabel('Frequency')
% 
% figure(8)
% bar(tvec,T1_cut4,'c'); grid on; hold on % what you get after cut 3
% %bar(tvec,T1_b,'r')
% xlabel('Thickness')
% ylabel('Frequency')

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% T1 distribution including the rework!
% % Working out D3 bounds: T1_U = D1_U - D3_L  and  T1_L = D1_L - D3_U
% %                        T1_U = 7 - D3_L     and  T1_L = 3 - D3_U
% %                        D3_L = 7 - T1_U     and  D3_U = 3 - T1_L
% pdf_D3_Trun = Fun_TruncatedNormalDist_pdf(D3,CUT_D3,sig11_D3,A(1)-C(1),B(1)-D(1),B(1)-D(1),0);
% pdf_D3grid_Trun = Fun_TruncatedNormalDist_pdf(D3grid,CUT_D3,sig11_D3,A(1)-C(1),B(1)-D(1),B(1)-D(1),0);
% cdf_D3grid_Trun = Fun_TruncatedNormalDist_cdf(D3grid,CUT_D3,sig11_D3,A(1)-C(1),B(1)-D(1),B(1)-D(1),0);
% 
% Cpdf3 = copulapdf('Clayton',[cdf_D1grid,cdf_D3grid_Trun],p2).*pdf_D1grid.*pdf_D3grid_Trun;
% Ccdf3 = copulacdf('Clayton',[cdf_D1grid,cdf_D3grid_Trun],p2);
% Cpdf3 = reshape(Cpdf3,length(D1),length(D3));
% Ccdf3 = reshape(Ccdf3,length(D1),length(D3));
% 
% % tessalate the domain, divide into rectangles and record the probability
% % densit in each rectange 
% F2 = griddedInterpolant(X1,X3,Cpdf3,'spline');
% range = [0 10];
% nums = 320; % use geometric sequence of factor 2, 10,20,40,80,160,320,640
% xt2 = range(1)+(range(2)/nums)*0.5;
% yt2 = range(1)+(range(2)/nums)*0.5;
% xt2 = linspace(xt2,10-xt2,nums); % xt and yt are where the Cpdf is evaluated, i.e. 
% yt2 = linspace(yt2,10-yt2,nums); % in the middle of each little square.
% [Xt2 Yt2] = ndgrid(xt2,yt2);
% Base2 = ((range(2)-range(1))/nums)*((range(2)-range(1))/nums);
% Vt2 = F2(Xt2,Yt2);
% 
% figure(2)
% %plot3(Xt,Yt,Vt,'g.','MarkerSize',1); hold on
% Int_density2 = sum(sum(Vt2.*Base2)) % should be 1
% nparts = 1000;
% 
% for i = 1:nums
%     for j = 1:nums
%         t2(i,j) = (Xt2(i,j)-Yt2(i,j));
%         Numbers2(i,j) = Vt2(i,j)*Base2*nparts;
%     %marginal_x1(i) = sum(Vt(i,:));
%     %marginal_y1(i) = sum(Vt(:,i));
%     end
% end
% %plot3(Xt,Yt,Numbers,'c+','MarkerSize',10)
% numsum2 = sum(sum(Numbers2))
% Numbers2 = Numbers2(:);
% tvec2 = min(min(t2(:))):range(2)/nums:max(max(t2(:)));
% for i = 1:length(tvec2)
%     p2 = find(t2(:)==tvec2(i)); % 
%     T2(i) = sum(Numbers2(p2));
% end
% 
% figure(6)
% surf(D1,D3,Cpdf3'); 
% xlabel('Diameter 1')
% ylabel('Diameter 3')
% zlabel('Probability Density')
% 
% figure(7)
% bar(tvec2,T2); grid on
% xlabel('Thickness')
% ylabel('Frequency')
% sum_T2 = sum(T2)
