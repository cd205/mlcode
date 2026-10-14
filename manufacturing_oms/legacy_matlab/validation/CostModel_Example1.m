
function [Prt_Cost Prt_Rwork Prt_Scrap Prt_Total] = CostModel_Example1(PrtScrapProb,Fb1b2b3)
% Cost model for 3D Example 1



nparts = 100;
a_Cost = 2;
b_Cost = 10;
c_Cost = 3;
PrtRwork = 10;
PrtScrap = 50;

% feature cutting cost
a_cut_cost = a_Cost*nparts;
b_cut_cost = b_Cost*nparts;
c_cut_cost = c_Cost*nparts;
% a_cut_cost = a_Cost*(1 - a_RW - a_SCP)*nparts;
% b_cut_cost = b_Cost*(1 - b_RW - b_SCP)*nparts;
% c_cut_cost = c_Cost*(1 - c_RW - c_SCP)*nparts;
%% feature rework cost
% a_RW_cost = a_Cost*a_RW*nparts;
% b_RW_cost = b_Cost*b_RW*nparts;
% c_RW_cost = c_Cost*c_RW*nparts;
%% feature scrap cost
% a_SCP_cost = PrtScrap*a_SCP*nparts;
% b_SCP_cost = PrtScrap*b_SCP*nparts;
% c_SCP_cost = PrtScrap*c_SCP*nparts;

Prt_Cost = a_cut_cost + b_cut_cost + c_cut_cost;
Prt_Rwork = PrtRwork*(1-Fb1b2b3)*nparts;
Prt_Scrap = PrtScrap*(PrtScrapProb)*nparts;
% Prt_Rwork = (a_RW_cost + b_RW_cost + c_RW_cost) + PrtRwork*(1-Fb1b2b3)*nparts;
% Prt_Scrap = (a_SCP_cost + b_SCP_cost + c_SCP_cost) + PrtScrap*(PrtScrapProb)*nparts;

Prt_Total = Prt_Cost + Prt_Rwork + Prt_Scrap;