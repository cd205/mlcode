function [Profit,TC,S,PIs,f1s,f2s] = MinCMCFun_2var(mu1,mu2,mu1_rw,mu2_rw,U,L,SIGMA)
% used by MinimiseCMCFunction_2Var.m
% determine scrap and rework cost for a 2 variable example given the means.
%SC = [100 125 125 150];
SP = 400; PC = 50; 
RC = [0 25 25 50];
C = 1;
mu1_R = L(1)+(U(1)-mu1);
mu2_R = L(2)+(U(2)-mu2);
sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));
Fb1b2 = mvncdf([U(1),U(2)],[mu1_R mu2_R],SIGMA);
Fa1b2 = mvncdf([L(1),U(2)],[mu1_R mu2_R],SIGMA);
Fb1a2 = mvncdf([U(1),L(2)],[mu1_R mu2_R],SIGMA);
Fa1a2 = mvncdf([L(1),L(2)],[mu1_R mu2_R],SIGMA);
        
pI2 = Fa1b2 - Fa1a2;
pI3 = Fb1a2 - Fa1a2;
pI4 = Fa1a2;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pIS = 1 - Fb1b2;

p22 = 1 - normcdf(U(1),mu1_rw,sig11);
p2C = normcdf(U(1),mu1_rw,sig11) - normcdf(L(1),mu1_rw,sig11);
p2S = normcdf(L(1),mu1_rw,sig11);
p33 = 1 - normcdf(U(2),mu2_rw,sig22);
p3C = normcdf(U(2),mu2_rw,sig22) - normcdf(L(2),mu2_rw,sig22);
p3S = normcdf(L(2),mu2_rw,sig22);

p42 = pI2;
p43 = pI3;
p44 = pI4;
p4C = pIC;
p4S = pIS;
p55 = 1;
p56 = 0;

% reworks
m12 = pI2/((1-p22)*(1-p44));
m13 = pI3/((1-p33)*(1-p44));
m14 = pI4/(1-p44);

% Conforms from F-matrix
fIC = pIC + pI2*p2C/((1-p22)*(1-p44)) + pI3*p3C/((1-p33)*(1-p44)) + pI4*p4C/(1-p44);
f2C = (p2C/(1-p22));
f3C = (p3C/(1-p33));
f4C = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));
% Scraps from F-matrix
fIS = pIS + pI2*p2S/((1-p22)*(1-p44)) + pI3*p3S/((1-p33)*(1-p44)) + pI4*p4S/(1-p44);
f2S = (p2S/(1-p22));
f3S = (p3S/(1-p33));
f4S = (p42*p2S/((1-p22)*(1-p44)) + p43*p3S/((1-p33)*(1-p44)) + p4S/(1-p44));

f1s = [fIC, f2C*(pI4*(pI2/(1-pI4))+pI2),...
            f3C*(pI4*(pI3/(1-pI4))+pI3)...
            pI4*(pIC/(1-pI4))];
f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
            f3S*(pI4*(pI3/(1-pI4))+pI3),...
            pI4*(pIS/(1-pI4))];

RwInital = (m12-pI2) + (m13-pI3) + (m14-pI4);

%% Scrap cost vector, uses the averge time in rework
%SC = [100, 100+25*(1+m12), 100+25*(1+m13), 100+50*(1+m14)];
%SC = [100 125 125 150];
SC = [150 150 150 150];

Scrap = SC(1)*pIS + SC(2)*f2s(2) + SC(3)*f2s(3) + SC(4)*f2s(4);
Rwork = RC(2)*m12 + RC(3)*m13 + RC(4)*m14;

Profit = SP*fIC - PC - SC(1)*pIS - ...
    SC(2)*f2s(2) - SC(3)*f2s(3) - SC(4)*f2s(4) -...
    RC(2)*m12 - RC(3)*m13 - RC(4)*m14;
TC1 = 100*C*fIS + C*(m12 + m13 + m14);
TC = Scrap + Rwork;
%TC = abs(pIS - (pI2 + pI3 + pI4)); % Prob of rework and scrap

PIs = [pI2 pI3 pI4 pIC pIS];
S = struct('pI2',pI2,'pI3',pI3,'pI4',pI4,'pIC',pIC,'pIS',pIS,...
           'p22',p22,'p2C',p2C,'p2S',p2S,'p33',p33,'p3C',p3C,'p3S',p3S,...
           'fIC',fIC,'fIS',fIS,...
           'Scrap',Scrap,'Rwork',Rwork,...
           'Sc1',SC(1)*pIS,'Sc2',SC(2)*f2s(2),'Sc3',SC(3)*f2s(3),'Sc4',SC(4)*f2s(4),...
           'Rw1',RC(2)*m12,'Rw2',RC(3)*m13,'Rw3',RC(4)*m14);

