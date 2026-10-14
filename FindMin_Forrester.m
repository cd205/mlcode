clear all 
clc

%function [time, funevals, Xmin, Ymin]=Minimise_Forrester_1
tic
j=0;
for i=0:0.25:1
    j=j+1;
    [xmin,ymin]=fmincon('Forrester',[i],[],[],[],[],[0],[1]);
    xmins(j)=xmin;
    ymins(j)=ymin;
end
time = toc
funevals = j
Xmin = min(xmins)
Ymin = min(ymins) 
