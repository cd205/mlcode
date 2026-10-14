function [v Rwork_P Scrap_P] = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL)

% this function returns a points on the cut-measure-cut distribtuion
% corresponding to 'xi'
% cd205@soton.ac.uk     -     Christopher Dodd     -     05/03/2013

% INPUTS -     xi:     an x-location on the distribution for which one wishes
%                      to evaluate the probability 
%              cut1:   Inital cut location
%              cut2:   Secondary cut location
%              sigma1: First cut process variation
%              sigma1: Second cut process variation
%              LSL:    Lower specification limit
%              USL:    Upper specification limit
%              Nom:    Nominal target value 

% OUTPUTS -    v:      Probability for the 'xi' location
% clear all
% close all
% clc
% xi = linspace(-5,10,100000);
% cut1 = 6.5
% cut2 = 5
% sigma1 = 1;
% sigma2 = 1;
% LSL = 3;
% USL = 7;

x1 = linspace(LSL-(10*(max(sigma1,sigma2))),USL+(10*max(sigma1,sigma2)),1000000);
NFun = @(x1) normpdf(x1,cut1,sigma1);
Cut1_Dist = NFun(x1);
SpecRange = [sum(x1<LSL),sum(x1<USL)];
ZeroVec_1 = zeros(1,(SpecRange(1))); % zeros before LSL
ZeroVec_2 = zeros(1,length(x1) - SpecRange(2)); % zeros after USL
ZeroVec_3 = zeros(1,length(x1) - length(ZeroVec_1)); % zeros from LSL to end
Cut1_InSpec = Cut1_Dist(SpecRange(1)+1:SpecRange(2)); % From LSL to USL
Cut1_Scrap = Cut1_Dist(1:SpecRange(1)); % from 0 to LSL
Cut1_InSpec = [ZeroVec_1, Cut1_InSpec, ZeroVec_2]; % pad with zeros
Cut1_Scrap = [Cut1_Scrap, ZeroVec_3];

Rwork_P = 1 - normcdf(USL,cut1,sigma1)
Scrap_P = normcdf(LSL,cut1,sigma1)
Inspec_P = 1 - Rwork_P - Scrap_P

v = (Rwork_P*normpdf(xi,cut2,sigma2)) + (1)*interp1(x1,Cut1_InSpec,xi,'spline')...
    + interp1(x1,Cut1_Scrap,xi,'spline');

% CD_FinalDist = trapz(xi,v)
%figure(1)
%plot(xi,v); grid on
% FinalScrap = trapz(x(x<LSL),FinalDist(1:SpecRange(1))) + Scrap_P ;
% FinalRwork = trapz(x(x>USL),FinalDist(SpecRange(2)+1:end));