%% load some components and put the through K and B model to validate results
clear all
clc
close all
CUT = [5 5 5]
sig11 = 2;
sig22 = 2;
sig33 = 2;
SIGMA = [sig11^2 0 0; 0 sig22^2 0; 0 0 sig33^2]
A = [3 3 3];
B = [7 7 7];
LSLx = A(1);
LSLy = A(2);
LSLz = A(3);
USLx = B(1);
USLy = B(2);
USLz = B(3);

n = 10000000;

% First processing cut
[PS,Finish,Scrap,ReworkX,ReworkY,ReworkZ,ReworkXY,ReworkXZ,ReworkYZ,ReworkXYZ]= Simulate_3var(CUT,SIGMA,A,B,n);
s1 = struct('Finish',Finish,'Scrap',Scrap,...
            'ReworkX',ReworkX,'ReworkY',ReworkY,'ReworkZ',ReworkZ,...
            'ReworkXY',ReworkXY,'ReworkXZ',ReworkXZ,'ReworkYZ',ReworkYZ,...
            'ReworkXYZ',ReworkXYZ)
% check total adds up to n        
Total = sum([Finish,Scrap,ReworkX,ReworkY,ReworkZ,ReworkXY,ReworkXZ,ReworkYZ,ReworkXYZ])
PS;

RWX = ReworkX; RWY = ReworkY; RWZ = ReworkZ;
RWXY = ReworkXY; RWXZ = ReworkXZ; RWYZ = ReworkYZ; 
RWXYZ = ReworkXYZ; 

RWX_bin = 0; RWY_bin = 0; RWZ_bin = 0;
RWXY_bin = 0; RWXZ_bin = 0; RWYZ_bin = 0;
RWXYZ_bin = 0; 

RWXcount = 0; RWYcount = 0; RWZcount = 0;
RWXYcount = 0; RWXZcount = 0; RWYZcount = 0;
RWXYZcount = 0; 

Fin2count = 0; Fin3count = 0; Fin4count = 0; Fin5count = 0; Fin6count = 0; Fin7count = 0; Fin8count = 0;

Scrap1count = Scrap;
Scrap2count = 0; Scrap3count = 0; Scrap4count = 0; Scrap5count = 0; Scrap6count = 0; Scrap7count = 0; Scrap8count = 0;


count = 0
while RWX > 0 || RWY > 0 || RWZ > 0 || RWXY > 0 || RWXZ > 0 || RWYZ > 0 || RWXYZ > 0  % If there is rework do the following
    [Fin2,Scr2,RWX2] = KandBSimulate_1Var(CUT(1),sig11,A(1),B(1),RWX); % Stage 2
    [Fin3,Scr3,RWY3] = KandBSimulate_1Var(CUT(2),sig22,A(2),B(2),RWY); % Stage 3
    [Fin4,Scr4,RWZ4] = KandBSimulate_1Var(CUT(3),sig33,A(3),B(3),RWZ); % Stage 4
    % Stage 5 (X,Y)
    [Fin5,Scr5,RWXY5,RWX5,RWY5] = KandBSimulate([CUT(1),CUT(2)],[sig11,0;0,sig22],[A(1),A(2)],[B(1),B(2)],RWXY);
    % Stage 6 (X,Z)
    [Fin6,Scr6,RWXZ6,RWX6,RWZ6] = KandBSimulate([CUT(1),CUT(3)],[sig11,0;0,sig33],[A(1),A(3)],[B(1),B(3)],RWXZ);
    % Stage 7 (Y,Z)
    [Fin7,Scr7,RWYZ7,RWY7,RWZ7] = KandBSimulate([CUT(2),CUT(3)],[sig22,0;0,sig33],[A(2),A(3)],[B(2),B(3)],RWYZ);
    % Stage 8 (X,Y,Z)
    [PS,Fin8,Scr8,RWX8,RWY8,RWZ8,RWXY8,RWXZ8,RWYZ8,RWXYZ8] = Simulate_3var(CUT,SIGMA,A,B,RWXYZ);
    
    
    Finish = Finish + Fin2+Fin3+Fin4+Fin5+Fin6+Fin7+Fin8; % add rework to finish
    Scrap = Scrap + Scr2+Scr3+Scr4+Scr5+Scr6+Scr7+Scr8;   % add rework to scrap
    RWX_bin = RWX2+RWX5+RWX6+RWX8;              % add rework to rework just x
    RWY_bin = RWY3+RWY5+RWY7+RWY8;              % add rework to rework just y
    RWZ_bin = RWZ4+RWZ6+RWZ7+RWZ8;              % add rework to rework just y
    RWXY_bin = RWXY5 + RWXY8;                   % add rework to further rework x and y
    RWXZ_bin = RWXZ6 + RWXZ8;                   % add rework to further rework x and z
    RWYZ_bin = RWYZ7 + RWYZ8;                   % add rework to further rework y and z
    RWXYZ_bin = RWXYZ8;                         % add rework to further rework x, y and z
    
    Fin2count = Fin2count + Fin2;
    Fin3count = Fin3count + Fin3;
    Fin4count = Fin4count + Fin4;
    Fin5count = Fin5count + Fin5;
    Fin6count = Fin6count + Fin6;
    Fin7count = Fin7count + Fin7;
    Fin8count = Fin8count + Fin8;
    
    RWXcount = RWXcount + RWX; 
    RWYcount = RWYcount + RWY;
    RWZcount = RWZcount + RWZ;
    RWXYcount = RWXYcount + RWXY;
    RWXZcount = RWXZcount + RWXZ;
    RWYZcount = RWYZcount + RWYZ;
    RWXYZcount = RWXYZcount + RWXYZ;
    
    Scrap2count = Scrap2count + Scr2;
    Scrap3count = Scrap3count + Scr3;
    Scrap4count = Scrap4count + Scr4;
    Scrap5count = Scrap5count + Scr5;
    Scrap6count = Scrap6count + Scr6;
    Scrap7count = Scrap7count + Scr7;
    Scrap8count = Scrap8count + Scr8;
    
    s2 = struct('Finish',Finish,'Scrap',Scrap,...
        'RWX_bin',RWX_bin,'RWY_bin',RWY_bin','RWZ_bin',RWZ_bin',...
        'RWXY_bin',RWXY_bin,'RWXZ_bin',RWXZ_bin,'RWYZ_bin',RWYZ_bin,...
        'RWXYZ_bin',RWXYZ_bin)
    %figure(1)
    %bar([s2.Finish,s2.Scrap,s2.RWXY_bin,s2.RWX_bin,s2.RWY_bin]); grid on
    %set(gca,'XTickLabel',{'Finish','Scrap','RW_XY','RW_X','RW_Y'})
    %pause(0.0)
    
    % If there are components still to rework in any of the rework bins, 
    % set the RW imput equal to the number of components in the RW bin.  
    % These are fed back into the 'KandBSimulate_1Var', KandBSimulate' and
    % 'Simulate_3var' 
    RWX = RWX_bin;  RWX_bin = 0;   
    RWY = RWY_bin;  RWY_bin = 0;  
    RWZ = RWZ_bin;  RWZ_bin = 0;
    RWXY = RWXY_bin;  RWXY_bin = 0;
    RWXZ = RWXZ_bin;  RWXZ_bin = 0;
    RWYZ = RWYZ_bin;  RWYZ_bin = 0;
    RWXYZ = RWXYZ_bin;  RWXYZ_bin = 0;
    
    FinsihANDScrap = Finish + Scrap;
    count = count+1
