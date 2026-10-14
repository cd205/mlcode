function [PS,Finish,Scrap,ReworkX,ReworkY,ReworkZ,ReworkXY,ReworkXZ,ReworkYZ,ReworkXYZ] = Simulate_3var(CUT,SIGMA,A,B,Rework)
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
sig33 = sqrt(SIGMA(3,3));
LSLx = A(1);
LSLy = A(2);
LSLz = A(3);
USLx = B(1);
USLy = B(2);
USLz = B(3);

Finish = 0;
Scrap = 0;
ReworkX=0; ReworkY=0; ReworkZ=0;
ReworkXY=0; ReworkXZ=0; ReworkYZ=0;
ReworkXYZ=0;

PS = mvnrnd(CUT,SIGMA,Rework);
SPS = size(PS);
% 
% R1 = PS(:,1)>USLx;
% R2 = PS(:,2)>USLy;
% R3 = PS(:,3)>USLz;
% RM = [R1,R2,R3];
for i = 1:SPS(1)
    if PS(i,1)>=LSLx && PS(i,1)<=USLx && PS(i,2)>=LSLy && PS(i,2)<=USLy && PS(i,3)>=LSLz && PS(i,3)<=USLz % finish
        Finish  = Finish + 1;
    elseif PS(i,1)<LSLx || PS(i,2)<LSLy || PS(i,3)<LSLz % Scrap
        Scrap = Scrap + 1;
    elseif PS(i,1)>USLx && PS(i,2)>USLy && PS(i,3)>USLz % Rework x,y,z
        ReworkXYZ = ReworkXYZ + 1;
    elseif PS(i,1)>USLx && PS(i,2)>USLy                 % Rework x,y
        ReworkXY = ReworkXY + 1;    
    elseif PS(i,1)>USLx && PS(i,3)>USLz                 % Rework x,z
        ReworkXZ = ReworkXZ + 1;    
    elseif PS(i,2)>USLy && PS(i,3)>USLz                 % Rework y,z
        ReworkYZ = ReworkYZ + 1;    
    elseif PS(i,1)>USLx                                 % Rework x
        ReworkX = ReworkX + 1;
    elseif PS(i,2)>USLy                                 % Rework y
        ReworkY = ReworkY + 1;
    elseif PS(i,3)>USLz                                 % Rework z
        ReworkZ = ReworkZ + 1;
    end
end


