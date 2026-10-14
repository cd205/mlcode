clear all 
close all
clc
%% 
% MU_0 = [7.987 6.346 4.1 5]; % 117.8
% MU_0 = [8.064 6.346 4.1 5]; % 117.1
MU_0 = [5 6 4 5]; % 117.8
n = 100;
%MU_0 = [5.8 6 5 6];
%diff13 = (MU_0(1) + MU_0(3) - 10)/2;
%diff14 = (MU_0(1) + MU_0(4) - 10)/2;
%% parameters for D1 and D2
sig_D1 = 0.1;
sig_D2 = 0.1;
rho = 0;
SIGMA = [sig_D1^2 rho*sig_D1*sig_D2; rho*sig_D1*sig_D2 sig_D2^2];
A = [4.7 5.7]
B = [5.3 6.3];
LD1 = A(1);
LD2 = A(2);
UD1 = B(1);
UD2 = B(2);
D1 = linspace(MU_0(1)-.5,MU_0(1)+.5,n);
D2 = linspace(MU_0(2)-.5,MU_0(2)+.5,n);
D3 = linspace(MU_0(3)-.5,MU_0(3)+.5,n);
D4 = linspace(MU_0(4)-.5,MU_0(4)+.5,n);

sig_D3 = 0.05;
sig_D4 = 0.05;
rho = 0;
SIGMA2 = [sig_D3^2 rho*sig_D3*sig_D4; rho*sig_D3*sig_D4 sig_D4^2];
LT1 = 4.9; % lower tolerance for thickness
UT1 = 5.1; % upper tolerance for thickness
LT2 = 4.9;
UT2 = 5.1;
a = 0;    % Clayton's alpha parameter for Clyaton correlation

D1_dist = normpdf(D1,MU_0(1),sig_D1);
D2_dist = normpdf(D2,MU_0(2),sig_D2)
figure;
plot(D1,D1_dist,'.-'); hold on
plot(D2,D2_dist,'r.-'); grid on
line([LD1,LD1],[0 max(D1_dist)])
%Cost_Fun_D1D2 = @(MU_0) 1*D1_D2_CostModel(MU_0,SIGMA,LD1,LD2,UD1,UD2);
%EP_D = Cost_Fun_D1D2(MU_0(1:2));
%% Inital first cut distribution
[X1 X2] = ndgrid(D1,D2);
X = [X1(:) X2(:)];

