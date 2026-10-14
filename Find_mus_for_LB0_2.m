% Find MUs when LB is on the zero bound

clear all
clc
num = 10;
A = [3 3 3];
B = [7 7 7];
L = -10;
mu1 = 3.1%3.545;
mu2 = 4.45%3.545;
mu3 = 1; %3.10825;
alpha1 = 0;
alpha2 = 0;
alpha3 = 0;
sigma11 = 1;
sigma22 = 1;
sigma33= 1.0;
sigma12 = 0.0;
sigma13 = 0;
sigma21 = 0.0;
sigma23 = 0;
sigma31 = 0; 
sigma32 = 0;
ALPHA = [alpha1 alpha2 alpha3];
SIGMA = [sigma11^2 sigma12^2 sigma13^2;...
        sigma21^2 sigma22^2 sigma23^2;...
        sigma31^2 sigma32^2 sigma33^2];
MU = [mu1 mu2 mu3]



Fa1a2 = mvncdf([L L],[A(1),A(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
Fa1b2P = mvncdf([L A(2)],[A(1),B(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
Fb1a2P = mvncdf([A(1) L],[B(1),A(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
Fb1b2 = mvncdf([L L],[B(1),B(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
E = mvncdf([A(1) A(2)],[B(1),B(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
T = Fa1a2 + Fa1b2P + Fb1a2P