end
% format Short
% f1 = struct('FinsihScrap',FinsihANDScrap,'Finish',Finish,'Scrap',Scrap,'Total_Rework_xy',RWXYcount,...
%             'Total_Rework_x',RWXcount,'Total_Rework_y',RWYcount)
% 
S1 = struct('f19',Finish/n,'f29',Fin2count/n,'f39',Fin3count/n,'f49',Fin4count/n,...
            'f59',Fin5count/n,'f69',Fin6count/n,'f79',Fin7count/n,'f89',Fin8count/n,...
            'f110',Scrap/n,'f210',Scrap2count/n,'f310',Scrap3count/n,'f410',Scrap4count/n,...
            'f510',Scrap5count/n,'f610',Scrap6count/n,'f710',Scrap7count/n,'f810',Scrap8count/n,...
            'm12',RWXcount/n,'m13',RWYcount/n,'m14',RWXYcount/n)
% 
% [f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s, P2s] = KandBMarkov_DualChars(CUT,SIGMA,LSLx,LSLy,USLx,USLy)
% RWJustX = 1 - normcdf(USLx,CUT(1),sig11);
% RWJustY = 1 - normcdf(USLy,CUT(2),sig22);
% CnJustX = normcdf(USLx,CUT(1),sig11)-normcdf(LSLx,CUT(1),sig11);
% CnJustY = normcdf(USLy,CUT(2),sig22)-normcdf(LSLy,CUT(2),sig22);
% ScJustX = normcdf(LSLx,CUT(1),sig11);
% ScJustY = normcdf(LSLy,CUT(2),sig22);
% SingleVar = struct('RWJustX',RWJustX,'RWJustY',RWJustY,...
%     'CnJustX',CnJustX,'CnJustY',CnJustY,...
%     'ScJustX',ScJustX,'ScJustY',ScJustY)
% P1s = P1s
% S3 = struct('f15',f15,'f25_p12',f25*(P1s(1)+(P1s(3)*(P1s(1)/(1-P1s(3))))),...
%             'f35_p13',f35*(P1s(2)+(P1s(3)*(P1s(2)/(1-P1s(3))))),...
%             'f35_AA',f35*(P1s(2)/(1-P1s(3))),...
%             'f45_p14',P1s(3)*(P1s(4)/(1-P1s(3))),...
%             'f45_AA', f45*(P1s(3)),...
%             'f16',f16,'f26_p12',f26*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
%             'f36_p13',f36*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2)),...
%             'f46_p14',P1s(3)*(P1s(5)/(1-P1s(3))),...
%             'm12',m12,'m13',m13,'m14',m14)
% P1s(1)/((1-P2s(1))*(1-P1s(3)))
% S4 = struct('f15',f15,'f25',f25,'f35',f35,'f45',f45,...
%             'f16',f16,'f26',f26,'f36',f36,'f46',f46,...
%             'm12',m12,'m13',m13,'m14',m14)
%         
%         m42 = P1s(1)/((1-RWJustX)*(1-P1s(3)))
%         m43 = P1s(2)/((1-RWJustY)*(1-P1s(3)))
%         M41 = 1/(1-P1s(3))