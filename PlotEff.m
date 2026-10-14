
clear all
close all
clc
%filename = 'Eff_Series1fromFLU.csv';
%M = csvread(filename)
eff = load('Eff_Series1fromFLU.dat');
effLD = load('Eff_LD.dat');
effHD = load('Eff_HD.dat');
effOpt = load('Eff_Opt.dat');
Sch = load('Sch_rho1_2M1.dat');
Wang_ke = load('Zang2011_ke_standard.dat');
Ree2002 = load('Ree2002_Exp_M2.dat');


X_LD = (effLD(:,1)-min(effLD(:,1)))./0.004;
X_MD = (eff(:,1)-min(eff(:,1)))./0.004;
X_HD = (effHD(:,1)-min(effHD(:,1)))./0.004;

figure;
plot(X_LD,effLD(:,2),'b-','linewidth',2); hold on
plot(X_MD,eff(:,2),'k-','linewidth',2); hold on; grid on
%plot(effHD(:,1),effHD(:,2),'g-'); hold on
plot(X_HD,effOpt(:,2),'r-','linewidth',2); hold on
plot(Wang_ke(:,1),Wang_ke(:,2),'g','linewidth',2); hold on
plot(Sch(:,1),Sch(:,2),'+','MarkerSize',3); hold on
plot(Ree2002(:,1),Ree2002(:,2),'m.')

set(gca,'FontSize',15)
xlabel('Downstream distance (x/d)')
ylabel('Cooling effectiveness (\eta)')
legend('LD','MD','HD','Wang 2011','Schroeder 2014','Rhee 2002')
axis([0 30 0.2 1])
yplus = load('yplus_Series1fromFLU.dat');
yplusLD = load('yplus_LD.dat');
yplusHD = load('yplus_HD.dat');
yplusOpt = load('yplus_Opt.dat');

figure;
plot(X_LD(:,1),yplusLD(:,2),'b-','linewidth',2); hold on
plot(X_MD(:,1),yplus(:,2),'k-','linewidth',2); hold on; grid on
plot(X_HD(:,1),yplusOpt(:,2),'r-','linewidth',2)
set(gca,'FontSize',15)
xlabel('Downstream distance (x/d)')
ylabel('yPlus')
legend('LD','MD','HD')
axis([0 60 0 3.5])