function [C_tot,C_srp,C_rwk] = Pump_L_R_CostModel(P_con,P_srp,P_rwk)

No_comps = 100;

Cost_con = 2;
Cost_srp = 6;
Cost_rwk = 2;

C_con = No_comps*Cost_con*P_con;
if P_srp > 0
    C_srp = No_comps * Cost_srp * (1/(1.01-P_srp));
else C_srp = 0;
end

if P_rwk > 0
    C_rwk = No_comps * Cost_rwk * (1/(1.01-P_rwk));
else C_rwk = 0;
end

C_tot = C_con + C_srp + C_rwk;