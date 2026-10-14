
clear all
close all
clc
%% parameters for D1 and D2
sig11_D1 = 1;
sig22_D2 = 1.2;
c = 0.8;
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

sig_D3 = 0.5;
Lt = 0.5; % lower tolerance for thickness
Ut = 2; % upper tolerance for thickness
a = 1;    % Clayton's alpha parameter for Clyaton correlation

%% 
MU_0 = [  4.8897    5.8361    2.7982];
Cost_Fun_D1D2 = @(MU_0) 1*D1_D2_CostModel(MU_0,SIGMA,LD1,LD2,UD1,UD2);
EP_D1D2 = Cost_Fun_D1D2(MU_0(1:2));
%% Inital first cut distribution
[X1 X2] = meshgrid(D1,D2);
X = [X1(:) X2(:)];
MVNOpt = mvnpdf(X,[MU_0(1),MU_0(2)],SIGMA);
MVNopt = reshape(MVNOpt,length(D1),length(D2))'; % transpose it beacuse it was created by ndgrid
% there is scrap produced here and from recutting the rework.  But this is
% removed on the next section as it will be taken out the system here.
%% Find final distribution shapes from first stage (outer diameters)
pdf_D1 = Fun_TruncatedNormalDist_pdf(D1,MU_0(1),sig11_D1,0,B(1),B(1),0);
pdf_D2 = Fun_TruncatedNormalDist_pdf(D2,MU_0(2),sig22_D2,0,B(2),B(2),0);
cdf_D1 = Fun_TruncatedNormalDist_cdf(D1,MU_0(1),sig11_D1,0,B(1),B(1),0);
cdf_D2 = Fun_TruncatedNormalDist_cdf(D2,MU_0(2),sig22_D2,0,B(2),B(2),0);
% The scrap produced initally is not taken through here since it 
%% Final distribtion (from D1, D2 cutting)
D1grid = X(:,1);
D2grid = X(:,2);
pdf_D1grid = Fun_TruncatedNormalDist_pdf(D1grid,MU_0(1),sig11_D1,0,B(1),B(1),0);
pdf_D2grid = Fun_TruncatedNormalDist_pdf(D2grid,MU_0(2),sig22_D2,0,B(2),B(2),0);
cdf_D1grid = Fun_TruncatedNormalDist_cdf(D1grid,MU_0(1),sig11_D1,0,B(1),B(1),0);
cdf_D2grid = Fun_TruncatedNormalDist_cdf(D2grid,MU_0(2),sig22_D2,0,B(2),B(2),0);
p1 = [1 c;c 1];
Cpdf1 = copulapdf('Frank',[cdf_D1grid,cdf_D2grid],7.9019).*pdf_D1grid.*pdf_D2grid;
Ccdf1 = copulacdf('Frank',[cdf_D1grid,cdf_D2grid],7.9019);
Cpdf1 = reshape(Cpdf1,length(D1),length(D2));
Ccdf1 = reshape(Ccdf1,length(D1),length(D2));
% plot marginals
figure(11)
plot(D1,pdf_D1,'-','linewidth',2); grid on; hold on
plot(D2,pdf_D2,'r-','linewidth',2)
xlabel('x,y')
ylabel('Probability Density')
legend('f_1(x)','f_2(y)')
figure(111)
plot(D1,cdf_D1,'-','linewidth',2); grid on; hold on
plot(D2,cdf_D2,'r-','linewidth',2)
xlabel('x,y')
ylabel('Cumulative Density')
legend('F_1(x)','F_2(y)')
% plot outer diameter finish distributions
% pdf
figure(1)
surf(D1,D2,Cpdf1); hold on
view(-28,45)
xlabel('x')
ylabel('y')
zlabel('Probability Density')
%cdf
%subM = Ccdf1(:,1:end);  % replace all
%subM(subM==1)=0;        % the ones in the CDF
%CcdfN0 = subM;          % with zeros
D1to7 = D1(D1<=7)
figure(22)
surf(D1to7,D2(1:length(D1to7)),Ccdf1(1:length(D1to7),1:length(D1to7))); hold on
axis([0 7 0 7 0.01 1])
view(-37.5,30)
xlabel('x')
ylabel('y')
zlabel('Cumulative Density')

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
%% T1 distribution - first cut (no rework)

CUT_D3 = MU_0(3);
[T1,tvec, T1_Scrap,T1_Rwork,T1_Cform, pdf_D3,Cpdf2] = Fun_ThicknessDist(pdf_D1,D1,pdf_D1grid,cdf_D1grid,CUT_D3,D3,sig_D3,Lt,Ut,a);
TotalCheck = T1_Scrap + T1_Rwork + T1_Cform  % should be 1% we already have D1 (pdf_x) above

% MARKOV CHAIN
m11_T1 = 1/(1-T1_Rwork);
f12_T1 = T1_Cform/(1-T1_Rwork);
f13_T1 = T1_Scrap/(1-T1_Rwork);
%COST
SP_T1 = 100; PC_T1 = 45; RC_T1 = 20; SC_T1 = 100;
EP_T1 = SP_T1*f12_T1 - PC_T1 - SC_T1*f13_T1 - RC_T1*(m11_T1-1);

%% Determine the final distribution shape after rework.
tvec_NR = tvec<=Ut;  % Everything except the reworked bins
%T1_cut1 = tvec_NR.*T1;
T1_DISTn(1,:) = T1;        % the distribution from the first cut before any rework
i = 1;
RW_num = sum(T1_Rwork.*T1);
tvec_R = tvec>Ut;
T1_RWn = T1.*T1_Rwork;

figure(2)
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

figure(3)
bar(tvec,T1_DISTn(end,:)); grid on % this is the final rework shape of the Thickness distribution
title('Final distribution after rework')
xlabel('Thickness')
ylabel('Number of Parts')

TOTALPROFIT = EP_D1D2 + EP_T1;
