
clear all
close all
clc
f = @(x) 6.*x.^2 + 3.*x + 2;

x = linspace(-2,2,100)
df = diff(f(x))
ddf = diff(df)

figure;
plotyy(x,f(x),x(1:end-1),df); hold on; grid on

figure;
plot(x(2:end-1),ddf); grid on