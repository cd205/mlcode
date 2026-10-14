
clear all
close all
clc
X1 = randn(1000,1)
X2 = randn(1000,1)

Y = X1.*X2

hist(Y,100)

x1 = rand(10000,1)
Xin = norminv(x1,1,1)

figure;
hist(Xin,50)

di = 7+randn(10,1)
do = 5+randn(10,1)
t = di-do

figure;
hist(di,20); hold on; hist(do,20); hold on; hist(t,20)

pos = find(t>1 & t< 3)
% find all 