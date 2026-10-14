function [Profit] = ConRodProfit(MUs,SP,sig11,sig22,rho,L,U,PC,SC,RC,ReworkBound)
MU = MUs(1:2);
MU_rw = MUs(3:4);
if ReworkBound == 'L'
   % 'Rework at lower limits'
    MU_rw = L+(U-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
elseif ReworkBound == 'U'
   % 'Rework at upper limits'
    MU = L+(U-MU);  % reverse the dual feature rework to us nelsen method 
end
    

%% Marginals distributions 
% x2_pdf = normpdf(xp2,MU(1),sig11); % large diameter (x_2) pdf
fc2 = @(lim) normcdf(lim,MU(1),sig11); % large diameter (x_2) cdf
fc2rw = @(lim) normcdf(lim,MU_rw(1),sig11);

pd3 = makedist('tLocationScale','mu',MU(2),'sigma',sig22,'nu',2.2522);
pd3_rw = makedist('tLocationScale','mu',MU_rw(2),'sigma',sig22,'nu',2.2522);
%pd3 = makedist('GeneralizedExtremeValue','k',0.2,'mu',MU(2),'sigma',sig22);
%pd3_rw = makedist('GeneralizedExtremeValue','k',0.2,'mu',MU_rw(2),'sigma',sig22);     
% x3_pdf = normpdf(xp3,MU(2),sig22);%pdf(pd3,xp3);             
fc3 = @(lim) cdf(pd3,lim);              % small diameter (x_3) pdf
fc3rw = @(lim) cdf(pd3_rw,lim);

Fb1b2 = copulacdf('Gaussian',[fc2(U(1)),fc3(U(2))],rho);
Fa1b2 = copulacdf('Gaussian',[fc2(L(1)),fc3(U(2))],rho);
Fb1a2 = copulacdf('Gaussian',[fc2(U(1)),fc3(L(2))],rho);
Fa1a2 = copulacdf('Gaussian',[fc2(L(1)),fc3(L(2))],rho);

pI2 = Fa1b2 - Fa1a2;
pI3 = Fb1a2 - Fa1a2;
pI4 = Fa1a2;
pIC = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
pIS = 1 - Fb1b2;
 


p22 = 1- fc2rw(U(1));
p2C = fc2rw(U(1)) - fc2rw(L(1));
p2S = fc2rw(L(1));
p33 = 1- fc3rw(U(2));
p3C = fc3rw(U(2)) - fc3rw(L(2));
p3S = fc3rw(L(2));


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
% %Sum_45 = p25*p12/((1-p22)*(1-p14)) + p35*p13/((1-p33)*(1-p14));
% %f45 = (p15/(1-p14)) + Sum_45;
f45 = (p42*p2C/((1-p22)*(1-p44)) + p43*p3C/((1-p33)*(1-p44)) + p4C/(1-p44));%*p14;
% 
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
            pI4*(pIC/(1-pI4))];
f2s = [fIS, f2S*(pI4*(pI2/(1-pI4))+pI2),...
            f3S*(pI4*(pI3/(1-pI4))+pI3),...
            pI4*(pIS/(1-pI4))];


Profit = SP*fIC - PC - SC(1)*pIS - ...
         SC(2)*f2s(2) - SC(3)*f2s(3) - SC(4)*f2s(4) -...
         RC(2)*m12 - RC(3)*m13 - RC(4)*m14  ;     