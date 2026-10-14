function [PumpCost] = PumpCostDetailed_SNQuad2d(MU,SIGMA,ALPHA,a,b,c,d) 

format long
%% Cost model
No_Comps = 100;
ScrapPrice = 1.2;
ReworkPrice_L = 0.6;
ReworkPrice_R = 0.8;
ConfPrice = 0.2;
fun = @(L,R) dmsn_quad2d(L,R,MU,SIGMA,ALPHA);

RW_L = quad2d(fun,b,5,c,d);
RW_R = quad2d(fun,a,b,d,5);
RW_LR = quad2d(fun,b,5,d,5);
Rwork_Total = RW_L + RW_R + RW_LR;
%if Rwork_Total > 1
%    Rwork_Total = 1;
%end
Scrap_Total = quad2d(fun,-5,a,-5,5) + quad2d(fun,a,5,-5,c);
% if Scrap_Total > 1
%     Scrap_Total = 1
% end
Conformance = 1 - Rwork_Total - Scrap_Total;
% if Conformance <= 0
%     PumpCost = No_Comps*ConfPrice*1000
% else
    Non_Conformance = 1 - Conformance;
    
    if Scrap_Total > 0 % Scrap cost
        ScrapCost = No_Comps*((1/(1-Scrap_Total))*ScrapPrice);
    else ScrapCost = 0;
    end
    
    if RW_L > 0 % Rework cost
        RW_L_cost = No_Comps*((1/(1-RW_L))*ReworkPrice_L)+No_Comps*0.5*((1/(1-RW_L))*ReworkPrice_R);
    else RW_L_cost = 0;
    end
    
    if RW_R > 0 % Rework cost
        RW_R_cost = No_Comps*((1/(1-RW_R))*ReworkPrice_R);
    else RW_R_cost = 0;
    end
    
    if RW_LR > 0 % Rework cost
        RW_LR_cost = No_Comps*((1/(1-RW_LR))*(ReworkPrice_L+ReworkPrice_R));
    else RW_LR_cost = 0;
    end
    ReworkCost = RW_L_cost + RW_R_cost + RW_LR_cost;
    
    if Conformance > 0 % Conformance cost
        ConfCost = No_Comps*ConfPrice*Conformance;
    else ConfCost = 0;
    end
    
    PumpCost = ScrapCost + ReworkCost + ConfCost;
%end