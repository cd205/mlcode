function [TotalCost] = Fun_Cut_Measure_Cut_Dist_Cost(cut1,cut2)

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
xi = linspace(-2,12,1e4);
sigma1 = 1;
sigma2 = sigma1;
LSL = 3;
USL = 7;
CutCost = 1;
RworkCost = 1;
ScrapCost = 5;
nparts = 1e6;


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

RworkCost_cut1 = Rwork_P*nparts*RworkCost;
ScrapCost_cut1 = s.Scrap_P*nparts*ScrapCost;
CutCost_cut1 = nparts*CutCost;

RworkCost_cut2 = vRwork*(Rwork_P)*nparts*RworkCost;
ScrapCost_cut2 = vScrap*(Rwork_P)*nparts*ScrapCost;

TotalRworkCost =  RworkCost_cut1 + RworkCost_cut2;
TotalScrapCost =  ScrapCost_cut1 + ScrapCost_cut2;
TotalCost = CutCost_cut1 + RworkCost_cut1+RworkCost_cut2...
    + ScrapCost_cut1+ScrapCost_cut2;