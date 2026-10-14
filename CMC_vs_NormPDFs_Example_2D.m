% cut -measure cut example

%% normal distributions
nom = 5
sigma1 = 1
sigma2 = sigma1
nparts = 1000

Fb1b2 = mvncdf([7 7],[nom nom],[sigma1 sigma2]);
Fb1a2 = mvncdf([20 3],[nom nom],[sigma1 sigma2]);
Fa1b2 = mvncdf([3 20],[nom nom],[sigma1 sigma2]);
Fa1a2 =mvncdf([3 3],[nom nom],[sigma1 sigma2]);

ScrapProb = Fa1b2 + Fb1a2 - Fa1a2
ConformProb = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2
RworkProb = 1 - Fb1b2

PriceScrap = 5
PriceRwork = 1
PriceConformance = 1

TotalCost_Norm = ScrapProb*nparts*PriceScrap +...
    RworkProb*nparts*PriceRwork +...
    nparts*PriceConformance

%% 

% Cut measure cut

RworkP_a = 0.1587
ScrapP_a = 0.0013
RworkP_b = 0.1587
ScrapP_b = 0.0013

CuttingCost = nparts*PriceConformance
ReworkCost_cut1  = nparts*((RworkP_a+RworkP_b)/2)*PriceRwork
ScrapCost_cut1 =  nparts*((ScrapP_a+ScrapP_b)/2)*PriceScrap

Fb1b2 = 0.9933
Fb1a2 = 0.0049
Fa1b2 = 0.0049
Fa1a2 = 0.0098

Scrap_cut2  = Fb1a2+Fa1b2-Fa1a2
Rework_cut2 = 1 - Fb1b2

ReworkCost_cut2 = nparts*Rework_cut2*PriceRwork 
ScrapCost_cut2 = nparts*Scrap_cut2*PriceScrap

TotalCost_CMC = CuttingCost + ReworkCost_cut1 + ScrapCost_cut1 +...
    ReworkCost_cut2 + ScrapCost_cut2