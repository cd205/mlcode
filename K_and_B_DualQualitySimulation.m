%% load some components and put the through K and B model to validate results
clear all
clc
close all
CUT = [5 5]
sig11 = 1.55;
sig22 = 1.55;
SIGMA = [sig11^2 0; 0 sig22^2]
A = [3 3];
B = [7 7];
LSLx = A(1);
LSLy = A(2);
USLx = B(1);
USLy = B(2);

n = 1000000;

[Finish,Scrap,ReworkXY,ReworkX,ReworkY] = KandBSimulate(CUT,SIGMA,A,B,n);
s1 = struct('Finish',Finish/n,'Scrap',Scrap/n,'ReworkXY',ReworkXY/n,...
            'ReworkX',ReworkX/n,'ReworkY',ReworkY/n)


RWXY = ReworkXY; RWX = ReworkX; RWY = ReworkY;
RWXY_bin = 0; RWX_bin = 0; RWY_bin = 0;
Fin2count = 0; Fin3count = 0; Fin4count = 0;
RWXYcount = 0; RWXcount = 0; RWYcount = 0;
Scrap2count = 0; Scrap3count = 0; Scrap4count = 0;
Scrap1count = Scrap;
count = 0;
while RWXY > 0 || RWX > 0 || RWY > 0 % If there is rework do the following
    [Fin2,Scr2,RWX2] = KandBSimulate_1Var(CUT(1),sig11,A(1),B(1),RWX);
    [Fin3,Scr3,RWY3] = KandBSimulate_1Var(CUT(2),sig22,A(2),B(2),RWY);
    [Fin4,Scr4,RWXY4,RWX4,RWY4] = KandBSimulate(CUT,SIGMA,A,B,RWXY);
    
    Finish = Finish + Fin2+Fin3+Fin4; % add rework to finish
    Scrap = Scrap + Scr2+Scr3+Scr4;   % add rework to scrap
    RWXY_bin = RWXY4;                % add rework to further rework x and y
    RWX_bin = RWX2 + RWX4;           % add rework to rework just x
    RWY_bin = RWY3 + RWY4;           % add rework to rework just y
    Fin2count = Fin2count + Fin2;
    Fin3count = Fin3count + Fin3;
    Fin4count = Fin4count + Fin4;
    RWXcount = RWXcount + RWX; 
    RWYcount = RWYcount + RWY;
    RWXYcount = RWXYcount + RWXY;
    Scrap2count = Scrap2count + Scr2;
    Scrap3count = Scrap3count + Scr3;
    Scrap4count = Scrap4count + Scr4;
    s2 = struct('Finish',Finish,'Scrap',Scrap,'RWXY_bin',RWXY_bin,...
        'RWX_bin',RWX_bin,'RWY_bin',RWY_bin);
    %figure(1)
    %bar([s2.Finish,s2.Scrap,s2.RWXY_bin,s2.RWX_bin,s2.RWY_bin]); grid on
    %set(gca,'XTickLabel',{'Finish','Scrap','RW_XY','RW_X','RW_Y'})
    %pause(0.0)
    RWXY = RWXY_bin;  RWXY_bin = 0; % If there are components left in
    RWX = RWX_bin;  RWX_bin = 0;  % Rework x y change varable for
    RWY = RWY_bin;  RWY_bin = 0;  % inputn into 'KandBSimulate' and
    % take them out of the rework x y bin
    FinsihANDScrap = Finish + Scrap;
    count = count+1;
end
format Short
f1 = struct('FinsihScrap',FinsihANDScrap,'Finish',Finish,'Scrap',Scrap,'Total_Rework_xy',RWXYcount,...
            'Total_Rework_x',RWXcount,'Total_Rework_y',RWYcount)

S1 = struct('f15',Finish/n,'f25',Fin2count/n,'f35',Fin3count/n,'f45',Fin4count/n,...
            'f16',Scrap/n,'f26',Scrap2count/n,'f36',Scrap3count/n,'f46',Scrap4count/n,...
            'm12',RWXcount/n,'m13',RWYcount/n,'m14',RWXYcount/n)

[f15,f25,f35,f45, m12,m13,m14, f16,f26,f36,f46, P1s, P2s] = KandBMarkov_DualChars(CUT,SIGMA,LSLx,LSLy,USLx,USLy);
RWJustX = 1 - normcdf(USLx,CUT(1),sig11);
RWJustY = 1 - normcdf(USLy,CUT(2),sig22);
CnJustX = normcdf(USLx,CUT(1),sig11)-normcdf(LSLx,CUT(1),sig11);
CnJustY = normcdf(USLy,CUT(2),sig22)-normcdf(LSLy,CUT(2),sig22);
ScJustX = normcdf(LSLx,CUT(1),sig11);
ScJustY = normcdf(LSLy,CUT(2),sig22);
SingleVar = struct('RWJustX',RWJustX,'RWJustY',RWJustY,...
    'CnJustX',CnJustX,'CnJustY',CnJustY,...
    'ScJustX',ScJustX,'ScJustY',ScJustY)
P1s = P1s
S3 = struct('f15',f15,'f25_p12',f25*(P1s(1)+(P1s(3)*(P1s(1)/(1-P1s(3))))),...
            'f35_p13',f35*(P1s(2)+(P1s(3)*(P1s(2)/(1-P1s(3))))),...
            'f35_AA',f35*(P1s(2)/(1-P1s(3))),...
            'f45_p14',P1s(3)*(P1s(4)/(1-P1s(3))),...
            'f45_AA', f45*(P1s(3)),...
            'f16',f16,'f26_p12',f26*(P1s(3)*(P1s(1)/(1-P1s(3)))+P1s(1)),...
            'f36_p13',f36*(P1s(3)*(P1s(2)/(1-P1s(3)))+P1s(2)),...
            'f46_p14',P1s(3)*(P1s(5)/(1-P1s(3))),...
            'm12',m12,'m13',m13,'m14',m14)
P1s(1)/((1-P2s(1))*(1-P1s(3)))
S4 = struct('f15',f15,'f25',f25,'f35',f35,'f45',f45,...
            'f16',f16,'f26',f26,'f36',f36,'f46',f46,...
            'm12',m12,'m13',m13,'m14',m14)
        
        m42 = P1s(1)/((1-RWJustX)*(1-P1s(3)))
        m43 = P1s(2)/((1-RWJustY)*(1-P1s(3)))
        M41 = 1/(1-P1s(3))