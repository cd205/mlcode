function [Prt_Cost Prt_Rwork_Cost Prt_Scrap_Cost Prt_Total_Cost] = CostModel_CMC_Example1(RW_vec,M11,F13)
% Cost model for 3D Example 1



nparts = 100;
L_Cost = 2;
b_Cost = 10;
c_Cost = 3;
PrtRwork = 5;
PrtScrap = 50;


L_cut_cost = (L_Cost + L_Cost*L_RW)*nparts; % this is the cost of the fist
% cut and second cut, there may still be scrap and rework after this stage
% b_cut_cost = (b_Cost + b_Cost*b_RW)*nparts;
% c_cut_cost = (c_Cost + c_Cost*c_RW)*nparts;

% % feature rework cost
% a_RW_cost = a_Cost*a_RW*nparts;
% b_RW_cost = b_Cost*b_RW*nparts;
% c_RW_cost = c_Cost*c_RW*nparts;
% % feature scrap cost
% a_SCP_cost = PrtScrap*a_SCP*nparts;
% b_SCP_cost = PrtScrap*b_SCP*nparts;
% c_SCP_cost = PrtScrap*c_SCP*nparts;

% Prt_Cost = a_cut_cost + b_cut_cost + c_cut_cost;

% Prt_Rwork = PrtRwork*(1-Fb1b2b3)*nparts;
% Prt_Scrap = PrtScrap*(PrtScrapProb)*nparts;
% Prt_Rwork_Cost = (a_RW_cost + b_RW_cost + c_RW_cost) + PrtRwork*(1-Fb1b2b3)*nparts;
% Prt_Scrap_Cost = (a_SCP_cost + b_SCP_cost + c_SCP_cost) + PrtScrap*(PrtScrapProb)*nparts;

L_scrap_cost = L_Scp*Stage_PartCost*nparts; % part cost is the value fo the part at this stage

Prt_Rwork_Cost = PrtRwork*(m11-1)*nparts;
Prt_Scrap_Cost = PrtScrap*f13*nparts;
Prt_Total_Cost = Prt_Cost + Prt_Rwork_Cost + Prt_Scrap_Cost;