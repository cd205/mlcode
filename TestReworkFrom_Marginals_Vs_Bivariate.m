% Test a 2 variable cut-measure-cut distribtuion
% Draw a bivariate distribution to determine total conformance, scrap and
% rework.  Show that integrating out the bivariate distribution to given
% the univariate margins just gives the normal univarite margins (not some
% odd shape) .  Also calculates a markov chain to given total rework scrap
% and conformance based on (A Markovian approach to determining process
% means with dual quality characteristics, Khasawneh, M.T.
% Bowling, S.R, Cho, B.R., 2008)
clear all
close all
clc

sig11 = 1;
sig22 = 1;
SIGMA = [sig11^2 0.0 ;0.0 sig22^2]
A = [3 3];
B = [7 7];
CUT1 = [6 7];
CUT2 = CUT1;
CUT1R = A+(B-CUT1)  % convert cut1 from near to USL to near LSL
CUT2R = CUT1R;


N1 = @(x) normpdf(x,CUT1R(1),sig11);
N2 = @(y) normpdf(y,CUT1R(2),sig22);

MN = @(x,y) mvnpdf([x,y],CUT1R,SIGMA);

I_N1 = integral(N1,-inf,A(1))
I_N2 = integral(N2,-inf,A(2))
%I_N1b = normcdf(A(1),CUT1R(1),sig11)

Fa1a2 = mvncdf([A(1),A(2)],CUT1R,SIGMA);
Fa1b2 = mvncdf([A(1),B(2)],CUT1R,SIGMA);
Fb1a2 = mvncdf([B(1),A(2)],CUT1R,SIGMA);
Fb1b2 = mvncdf([B(1),B(2)],CUT1R,SIGMA);
s1 = struct('Fa1a2',Fa1a2,'Fa1b2',Fa1b2,'Fb1a2',Fb1a2,'Fb1b2',Fb1b2)
% Fa1b2 = integral2(@(x,y) fun_2VarReverse_CMC_Dist(x,y,SIGMA,CUT1,CUT2,A,B),-10,A(1),-10,B(2))
% Fb1a2 = integral2(@(x,y) fun_2VarReverse_CMC_Dist(x,y,SIGMA,CUT1,CUT2,A,B),-10,B(1),-10,A(2))
% Fb1b2 = integral2(@(x,y) fun_2VarReverse_CMC_Dist(x,y,SIGMA,CUT1,CUT2,A,B),-10,B(1),-10,B(2))

% Conformance
ConformPrt = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;  
% Scrap
ScrapPrt = 1 - Fb1b2;
% Rework 
RworkPrt = Fb1b2 - ConformPrt
%%
f = @(x,y)mvnpdf([x,y],CUT1R,SIGMA);
fx = @(x)integral(@(y)f(x,y),-20,20,'ArrayValued',true); % fx is a function in x, 
            % for every call 'x' the bivariate function is evaluated at 'x' and in y from -inf to inf
fy = @(y)integral(@(x)f(x,y),-20,20,'ArrayValued',true);
% NOTE it is much faster to integrate between finite numbers eg -20 to 20 
% then to go from -inf to inf 

x = 0:.1:10;
y = x;
[X Y] = meshgrid(x,y);
X = [X(:) Y(:)];

for i = 1:length(x)
    marginal_x(i) = fx(x(i));
    marginal_y(i) = fy(y(i));
end


figure(1)
plot(x,N1(x),'-'); grid on; hold on
plot(x,marginal_x,'c.'); hold on
plot(y,N2(y),'r-'); hold on
plot(y,marginal_y,'m+')


MVP = mvnpdf(X,CUT1R,SIGMA);
MVP = reshape(MVP,length(x),length(y));
figure(2)
surf(x,y,MVP,'Line','none')
%

%
%% Markov chain probability for bivariate distribution
p12 = mvncdf([B(1) A(2)],[inf,B(2)],CUT1,SIGMA)
p13 = mvncdf([A(1) B(2)],[B(1),inf],CUT1,SIGMA)
p14 = mvncdf([B(1) B(2)],[inf,inf],CUT1,SIGMA)
p15 = mvncdf([A(1) A(2)],[B(1),B(2)],CUT1,SIGMA)
p16 = mvncdf([-inf,-inf],[A(1),inf],CUT1,SIGMA) + ...
      mvncdf([-inf,-inf],[inf,A(2)],CUT1,SIGMA) - ...
      mvncdf([-inf,-inf],[A(1),A(2)],CUT1,SIGMA)

p22 = 1 - normcdf(B(1),CUT1(1),sig11);
p25 = normcdf(B(1),CUT1(1),sig11) - normcdf(A(1),CUT1(1),sig11);
p26 = normcdf(A(1),CUT1(1),sig11);
p33 = 1 - normcdf(B(2),CUT1(2),sig22);
p35 = normcdf(B(2),CUT1(2),sig22) - normcdf(A(2),CUT1(2),sig22);
p36 = normcdf(A(2),CUT1(2),sig22);
p44 = p14;
p45 = p15;
p55 = 1;

m12 = p12/((1-p22)*(1-p44))
m13 = p13/((1-p33)*(1-p44))
m14 = p14/(1-p44)

Sum_15 = [p35*p13,p45*p14,p55*p15];
Prod_15 = (1-p22)*(1-p33)*(1-p44);
f15 = p25*p12*(1-p33)+sum(Sum_15.*Prod_15)/(Prod_15);
f25 =p25/(1-p22);
f35 = p35/(1-p22);
Sum_45 = [p25*p12/((1-p22)*(1-p14)),p35*p13/((1-p33)*(1-p14))];
f45 = p15/(1-p14)+sum(Sum_45);

TotalAccpt = f15
TotalScrap = (1-f15) + (1-f25) + (1-f35) + (1-f45)
TotalRWork = m12 + m13 + m14

    