function [Cost] = Fun_4CUT_CMC(cut)
% clear all
% close all
% clc
sigma = 1;
USL = 7;
LSL = 3;

%cut1 = linspace(2,8,100)
%cut2 = cut1

%for i = 1:length(cut1)
%    for j = 1:length(cut2)
%        cut = [cut1(i) cut2(j) 5 5];
        % 1st iteration
        Scrap1 = normcdf(LSL,cut(1),sigma);
        Confm1 = normcdf(USL,cut(1),sigma) - normcdf(LSL,cut(1),sigma);
        Rwork1 = 1 - normcdf(USL,cut(1),sigma);
        
        % 2nd iteration
        Scrap2 = Rwork1*normcdf(LSL,cut(2),sigma);
        Confm2 = Rwork1*(normcdf(USL,cut(2),sigma) - normcdf(LSL,cut(2),sigma));
        Rwork2 = Rwork1*(1 - normcdf(USL,cut(2),sigma));
        
        % 3rd iteration
        Scrap3 = Rwork2*normcdf(LSL,cut(3),sigma);
        Confm3 = Rwork2*(normcdf(USL,cut(3),sigma) - normcdf(LSL,cut(3),sigma));
        Rwork3 = Rwork2*(1 - normcdf(USL,cut(3),sigma));
        
        % 4th iteration
        Scrap4 = Rwork3*normcdf(LSL,cut(4),sigma);
        Confm4 = Rwork3*(normcdf(USL,cut(4),sigma) - normcdf(LSL,cut(4),sigma));
        Rwork4 = Rwork3*(1 - normcdf(USL,cut(4),sigma));
        
        TOT_Confrom = Confm1 + Confm2 + Confm3 + Confm4;
        TOT_Scrap = Scrap1+Scrap2+Scrap3+Scrap4;
        TOT_Rwork = Rwork1 + Rwork2 + Rwork3 + Rwork4;
        
        TOT = TOT_Confrom + TOT_Scrap;
        
        PC = 5; SC = 10; RC = 2;
        
        Cost = PC + SC*(TOT_Scrap) + RC*(TOT_Rwork) + 50*(1-TOT);
 %   end
%end

%surf(cut1,cut2,Cost)
%xlabel('cut 1')
%ylabel('cut 2')

%[d p]= find(Cost==(min(min(Cost))))