%% Find final distribution shapes from first stage (outer diameters)
pdf_D1 = Fun_TruncatedNormalDist_pdf(D1,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
pdf_D2 = Fun_TruncatedNormalDist_pdf(D2,MU_0(2),sig22_D2,A(2),B(2),B(2),0);
cdf_D1 = Fun_TruncatedNormalDist_cdf(D1,MU_0(1),sig11_D1,A(1),B(1),B(1),0);
cdf_D2 = Fun_TruncatedNormalDist_cdf(D2,MU_0(2),sig22_D2,A(2),B(2),B(2),0);


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

figure(22)
plot(D1,pdf_D1,'.-'); hold on; plot(D3n,pdf_D3n,'r.-'); hold on; 
plot(D1D3*2,pdf_T1(1:2:end),'g.-'); grid on

trapz(D1,pdf_D1);
trapz(D3,pdf_D3n);
trapz(D1D3*2,pdf_T1(1:2:end))

% T2
D1D4 = linspace(-1*MU_0(4)+diff14,MU_0(1)-diff14,n);
D4n = -1*D4;
pdf_D4n = normpdf(D4n,-1*MU_0(4),sig_D4);
pdf_T2 = conv(pdf_D1,pdf_D4n)*(D1(2)-D1(1));
cdf_T2 = cumtrapz(D1D4*2,pdf_T2(1:2:end));

figure(44)
plot(D1,pdf_D1,'b.-'); hold on; plot(D4n,pdf_D4n,'r.-'); hold on; 
plot(D1D4*2,pdf_T2(1:2:end),'g.-'); grid on

trapz(D4,pdf_D4n);
trapz(D1D3*2,pdf_T2(1:2:end))
% figure(5) 
% plot(D1D4*2,cdf_T2,'g.-'); grid on

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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %%% Copula(T1, T2) %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copula to join T1 and T2 distributions together with correlation
c = 0.0;
p1 = [1 c;c 1];
CpdfT1T2 = copulapdf('Gaussian',[cdf_T1grid,cdf_T2grid],p1).*pdf_T1grid.*pdf_T2grid;
CcdfT1T2 = copulacdf('Gaussian',[cdf_T1grid,cdf_T2grid],p1);
CpdfT1T2 = reshape(CpdfT1T2,length(D1D3),length(D1D4));
CcdfT1T2 = reshape(CcdfT1T2,length(D1D3),length(D1D4));

% plot outer diameter finish distributions
% figure(6)
% surf(D1D3,D1D4,CpdfT1T2,'Line','none'); hold on
% xlabel('Thickness 1')
% ylabel('Thickness 2')
% zlabel('Probability Density')
% figure(7)
% surf(D1D3,D1D4,CcdfT1T2,'Line','none'); hold on
% xlabel('Thickness 1')
% ylabel('Thickness 2')
% zlabel('Cumulative Density')

[val1 index1] = find(D1D3*2<=LT1);  % Find closest value to LT1 in D1D3*2
[val2 index2] = find(D1D3*2>=UT1);  % Find closest value to UT1 in D1D3*2
[val3 index3] = find(D1D4*2<=LT2);  % Find closest value to LT2 in D1D4*2
[val4 index4] = find(D1D4*2>=UT2);  % Find closest value to UT2 in D1D4*2
cdf_LT1 = interp1([D1D3(index1(end))*2,D1D3(index1(end)+1)*2],...
    [cdf_T1(index1(end)),cdf_T1(index1(end)+1)],LT1);% value of cdf_T1 at LT1
cdf_UT1 = interp1([D1D3(index2(1)-1)*2,D1D3(index2(1))*2],...
    [cdf_T1(index2(1)-1),cdf_T1(index2(1))],UT1);    % value of cdf_T1 at UT1
cdf_LT2 = interp1([D1D4(index3(end))*2,D1D4(index3(end)+1)*2],...
    [cdf_T2(index3(end)),cdf_T2(index3(end)+1)],LT2);% value of cdf_T2 at LT2
cdf_UT2 = interp1([D1D4(index4(1)-1)*2,D1D4(index4(1))*2],...
    [cdf_T2(index4(1)-1),cdf_T2(index4(1))],UT2);    % value of cdf_T2 at UT2 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %%% Markov T1 and T2 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
p12 = copulacdf('Gaussian',[inf,cdf_UT2],p1) - copulacdf('Gaussian',[cdf_UT1,cdf_UT2],p1)...
    - copulacdf('Gaussian',[inf,cdf_LT2],p1) + copulacdf('Gaussian',[cdf_UT1,cdf_LT2],p1);
p13 = copulacdf('Gaussian',[cdf_UT1,inf],p1) - copulacdf('Gaussian',[cdf_UT1,cdf_UT2],p1)...
    - copulacdf('Gaussian',[cdf_LT1,inf],p1) + copulacdf('Gaussian',[cdf_LT1,cdf_UT2],p1);
p14 = 1 - copulacdf('Gaussian',[inf,cdf_UT2],p1) - copulacdf('Gaussian',[cdf_UT1,inf],p1)...
    + copulacdf('Gaussian',[cdf_UT1,cdf_UT2],p1);
p15 = copulacdf('Gaussian',[cdf_UT1,cdf_UT2],p1) - copulacdf('Gaussian',[cdf_LT1,cdf_UT2],p1)...
    - copulacdf('Gaussian',[cdf_UT1,cdf_LT2],p1) + copulacdf('Gaussian',[cdf_LT1,cdf_LT2],p1);
p16 = copulacdf('Gaussian',[cdf_LT1,inf],p1) + copulacdf('Gaussian',[inf,cdf_LT2],p1)...
    - copulacdf('Gaussian',[cdf_LT1,cdf_LT2],p1);
P = p12+p13+p14+p15+p16;

p22 = 1 - cdf_UT1; % rework on T1 
p25 = cdf_UT1 - cdf_LT1; % conformance T1
p26 = cdf_LT1; % scrap T1
p33 = 1 - cdf_UT2; % rework on T2 
p35 = cdf_UT2 - cdf_LT2; % conformance T2
p36 = cdf_LT2; % scrap T2

p42 = p12;
p43 = p13;
p44 = p14;
p45 = p15;
p46 = p16;
p55 = 1;
p56 = 0;
P1s = [p12,p13,p14,p15,p16];
P2s = [p22];

m12 = p12/((1-p22)*(1-p44));
m13 = p13/((1-p33)*(1-p44));
m14 = p14/(1-p44);

%% Acceptance parts
f15 = p15 + p12*p25/((1-p22)*(1-p44)) + p13*p35/((1-p33)*(1-p44)) + p14*p45/(1-p44);
f25 = (p25/(1-p22));%*p12;
f35 = (p35/(1-p33));%*p13;
f45 = (p42*p25/((1-p22)*(1-p44)) + p43*p35/((1-p33)*(1-p44)) + p45/(1-p44));%*p14;

%% Scrap parts
f16 = p16 + p12*p26/((1-p22)*(1-p44)) + p13*p36/((1-p33)*(1-p44)) + p14*p46/(1-p44);
f26 = (p26/(1-p22));%*p12;
f36 = (p36/(1-p33));%*p13;
f46 = (p42*p26/((1-p22)*(1-p44)) + p43*p36/((1-p33)*(1-p44)) + p46/(1-p44));%*p14;

f1s = [f15, f25*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
    f35*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2))...
    P1s(3)*(P1s(4)/(1-P1s(3)))];
f2s = [f16, f26*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
    f36*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2)),...
    P1s(3)*(P1s(5)/(1-P1s(3)))];
ms = [m12,m13,m14];

SPT = 200;
PCT = 10;
RCT = [0 5 5 10];
SCT = [130 135 135 140];
ScrapT = SCT(1)*P1s(5) + SCT(2)*f2s(2) + SCT(3)*f2s(3) + SCT(4)*f2s(4);
RworkT = RCT(2)*m12 + RCT(3)*m13 + RCT(4)*m14;
EP_T = SPT*f15 - PCT - ScrapT - RworkT;

TotalProfit = EP_D + EP_T