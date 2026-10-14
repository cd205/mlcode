MU = [5 5];
mu1_rw = 5; mu2_rw = 5;
L = [4 4];
U = [6 6];
SIGMA = [1 0; 0 1]
sig11 = sqrt(SIGMA(1));
sig22 = sqrt(SIGMA(2,2));
% Costs
PC = 50
SP = 100
SC = [50 50 50 50]
RC = [25 25 50] 

MU_R = L+(U-MU); % reverse the axes 

Fb1b2 = mvncdf([U(1),U(2)],MU_R,SIGMA);
Fa1b2 = mvncdf([L(1),U(2)],MU_R,SIGMA);
Fb1a2 = mvncdf([U(1),L(2)],MU_R,SIGMA);
Fa1a2 = mvncdf([L(1),L(2)],MU_R,SIGMA);

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
p5C = 1; 
p5S = 0; 

m12 = pI2/((1-p22)*(1-p44));
m13 = pI3/((1-p33)*(1-p44));
m14 = pI4/(1-p44);

fIC = pIC + pI2*p2C/((1-p22)*(1-p44)) + pI3*p3C/((1-p33)*(1-p44)) + pI4*p4C/(1-p44);
f2C = (p2C/(1-p22));%*p12;
f3C = (p3C/(1-p33));%*p13;
%Sum_45 = p25*p12/((1-p22)*(1-p14)) + p35*p13/((1-p33)*(1-p14));
%f45 = (p15/(1-p14)) + Sum_45;
f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;

%% Scrap parts
% NOTE: p12, p13 and p14 that multiply f26, f36 and f46 account for the
% number of parts flowing through into these rework stages,  this could be
% done in the cost model rather than here
% Sum_16 = p35*p13 + p46*p14 + p56*p15;
% Prod_16 = (1-p22)*(1-p33)*(1-p44);
% f16 = (p26*p12*(1-p33) + (Sum_16*Prod_16))/Prod_16;
fIS = pIS + pI2*p2S/((1-p22)*(1-p44)) + pI3*p3S/((1-p33)*(1-p44)) + pI4*p4S/(1-p44);
f2S = (p2S/(1-p22));%*p12;
f3S = (p3S/(1-p33));%*p13;
%Sum_46 = p26*p16/((1-p22)*(1-p14)) + p36*p13/((1-p33)*(1-p14));
%f46 = (p16/(1-p14)) + Sum_46;
f4S = (p42*p2S/((1-p22)*(1-p44)) + p43*p3S/((1-p33)*(1-p44)) + p4S/(1-p44));%*p14;


f1s = [fIC, f2C*(pI4*(pI2/(1-pI4))+pI2),...
            f3C*(pI4*(pI3/(1-pI4))+pI3)...
            pI4*(pIC/(1-pI4))]
f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
            f3S*(pI4*(pI3/(1-pI4))+pI3),...
            pI4*(pIS/(1-pI4))]

% %% dual variable truncated distribution
% % truncated dist with MU = [mu1 mu2]
% x1 = linspace(0,10,nums); x2 = linspace(0,10,nums);
% [X1,X2] = meshgrid(x1',x2');
% %MU = [mu1 mu2];
% [pdf IXV] = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
% figure;
% surf(x1,x2,pdf,'EdgeColor','none')
% fun = @(X1,X2) tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
% % q1 = integral2(fun,0,10,0,10)
% q_pdf = trapz(x2,trapz(x1,pdf))
% 
% (pIC + pIS)
% (f1s(2)+f1s(3)+f2s(2)+f2s(3))
% (f1s(4)+f2s(4))

Profit = SP*fIC - PC - SC(1)*pIS - ...
    SC(2)*f2s(2) - SC(3)*f2s(3) - SC(4)*f2s(4) -...
    RC(1)*m12 - RC(2)*m13 - RC(3)*m14

        
EP_Dodd2014(MU,SIGMA,L(1),L(2),U(1),U(2),SP,PC,SC,RC)
        