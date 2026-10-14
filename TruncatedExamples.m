% truncated examples
clear all
close all
clc
x = linspace(0,10,50);
mu = 5;
sig =0.8
a = 3;
b = 7;
c = (mu-b)/sig
d = (mu-a)/sig

Tpdf = normpdf(x,mu,sig)./(normcdf(d,0,1) - normcdf(c,0,1));
trapz(x,Tpdf)
figure(1)
plot(x,Tpdf,'.-')