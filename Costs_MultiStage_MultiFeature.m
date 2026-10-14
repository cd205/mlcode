% Multi Stage and Multi Feature costs
clear all
close all
clc
%% EXAMPLEs
% %% 1 var example
% SP= 120;
% PC = [45];
% U = [7]; L = [3];
% MU = [4.5];
% sig11 = 1.7; SIGMA = [sig11^2];
% S_Cost = [3,3]; R_Cost = [3];  % S_Cost has two elements as S_Cost(1) is 
% % the cost from Iitial-to-scrap, S_Cost(2) is cost of Rework-to-scrap.
% % Note initial processing and rework are considered two seperate processes
% % in Dodd [2014] even though bowling [2004] and Selim [2011] treat them as
% % the same process (hence use only 1 scrap cost.
% [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU,SIGMA,U,L,R_Cost,S_Cost)
% EP1 = SP*F_stageC - (PC + Sri + Rwi)
% 
% sigs = [sig11]; rho = 0
% [F_stageC,pIC,Rwi,Sri] = StageCostFun(MU,sigs,rho,U,L,R_Cost,S_Cost);
% EP2 = SP*F_stageC - (PC + Sri + Rwi)
% 
% '-------------------- end of 1 var -----------------------------'



% %% 2 var example
% SP= 120;
% PC = [45];
% U = [12 17]; L = [8 13];
% MU = [10.55137 15.60796];
% sig11 = 1; sig22 = 1;
% SIGMA = [sig11^2 0;0 sig22^2];
% S_Cost = [8 9 11 14]; R_Cost = [15 12 20];
% [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU,SIGMA,U,L,R_Cost,S_Cost);
% EP1 = SP*F_stageC - (PC + Sri + Rwi)
% 
% sigs = [sig11 sig22]; rho = 0
% [F_stageC,pIC,Rwi,Sri] = StageCostFun(MU,sigs,rho,U,L,R_Cost,S_Cost);
% EP2 = SP*F_stageC - (PC + Sri + Rwi)
% '-------------------- end of 2 var -----------------------------'


% 
% %% 3 var exmaple
% SP= 120;
% PC = [45];
% U = [7 7 7]; L = [3 3 3];
% MU = [6 5.5 5];
% sig11 = 2; sig22 = 2.5; sig33 = 3;
% SIGMA = [sig11^2 0 0; 0 sig22^2 0; 0 0 sig33^2]; 
% S_Cost = [1 2 3 4 5 6 7 8]; R_Cost = [2.2 3.3 4.4 5.5 6.6 7.7 8.8];
% [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU,SIGMA,U,L,R_Cost,S_Cost);
% EP1 = SP*F_stageC - (PC + Sri + Rwi)
% 
% sigs = [sig11 sig22 sig33]; rho = 0;
% [F_stageC,pIC,Rwi,Sri] = StageCostFun(MU,sigs,rho,U,L,R_Cost,S_Cost);
% EP2 = SP*F_stageC - (PC + Sri + Rwi)
% 
% '-------------------- end of 3 var -----------------------------'


% 
% 
%% 2 Stage, single feature production
SP= 120;
PC = [25,20];
U_cell{1} = [12]; U_cell{2} = [17]; L_cell{1} = [8]; L_cell{2} = [13];
MU_cell{1} = [10.466]; MU_cell{2} = [15.575];
sig11 = 1.0; sig22 = 1.0;
SIGMA_cell{1} = [sig11^2]; SIGMA_cell{2} = [sig22^2];
S_Cost_cell{1} = [10,10]; S_Cost_cell{2} = [27,27]; % Scrap cost are 2 element vectors
% since rework is modelled as an extra state but rework-to-scrap cost is
% same as inital-to-scrap cost
R_Cost_cell{1} = [15]; R_Cost_cell{2} = [12];

F_stageC_vec(1) = 1;
for i = 1:length(U_cell) 
    [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU_cell{i},SIGMA_cell{i},U_cell{i},...
        L_cell{i},R_Cost_cell{i},S_Cost_cell{i});
    F_stageC_vec(i+1) = F_stageC; % store conformance from previous stage
    RwCost_vec(i) = Rwi*F_stageC_vec(i);
    SrCost_vec(i) = Sri*F_stageC_vec(i);
    ProdCost(i) = (PC(i) + Sri + Rwi)*prod(F_stageC_vec(1:i));
    PC(i)*prod(F_stageC_vec(1:i));
    Sri*prod(F_stageC_vec(1:i));
    Rwi*prod(F_stageC_vec(1:i));
end

ProdCost1 = sum(ProdCost)
EP1 = SP*(prod([F_stageC_vec(2:end)])) - sum(ProdCost)
SP*(prod([F_stageC_vec(2:end)]))
% '------------------------------ NEW METHOD -------------------------'
clear F_stageC_vec; clear RwCost_vec; clear SrCost_vec; clear ProdCost_vec 

rho = 0;
sigs_cell{1} = [sig11]; sigs_cell{2} = [sig22];
F_stageC_vec(1) = 1;
for i = 1:length(U_cell) 
    [F_stageC,pIC,Rwi,Sri] = StageCostFun(MU_cell{i},sigs_cell{i},rho,U_cell{i},...
        L_cell{i},R_Cost_cell{i},S_Cost_cell{i});
    F_stageC_vec(i+1) = F_stageC; % store conformance from previous stage
    RwCost_vec(i) = Rwi*F_stageC_vec(i);
    SrCost_vec(i) = Sri*F_stageC_vec(i);
    ProdCost(i) = (PC(i) + Sri + Rwi)*prod(F_stageC_vec(1:i));
end
ProdCost2 = sum(ProdCost)
EP2 = SP*(prod([F_stageC_vec(2:end)])) - sum(ProdCost)




%% 2 Stage, dual feature production
SP = 120;
PC = [45,0];
U_cell{1} = [12 17]; U_cell{2} = [15 12];
L_cell{1} = [8 13]; L_cell{2} = [5 6];
MU_cell{1} = [10.55137 15.60796]; 
MU_cell{2} = [10 9];
sig11 = 1; sig22 = 1; sig33 = 0.5; sig44 = 0.5;
rho1 = 0.0; rho2 = 0.0;
SIGMA_cell{1} = [sig11^2 rho1*sig11*sig22;rho1*sig11*sig22 sig22^2];
SIGMA_cell{2} = [sig33^2 rho2*sig33*sig44;rho2*sig33*sig44 sig44^2];
S_Cost_cell{1} = [8,9,11,14];
S_Cost_cell{2} = [7,10,7,10]; 
R_Cost_cell{1} = [15 12 20];
R_Cost_cell{2} = [12,13,25];

F_stageC_vec(1) = 1
for j = 1:2
    %for i = 1:length(U_cell)
        [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU_cell{j},SIGMA_cell{j},U_cell{j},L_cell{j},R_Cost_cell{j},S_Cost_cell{j})
        F_stageC_vec(j+1) = F_stageC % store conformance from previous stage
        RwCost_vec(j) = Rwi*F_stageC_vec(j)
        SrCost_vec(j) = Sri*F_stageC_vec(j)
        ProdCost(j) = (PC(j) + Sri + Rwi)*prod(F_stageC_vec(1:j))
    %end
end
ProdCost = sum(ProdCost)
EP1 = SP*(prod([F_stageC_vec(2:end)])) - sum(ProdCost)
% 
% 
% '------------------------------ NEW METHOD -------------------------'
clear F_stageC_vec; clear RwCost_vec; clear SrCost_vec; clear ProdCost_vec 
rho = 0;
sigs_cell{1} = [sig11 sig22]; sigs_cell{2} = [sig33 sig44];
F_stageC_vec(1) = 1;
for j = 1:2
    [F_stageC,pIC,Rwi,Sri] = StageCostFun(MU_cell{j},sigs_cell{j},rho,U_cell{j},...
        L_cell{j},R_Cost_cell{j},S_Cost_cell{j});
    F_stageC_vec(j+1) = F_stageC; % store conformance from previous stage
    RwCost_vec(j) = Rwi*F_stageC_vec(j);
    SrCost_vec(j) = Sri*F_stageC_vec(j);
    ProdCost(j) = (PC(j) + Sri + Rwi)*prod(F_stageC_vec(1:j));
end
ProdCost2 = sum(ProdCost)
EP2 = SP*(prod([F_stageC_vec(2:end)])) - sum(ProdCost)







