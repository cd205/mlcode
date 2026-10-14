clear all
close all
clc
xi = linspace(0,12,100);
%global cut1 cut2 sigma1 sigma2 LSL USL
cut1 = 7
cut2 = 6
sigma1 = 1;
sigma2 = 1;
LSL = 3;
USL = 7;

% [v Rwork_P Scrap_P] = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
% plot(xi,v,'.-')
% grid on;


% 
% fun = @(x) Fun_Cut_Measure_Cut_Dist(x,cut1,cut2,sigma1,sigma2,LSL,USL);
% 
% CD_FinalDist_trap = trapz(xi,v)
% CD_FinalDist_quad = quad(fun,0,12)
% 
% CD_FinalDist2 = trapz(xi(1:250),v(1:250))
% 
% a1 = find(xi(1,:,1)<=LSL);
% 
% Scrap = trapz(xi(1:a1(end)),v(1:a1(end)))


x = linspace(0,12,100);
[df1,PRwork1,PScrap1] = Fun_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL);
[df2,PRwork2,PScrap2] = Fun_Reverse_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL);
[PRwork1 PRwork2]
[PScrap1 PScrap2]

figure(1)
plot(x,df1,'-','linewidth',2); hold on
plot(x,df2,'k-','linewidth',2); hold on
plot(x,normpdf(x,cut1,sigma1),'r-'); hold on
plot(x,PRwork1.*normpdf(x,cut2,sigma2),'m-')
grid on;

for i = 1:length(x)
    cdf1(i) = quad(@(x) Fun_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL),0,x(i));
    cdf2(i) = quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL),0,x(i));
end
figure(2)
plot(x,cdf1,'-'); grid on; hold on
plot(x,cdf2,'k-');

I1 = quad(@(x) Fun_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL),0,12)
I2 = quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,cut1,cut2,sigma1,sigma2,LSL,USL),0,12)



