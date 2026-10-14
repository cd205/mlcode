 

clear all
close all
clc
LSL = 3;
USL = 7;

cutvec = linspace(4,7,20);

for i = 1:length(cutvec)
    nom = cutvec(i)
    cut1 = cutvec(i);
    cut2 = 5.3;
    sigma1 = 1;
    sigma2 = sigma1;
    nparts = 1e6;
    xi = linspace(0,12,nparts);
    [s] = Fun_Cut_Measure_Cut_Dist_Plot(xi,cut1,cut2,sigma1,sigma2,LSL,USL);
    
   
    
    %% costs
    CutCost = 1;
    RworkCost = 1;
    RworkCostN = 1.2; 
    ScrapCost = 5;
    
    RworkCost_cut1 = s.Rwork_P*nparts*RworkCost;
    ScrapCost_cut1 = s.Scrap_P*nparts*ScrapCost;
    CutCost_cut1 = nparts*CutCost;
    
    RworkCost_cut2 = s.vRwork*(s.Rwork_P)*nparts*RworkCost;
    ScrapCost_cut2 = s.vScrap*(s.Rwork_P)*nparts*ScrapCost;
    
    TotalRworkCost(i) =  RworkCost_cut1 + RworkCost_cut2;
    TotalScrapCost(i) =  ScrapCost_cut1 + ScrapCost_cut2;
    TotalCost(i) = CutCost_cut1 + RworkCost_cut1+RworkCost_cut2...
        + ScrapCost_cut1+ScrapCost_cut2;
    
    
    %% Normal dist costs
    
    NornRworkCost(i) = (1-normcdf(USL,nom,sigma1))*nparts*RworkCostN;
    NormScrapCost(i) = normcdf(LSL,nom,sigma1)*nparts*ScrapCost;
    NormCutCost(i) = nparts*CutCost;
    NormTotalCost(i) = NornRworkCost(i) + NormScrapCost(i) + NormCutCost(i);
end
 figure;
    plot(xi,normpdf(xi,5,sigma1),'color',[.6 .6 .6],'LineWidth',2); hold on
    plot(xi,normpdf(xi,cut1,sigma1),'-b','LineWidth',2); hold on
    plot(xi,s.v,'k-','LineWidth',2); grid on
    line([7 7],[0 max(s.v)],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
    line([3 3],[0 max(s.v)],'color',[1 0 0],'LineWidth',2,'LineStyle','--')

figure;
%plot(cutvec,NormTotalCost,'.-'); hold on
plot(cutvec,TotalCost,'r.-','LineWidth',2); grid on
xlabel('cut 1')
ylabel('Total Manufacturing Cost')
