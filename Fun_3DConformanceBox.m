function s1 = Fun_3DConformanceBox(mu1,mu2,mu3)

% Study 3D conformance problem

% Study how moving the location of the distribution effects the nearness of
% the exact solution to the upper or lower bound

% Exact Solution:
%   Exact:  F(b1,b2) - F(a1,b2,) - F(b1,a2) +F(a1,a2)
% Amir:
%   LB:     F(b1,b2) - {F(a1,b2,) + F(b1,a2)}
%   UB:     F(b1,b2) - MAX {F(a1,b2,), F(b1,a2)}

num = 10;
A = [3 3 3];
B = [7 7 7];
L = -10;

alpha1 = 0;
alpha2 = 0;
alpha3 = 0;
sigma1 = 1.0;
sigma2 = 1.0;
sigma3 = 1.0;
ALPHA = [alpha1 alpha2 alpha3];
SIGMA = [sigma1 0 0; 0 sigma2 0; 0 0 sigma3];
MU = [mu1 mu2 mu3]


% Define trivariate skew normal function
fun3d = @(X,Y,Z) dmsn_triplequad(X,Y,Z,MU,SIGMA,ALPHA);
% Integrate trivariate skew normal distribtuin between limits
Fa1a2a3 = triplequad(fun3d,L,A(1),L,A(2),L,A(3));
Fa1a2b3 = triplequad(fun3d,L,A(1),L,A(2),L,B(3));
Fa1b2a3 = triplequad(fun3d,L,A(1),L,B(2),L,A(3));
Fa1b2b3 = triplequad(fun3d,L,A(1),L,B(2),L,B(3));
Fb1a2a3 = triplequad(fun3d,L,B(1),L,A(2),L,A(3));
Fb1a2b3 = triplequad(fun3d,L,B(1),L,A(2),L,B(3));
Fb1b2a3 = triplequad(fun3d,L,B(1),L,B(2),L,A(3));
Fb1b2b3 = triplequad(fun3d,L,B(1),L,B(2),L,B(3));

% % Define trivariate skew normal function
% Fa1a2a3 = mvncdf([L L L],[A(1),A(2),A(3)],MU,SIGMA)
% Fa1a2b3 = triplequad(fun3d,L,A(1),L,A(2),L,B(3));
% Fa1b2a3 = triplequad(fun3d,L,A(1),L,B(2),L,A(3));
% Fa1b2b3 = triplequad(fun3d,L,A(1),L,B(2),L,B(3));
% Fb1a2a3 = triplequad(fun3d,L,B(1),L,A(2),L,A(3));
% Fb1a2b3 = triplequad(fun3d,L,B(1),L,A(2),L,B(3));
% Fb1b2a3 = triplequad(fun3d,L,B(1),L,B(2),L,A(3));
% Fb1b2b3 = triplequad(fun3d,L,B(1),L,B(2),L,B(3));


Conform = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
    + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3;

check = mvncdf([3 3 3],[7 7 7],MU,SIGMA);

LB = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3);
if LB < 0
    LB = 0;
end
UB = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3]);

s1 = struct('Fa1a2a3',Fa1a2a3,'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,...
    'Fa1b2b3',Fa1b2b3,'Fb1a2a3',Fb1a2a3,'Fb1a2b3',Fb1a2b3,...
    'Fb1b2a3',Fb1b2a3,'Fb1b2b3',Fb1b2b3,'Conform',Conform);
    


