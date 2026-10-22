function [Finish,Scrap,Rework] = KandBSimulate_1Var(cut,sig,L,U,RW)
% clear all
% clc
% close all
% cut = 5
% sig = 2
% L = 3
% U = 7
% RW = 1



Finish = 0;
Scrap = 0;
Rework = 0;

PS = normrnd(cut,sig,RW,1);

for i = 1:length(PS)
    if PS(i)>=L && PS(i,1)<=U % finish
        Finish  = Finish + 1;
    elseif PS(i)<L
        Scrap = Scrap + 1;
    elseif PS(i)>U
        Rework = Rework + 1;
    end
end