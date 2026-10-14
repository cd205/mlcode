% Draw Skew Normal Distributions 
clear all
close all
clc
%%
x_vec = linspace(-1,7,100);
location = 4;
scale = 2;
alpha = 1;
pdf = dsn(x_vec,location,scale,alpha);

%% Find Mean
delta  = alpha/sqrt(1+alpha^2)
mean = location + scale*delta*(sqrt(2/pi))



plot(x_vec,pdf,'.-'); grid on; hold on
line([mean mean], [0 max(pdf)],'Color',[1 0 0])