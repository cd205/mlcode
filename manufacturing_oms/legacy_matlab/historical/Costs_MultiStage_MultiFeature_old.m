% Multi Stage and Multi Feature costs
clear all
clc
%% EXAMPLEs
% 1 var example
% SP= 120
% U = [7]; L = [3];
% MU = [4.5];
% sig11 = 1.7; SIGMA = [sig11^2];
% S_Cost = [3,3]; R_Cost = [3];
% [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU,SIGMA,U,L,R_Cost,S_Cost)
% '-------------------- end of 1 var -----------------------------'

% 2 var example
SP= 120;
PC = [45];
U = [12 17]; L = [8 13];
MU = [12 15.5291];
sig11 = 1; sig22 = 1;
SIGMA = [sig11^2 0;0 sig22^2];
S_Cost = [8 9 11 14]; R_Cost = [0 15 12 20];
[F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU,SIGMA,U,L,R_Cost,S_Cost)
EP1 = SP*F_stageC - (PC + Sri + Rwi)

sigs = [sig11 sig22]; rho = 0
[F_stageC,pIC,Rwi,Sri] = StageCostFun(MU,sigs,rho,U,L,R_Cost,S_Cost)
EP2 = SP*F_stageC - (PC + Sri + Rwi)


'-------------------- end of 2 var -----------------------------'

% % 3 var exmaple
% U = [7 7 7]; L = [3 3 3];
% MU = [6 5.5 5];
% SIGMA = [2 0 0; 0 2.5 0; 0 0 3]; 
% S_Cost = [1 2 3 4 5 6 7 8]; R_Cost = [2.2 3.3 4.4 5.5 6.6 7.7 8.8];
% [pIC,Rwi,Sri] = StageCostFun_old(MU,SIGMA,U,L,R_Cost,S_Cost);
% EP = SP*F_stageC - (PC + Sri + Rwi)
% 
% 
% %% 2 Stage, single feature production
% PC = [5,5];
% U_cell{1} = [7]; U_cell{2} = [7]; L_cell{1} = [3]; L_cell{2} = [3];
% MU_cell{1} = [5]; MU_cell{2} = [5];
% sig11 = 2.5; sig22 = 2.5;
% SIGMA_cell{1} = [sig11^2]; SIGMA_cell{2} = [sig22^2];
% S_Cost_cell{1} = [5,5]; S_Cost_cell{2} = [10,10];
% R_Cost_cell{1} = [4]; R_Cost_cell{2} = [4];
% 
% F_stageC_vec(1) = 1
% for i = 1:length(U_cell) 
%     [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU_cell{i},SIGMA_cell{i},U_cell{i},...
%         L_cell{i},R_Cost_cell{i},S_Cost_cell{i})
%     F_stageC_vec(i+1) = F_stageC % store conformance from previous stage
%     RwCost_vec(i) = Rwi*F_stageC_vec(i)
%     SrCost_vec(i) = Sri*F_stageC_vec(i)
%     ProdCost(i) = (PC(i) + Sri + Rwi)*F_stageC_vec(i)
% end
% ProdCost = sum(ProdCost)
% 
% %% 2 Stage, dual feature production
% PC = [0,0];
% U_cell{1} = [7 7]; U_cell{2} = [7 7];
% L_cell{1} = [3 3]; L_cell{2} = [3 3];
% MU_cell{1} = [5 5]; 
% MU_cell{2} = [5 5];
% sig11 = 1.55; sig22 = 1.55;
% SIGMA_cell{1} = [sig11^2 0;0 sig22^2];
% SIGMA_cell{2} = [sig11^2 0;0 sig22^2];
% S_Cost_cell{1} = [1,1,1,1];
% S_Cost_cell{2} = [1,1,1,1]; 
% R_Cost_cell{1} = [1,1,1,1];
% R_Cost_cell{2} = [1,1,1,1];
% 
% F_stageC_vec(1) = 1
% for j = 1:2
%     %for i = 1:length(U_cell)
%         [F_stageC,pIC,Rwi,Sri] = StageCostFun_old(MU_cell{j},SIGMA_cell{j},U_cell{j},L_cell{j},R_Cost_cell{j},S_Cost_cell{j})
%         F_stageC_vec(j+1) = F_stageC % store conformance from previous stage
%         RwCost_vec(j) = Rwi*F_stageC_vec(j)
%         SrCost_vec(j) = Sri*F_stageC_vec(j)
%         ProdCost(j) = (PC(j) + Sri + Rwi)*F_stageC_vec(j)
%     %end
% end
% ProdCost = sum(ProdCost)
