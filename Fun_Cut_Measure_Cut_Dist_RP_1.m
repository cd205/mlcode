function [v] = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL)

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

% OUTPUTS -    v:            Probability for the 'xi' location


x1 = linspace(LSL-(5*(max(sigma1,sigma2))),USL+(5*max(sigma1,sigma2)),100000);
NFun = @(x1) normpdf(x1,cut1,sigma1);
Cut1_Dist = NFun(x1);
SpecRange = [sum(x1<LSL),sum(x1<USL)];
ZeroVec_1 = zeros(1,(SpecRange(1)));
ZeroVec_2 = zeros(1,length(x1) - SpecRange(2));
Cut1_InSpec = Cut1_Dist(SpecRange(1)+1:SpecRange(2));
Cut1_InSpec = [ZeroVec_1, Cut1_InSpec, ZeroVec_2];

Rwork_P = 1 - normcdf(USL,cut1,sigma1);
Scrap_P = normcdf(LSL,cut1,sigma1);
Inspec_P = 1 - Rwork_P - Scrap_P;

v = (Rwork_P*normpdf(xi,cut2,sigma2)) + interp1(x1,Cut1_InSpec,xi);

%CD_FinalDist = trapz(x,FinalDist);
%FinalScrap = trapz(x(x<LSL),FinalDist(1:SpecRange(1))) + Scrap_P ;
%FinalRwork = trapz(x(x>USL),FinalDist(SpecRange(2)+1:end));