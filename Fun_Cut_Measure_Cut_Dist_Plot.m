function [s] = Fun_Cut_Measure_Cut_Dist_Plot(xi,cut1,cut2,sigma1,sigma2,LSL,USL)

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


x1 = xi;% linspace(LSL-(10*(max(sigma1,sigma2))),USL+(10*max(sigma1,sigma2)),1e6);
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

Rwork_P = 1 - normcdf(USL,cut1,sigma1);
Scrap_P = normcdf(LSL,cut1,sigma1);
Inspec_P = 1 - Rwork_P - Scrap_P;

v = (Rwork_P*normpdf(xi,cut2,sigma2)) + (1)*interp1(x1,Cut1_InSpec,xi)...
    + interp1(x1,Cut1_Scrap,xi);

CD_FinalDist = trapz(xi,v);
vScrap = trapz(x1(x1<LSL),v(1:SpecRange(1)));
vRwork = trapz(x1(x1>USL),v(SpecRange(2)+1:end));


s = struct('Rwork_P',Rwork_P,'Scrap_P',Scrap_P,'Inspec_P',Inspec_P,...
    'CD_FinalDist',CD_FinalDist,'vScrap',vScrap,...
    'vRwork',vRwork,'Cut1_Dist',Cut1_Dist,'v',v);
figure(1)
plot(xi,v)
grid on
