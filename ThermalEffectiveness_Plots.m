clear all
close all
clc
'hello'
CD_v1_3 = load('CDodd_LD_Mesh_ThermalEff.dat')
CD_v1_3_stan_k_e = load('CDodd_LD_Mesh_ThermalEff_Standard_k_e.dat')
CD_v1_3_MD = load('CDodd_MD_Mesh_ThermalEff.dat')
CD_v1_3_HD = load('CDodd_HD_Mesh_ThermalEff.dat')
%CD_v1_3= csvread('Wang_Zhao2011_RSM_ThermalEffectivness')
WZ_RSM = load('Wang_Zhao2011_RSM_ThermalEffectivness.mat')
GSM1 = load('Goldstien_M_1.mat')
GSM05 = load('Goldstien_M_0_5.mat')

WZ_RSM_DATA = WZ_RSM.Wang_Zhao2011_RSM_ThermalEffectivness
GSM1_DATA_1 = GSM1.Goldstien_M_1
GSM1_DATA_05 = GSM05.Goldstien_M_0_5
% normalise x-axis

nX_CD = (CD_v1_3(:,1) - min(CD_v1_3(:,1)))./(max(CD_v1_3(:,1))-min(CD_v1_3(:,1)))
nX_WZ = (WZ_RSM_DATA(:,1) - min(WZ_RSM_DATA(:,1)))./(max(WZ_RSM_DATA(:,1))-min(WZ_RSM_DATA(:,1)))

nX_CD2 = (CD_v1_3(:,1)-CD_v1_3(1,1))./0.008
nX_CD2_stan_k_e = (CD_v1_3_stan_k_e(:,1)-CD_v1_3_stan_k_e(1,1))./0.008
nX_CD2_MD = (CD_v1_3_MD(:,1)-CD_v1_3_MD(1,1))./0.008
nX_CD2_HD = (CD_v1_3_HD(:,1)-CD_v1_3_HD(1,1))./0.008

figure;
plot(WZ_RSM_DATA(:,1),WZ_RSM_DATA(:,2),'b.-'); hold on; grid on
plot(GSM1_DATA_1(:,1)./1,GSM1_DATA_1(:,2),'g+'); hold on
plot(GSM1_DATA_05(:,1)./1,GSM1_DATA_05(:,2),'m+'); hold on
plot(nX_CD2,CD_v1_3(:,2),'r.-'); hold on
plot(nX_CD2_stan_k_e,CD_v1_3_stan_k_e(:,2),'m.-');
plot(nX_CD2_MD,CD_v1_3_MD(:,2),'k.-'); 
plot(nX_CD2_HD,CD_v1_3_HD(:,2),'c+-'); 
xlabel('x/2d')
ylabel('Thermal Effectivity')
legend('Wang Zhao','Golstien M=1','Golstien M=0.5','LD Mesh','LD Mesh Standard k_e', 'MD Mesh','HD Mesh')
axis([0 50 0.1 1])