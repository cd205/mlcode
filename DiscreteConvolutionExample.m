
clear all
close all
clc

n = 100
mu1 = 5
mu2 = -3
diff = (mu1 - mu2 - 10)/2
x1 = (linspace(mu1-5,mu1+5,n));
x2 = (linspace(mu2-5,mu2+5,n));
xp = linspace(mu2+diff,mu1-diff,n);
%xp = linspace(-10,10,n)
% in order to find difference rather than sum set one distribution to
% negative values. i.e CONV does Z = X + Y but we want Z = X - Y there set
% Y to -Y and do Z = X + (-Y) That is why x2 is defined as so.
l=normpdf(x1,mu1,0.8); % 1st normal distribution
n=normpdf(x2,mu2,0.5); % second normal distribution
ln=conv(l,n)*(x1(2)-x1(1));

figure(1)
plot(x1,l,'.-'); hold on; plot(x2,n,'r.-'); hold on; 
plot(xp*2,ln(1:2:end),'g.-'); grid on
%plot( x,n, x,l, x*2,ln(1:2:end) );
% xlim([.0,.3]);ylim([0,100]); 

trapz(x1,l)
trapz(x2,n)
trapz(xp*2,ln(1:2:end))