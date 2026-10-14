% CDFs of guassian mixture models
clear all
close all
clc
MU = [2 -5;-1 -5];
SIGMA = cat(2,[2 0;0 4]);
p = [0.7 0.3];%ones(1,2)/2;






for i= 1:1000
    obj = gmdistribution(MU,SIGMA,p);
end

figure(1)
ezsurf(@(x,y)pdf(obj,[x y]),[-10 10],[-10 10])
figure(2)
tic
ezsurf(@(x,y)cdf(obj,[x y]),[-10 10],[-10 10])
toc