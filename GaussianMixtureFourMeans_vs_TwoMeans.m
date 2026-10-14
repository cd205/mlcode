% call the MinCMCFun_2var function
clear all
close all
clc
% mu1 =   5.295 ; mu2 = 5.295;
% mu1_rw = 5.488; mu2_rw = 5.488;
% 
% sig11 = 1;
% sig22 = 1;
% rho = 0.5;
% SIGMA = [sig11^2, rho*sig11*sig22; rho*sig11*sig22, sig22^2];
% U = [6 6];
% L = [4 4];
% [Profit,TC,S,PIs,f1s,f2s] = MinCMCFun_2var(mu1,mu2,mu1_rw,mu2_rw,U,L,SIGMA)
% PIs
% CheckVals = f1s(2)+f1s(3)+f1s(4)+f2s(2)+f2s(3)+f2s(4)+PIs(4)+PIs(5)
% %% single variable truncated distribution 
% x = linspace(0,10,1000);
% piCS = normcdf(U(1),mu1,sig11);       % 1-var conformance and scrap after 1st iter
% pi2 = 1-normcdf(U(1),mu1,sig11);      % 1-var feed into rework state
% 
% % pdf from x_1 after first cut (i.e. TruncatedDist*Fa1b2
% pdfa = Fun_TruncatedNormalDist_pdf(x,mu1,sig11,0,U(1),U(1),1)*piCS;
% pdfb = Fun_TruncatedNormalDist_pdf(x,mu1_rw,sig11,0,U(1),U(1),1)*(PIs(1)+PIs(3));
% figure(1);
% plot(x,pdfa,'r.-'); grid on; hold on 
% plot(x,pdfb,'g.-'); hold on 
% plot(x,pdfa+pdfb,'m.-');
% xlabel('x_1')
% ylabel('Probability Density')
% legend('PDF inital state','PDF rework state','Sum of PDFs')
% int2one = trapz(x,pdfa+pdfb)

darkred = [127.5 0 0]./255;
red = [237 28 36]./255;
orange = [241 140 34]./255;
yellow = [255 222 23]./255; 
lightgreen = [173 209 54]./255;
darkgreen = [8 135 67]./255;
lightblue = [71 195 211]./255;
darkblue = [33 64 154]./255;
purple = [150 100 155]./255;
pink = [238 132 181]./255;

U = [7 7];
L = [3 3];
MU = [5.5 5.5];
mu1_rw = 7; mu2_rw = 7;
rho = 0
SIGMA = [1 rho*1*1; rho*1*1 1];


MU_R = L+(U-MU); % reverse the axes 
sig11 = sqrt(SIGMA(1));
sig22 = sqrt(SIGMA(2,2));

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

%% dual variable truncated distribution
% truncated dist with MU = [mu1 mu2]
x1 = linspace(2.5,7.5,40); x2 = linspace(2.5,7.5,40);
[X1,X2] = meshgrid(x1',x2');
%MU = [mu1 mu2];
pdf = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
figure;
surf(x1,x2,pdf,'EdgeColor','none')
fun = @(X1,X2) tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
% q1 = integral2(fun,0,10,0,10)
q_pdf = trapz(x2,trapz(x1,pdf))

(pIC + pIS)
(f1s(2)+f1s(3)+f2s(2)+f2s(3))
(f1s(4)+f2s(4))

%% truncated dist where MU1 = [mu1 mu2] and MU2 = [mu1_rw mu2_rw]
MU1 = [MU]; MU2 = [mu1_rw mu2_rw];
% pdf1 is Turncated distribution from inital iteration, this includes the 
% pIC and pIS parts, i.e. comformance and scrap from initial processing
pdf1 = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)*(pIC+pIS);
% pdf2 is Turncated distribution from the rework from the two single
% feature rework states (state 2 and 3), assume no dependence 
pdf2 = tmvnorm_2var(X1,X2,MU2,sig11,sig22,0,L,U)*(f1s(2)+f1s(3)+f2s(2)+f2s(3));
% pdf3 is Turncated distribution from the rework from the fourth state, it
% is the same as the inital process but with fewer components
pdf3 = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)*(f1s(4)+f2s(4));
% pdfTot is the combination of the pdfs
pdfTot = pdf1+pdf2+pdf3;
figure(2);
surf(x1,x2,pdfTot,'EdgeColor','none')
q_pdfTot = trapz(x2,trapz(x1,pdfTot))
%[TC2,S2] = MinCMCFun_Iterative_2var(mu1,mu2,mu1_rw,mu2_rw,U,L,SIGMA)

figure;
m1 = mesh(x1,x2,pdf,'EdgeColor','red','LineWidth',1); hold on
%set(m1,'FaceAlpha',0.8)
m2 = mesh(x1,x2,pdfTot,'EdgeColor',[33 64 154]./255,'LineWidth',1.1); hold on
set(m1,'FaceAlpha',0.4)
view(60, 30);  
set(gca,'FontSize',15)
xlabel('\mu_{1}'); ylabel('\mu_{2}'); zlabel('Probability Density');
legend('Case I surface','Case II surface');
axis([2 8 2 8 0 0.2])


%% GET THE MARGINAL DISTRIBUTIONS 
%clear x1; clear x2
funTrun = @(x1,x2) tmvnorm_2var(x1,x2,MU,sig11,sig22,rho,L,U)*(pIC+pIS)+...
 tmvnorm_2var(x1,x2,MU2,sig11,sig22,0,L,U)*(f1s(2)+f1s(3)+f2s(2)+f2s(3))+...
 tmvnorm_2var(x1,x2,MU,sig11,sig22,rho,L,U)*(f1s(4)+f2s(4));

% trunmvnpdf = funTrun(X1,X2)
% surf(x1,x2,trunmvnpdf)
%f = @(x,y)fun_2VarReverse_CMC_Dist(x,y,SIGMA,CUT1,CUT2,A,B);
fx1 = @(x1)integral(@(x2)funTrun(x1,x2),0,10,'ArrayValued',true); % fx is a function in x, 
            % for every call 'x' the bivariate function is evaluated at 'x' and in y from -inf to inf
fx2 = @(x2)integral(@(x1)fun(x1,x2),0,10,'ArrayValued',true);
% NOTE it is much faster to integrate between finite numbers eg -20 to 20 
% then to go from -inf to inf 

x1 = linspace(1,9,80);
x2 = x1;
 
for i = 1:length(x1)
    i
    marginal_x1(i) = fx1(x1(i));
    marginal_x2(i) = fx2(x2(i));
end
figure;
plot(x1,marginal_x1,'r.-','LineWidth',1.5); hold on
plot(x2,marginal_x2,'.-','Color',[33 64 154]./255,'LineWidth',1.5); grid on
line([3 3],[0 0.45],'Color','red','LineWidth',2.5)
line([7 7],[0 0.45],'Color','green','LineWidth',2.5)
set(gca,'FontSize',15)
xlabel('Mean (\mu)')
ylabel('Probability Density')
Leg = legend('Case I','Case II'); 
set(Leg,'FontSize',15)
axis([1 9 0 0.5])


