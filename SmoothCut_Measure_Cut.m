% This produces a cut-measure-cut distribution (FinalDist) it is a
% combination of a weighted truncated gaussian plus a gaussian 
clear all
close all
clc
LSL = 3;
USL = 7;
Nom = 5;
% first cut
cut1_vec = linspace(5,8,20)
for i = 1:length(cut1_vec)
    cut1 = cut1_vec(i);
    cut2 = 5;
    sigma1 = 1;
    sigma2 = 1;
    
    
    x = linspace(0,10,100000);
    NFun = @(x) normpdf(x,cut1,sigma1);
    Cut1_Dist = NFun(x);
    SpecRange = [sum(x<LSL),sum(x<USL)];
    ZeroVec_1 = zeros(1,(SpecRange(1)));
    ZeroVec_2 = zeros(1,length(x) - SpecRange(2));
    Cut1_InSpec = Cut1_Dist(SpecRange(1)+1:SpecRange(2));
    Cut1_InSpec = [ZeroVec_1, Cut1_InSpec, ZeroVec_2];
    %Cut1_InSpec = padarray(Cut1_InSpec,[SpecRange(2) length(x) - SpecRange(2)])
    plot(x,Cut1_Dist,'m-','LineWidth',2); hold on
    plot(x,Cut1_InSpec,'r-','LineWidth',2); hold on
    Rwork_P = 1 - normcdf(USL,cut1,sigma1)
    Scrap_P = normcdf(LSL,cut1,sigma1)
    Inspec_P = 1 - Rwork_P - Scrap_P
    
    FinalDist = (Rwork_P*normpdf(x,cut2,sigma2)) + Cut1_InSpec;
    %plot(x,FinalDist,'m-'); grid on; hold on
    line([7 7],[0 max(FinalDist)],'color',[0 1 0],'LineWidth',2,'LineStyle','--')
    line([3 3],[0 max(FinalDist)],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
    
    CD_FinalDist = trapz(x,FinalDist)
    FinalScrap(i) = trapz(x(x<LSL),FinalDist(1:SpecRange(1))) + Scrap_P
    FinalRwork(i) = trapz(x(x>USL),FinalDist(SpecRange(2)+1:end))
    
    xi = linspace(0.5,10,1000);
    [v] = Fun_Cut_Measure_Cut_Dist(xi,cut1,cut2,sigma1,sigma2,LSL,USL,Nom);
    plot(xi,v,'k-','LineWidth',2); hold on, grid on
    plot(xi,normpdf(xi,5,1),'-','LineWidth',2)
    ylabel('Probability Density')
    xlabel('Dimension')
end

figure(2)
plot(cut1_vec,FinalScrap,'r-','LineWidth',2); hold on
plot(cut1_vec,FinalRwork,'-','LineWidth',2); grid on
ylabel('Probabilty')
xlabel('cut1')
legend('Probabilty of Scrap','Probability of Rework')

