function [Finish,Scrap,ReworkXY,ReworkX,ReworkY] = KandBSimulate(CUT,SIGMA,A,B,Rework)
% clear all
% clc
% close all
% CUT = [5 5]
% sig11 = 1;
% sig22 = 1;
% SIGMA = [sig11^2 0; 0 sig22^2]
% p  = [1 0.7; 0.7 1]
% A = [3 3];
% B = [7 7];
% Rework = 10000
sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));
LSLx = A(1);
LSLy = A(2);
USLx = B(1);
USLy = B(2);


Finish = 0;
Scrap = 0;
ReworkXY = 0;
ReworkX = 0;
ReworkY = 0;

PS = mvnrnd(CUT,SIGMA,Rework);

for i = 1:length(PS)
    if PS(i,1)>=LSLx && PS(i,1)<=USLx && PS(i,2)>=LSLy && PS(i,2)<=USLy  % finish
        Finish  = Finish + 1;
    elseif PS(i,1)<=LSLx || PS(i,2)<=LSLy
        Scrap = Scrap + 1;
    elseif PS(i,1)>USLx && PS(i,2)>USLy
        ReworkXY = ReworkXY + 1;
    elseif PS(i,1)>USLx 
        ReworkX = ReworkX + 1;
    elseif PS(i,2)>USLy
        ReworkY = ReworkY + 1;
    end
end