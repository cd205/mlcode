% Study 4D conformance problem

% Study how moving the location of the distribution effects the nearness of
% the exact solution to the upper or lower bound
clear all
clc
close all
% Exact Solution:
%   Exact:  F(b1,b2) - F(a1,b2,) - F(b1,a2) +F(a1,a2)
% Amir:
%   LB:     F(b1,b2) - {F(a1,b2,) + F(b1,a2)}
%   UB:     F(b1,b2) - MAX {F(a1,b2,), F(b1,a2)}

num = 10;
A = [3 3 3 3];
B = [7 7 7 7];
L = -10;
mu1 = 3.7;
mu2 = 3.8;
mu3 = 4.2;
mu4 = 3.3;% 3.0709 %2239;
sigma11 = 0.7;
sigma22 = 0.7;
sigma33 = 0.7;
sigma44 = 0.7;
SIGMA = [sigma11^2 0 0 0; 0 sigma22^2 0 0; 0 0 sigma33^2 0; 0 0 0 sigma44^2];
MU = [mu1 mu2 mu3 mu4]

Fa1a2a3a4 = mvncdf([L,L,L,L],[A(1),A(2),A(3),A(4)],MU,SIGMA);
Fb1b2b3b4 = mvncdf([L,L,L,L],[B(1),B(2),B(3),B(4)],MU,SIGMA);

Fb1a2a3a4 = mvncdf([L,L,L,L],[B(1),A(2),A(3),A(4)],MU,SIGMA);
Fa1b2a3a4 = mvncdf([L,L,L,L],[A(1),B(2),A(3),A(4)],MU,SIGMA);
Fa1a2b3a4 = mvncdf([L,L,L,L],[A(1),A(2),B(3),A(4)],MU,SIGMA);
Fa1a2a3b4 = mvncdf([L,L,L,L],[A(1),A(2),A(3),B(4)],MU,SIGMA);

Fb1b2a3a4 = mvncdf([L,L,L,L],[B(1),B(2),A(3),A(4)],MU,SIGMA);
Fb1a2b3a4 = mvncdf([L,L,L,L],[B(1),A(2),B(3),A(4)],MU,SIGMA);
Fb1a2a3b4 = mvncdf([L,L,L,L],[B(1),A(2),A(3),B(4)],MU,SIGMA);
Fa1b2b3a4 = mvncdf([L,L,L,L],[A(1),B(2),B(3),A(4)],MU,SIGMA);
Fa1b2a3b4 = mvncdf([L,L,L,L],[A(1),B(2),A(3),B(4)],MU,SIGMA);
Fa1a2b3b4 = mvncdf([L,L,L,L],[A(1),A(2),B(3),B(4)],MU,SIGMA);

Fb1b2b3a4 = mvncdf([L,L,L,L],[B(1),B(2),B(3),A(4)],MU,SIGMA);
Fa1b2b3b4 = mvncdf([L,L,L,L],[A(1),B(2),B(3),B(4)],MU,SIGMA);
Fb1a2b3b4 = mvncdf([L,L,L,L],[B(1),A(2),B(3),B(4)],MU,SIGMA);
Fb1b2a3b4 = mvncdf([L,L,L,L],[B(1),B(2),A(3),B(4)],MU,SIGMA);

%special terms
Fa1a2a3b4P = Fa1a2a3b4 - Fa1a2a3a4;
Fa1b2a3b4P = Fa1b2a3b4 - Fa1b2a3a4;
Fb1a2a3b4P = Fb1a2a3b4 - Fb1a2a3a4;
Fa1a2b3b4P = Fa1a2b3b4 - Fa1a2b3a4;

check = mvncdf([A(1),A(2),A(3),A(4)],[B(1),B(2),B(3),B(4)],MU,SIGMA) 


Conform = + Fa1a2a3a4 + Fb1b2b3b4...
    - Fb1a2a3a4 - Fa1b2a3a4 - Fa1a2b3a4 - Fa1a2a3b4...
    + Fb1b2a3a4 + Fb1a2b3a4 + Fb1a2a3b4 + Fa1b2b3a4 + Fa1b2a3b4 + Fa1a2b3b4...
    - Fb1b2b3a4 - Fa1b2b3b4 - Fb1a2b3b4 - Fb1b2a3b4
if abs(check-Conform)>0.01
    disp('ERROR, conform is not equal to check')
end

LB = Fb1b2b3b4 - (Fa1b2b3b4 + Fb1a2b3b4 + Fb1b2a3b4 + Fb1b2b3a4)
if LB < 0
    LB = 0
end
UB = Fb1b2b3b4 - max([Fa1b2b3b4,Fb1a2b3b4,Fb1b2a3b4,Fb1b2b3a4])
b1s = ['one b'];
b2s = ['two bs'];
b3s = ['three bs'];
s1 = struct('Fa1a2a3a4',Fa1a2a3a4,'Fb1b2b3b4',Fb1b2b3b4,'b1s',b1s,...
    'Fb1a2a3a4',Fb1a2a3a4,'Fa1b2a3a4',Fa1b2a3a4,'Fa1a2b3a4',Fa1a2b3a4,'Fa1a2a3b4',Fa1a2a3b4,'b2s',b2s,...
    'Fb1b2a3a4',Fb1b2a3a4,'Fb1a2b3a4',Fb1a2b3a4,'Fb1a2a3b4',Fb1a2a3b4,...
    'Fa1b2b3a4',Fa1b2b3a4,'Fa1b2a3b4',Fa1b2a3b4,'Fa1a2b3b4',Fa1a2b3b4,'b3s',b3s,...
    'Fb1b2b3a4',Fb1b2b3a4,'Fa1b2b3b4',Fa1b2b3b4,'Fb1a2b3b4',Fb1a2b3b4,'Fb1b2a3b4',Fb1b2a3b4)
    
s1a = struct('Fa1a2a3a4',Fa1a2a3a4,'Fb1b2b3b4',Fb1b2b3b4,...
    'Fb1a2a3a4',Fb1a2a3a4,'Fa1b2a3a4',Fa1b2a3a4,'Fa1a2b3a4',Fa1a2b3a4,'Fa1a2a3b4',Fa1a2a3b4,...
    'Fb1b2a3a4',Fb1b2a3a4,'Fb1a2b3a4',Fb1a2b3a4,'Fb1a2a3b4',Fb1a2a3b4,...
    'Fa1b2b3a4',Fa1b2b3a4,'Fa1b2a3b4',Fa1b2a3b4,'Fa1a2b3b4',Fa1a2b3b4,...
    'Fb1b2b3a4',Fb1b2b3a4,'Fa1b2b3b4',Fa1b2b3b4,'Fb1a2b3b4',Fb1a2b3b4,'Fb1b2a3b4',Fb1b2a3b4)


s2 = struct('Fa1a2a3b4P',Fa1a2a3b4P,'Fa1b2a3b4P',Fa1b2a3b4P,...
    'Fb1a2a3b4P',Fb1a2a3b4P,'Fa1a2b3b4P',Fa1a2b3b4P)


% Calculation of the sticking out terms from preevaluated terms
Fa1a2a3b4PCalc = Fa1a2a3a4*(1/Fb1b2b3a4-1)
Fa1b2a3b4PCalc = Fa1a2a3b4PCalc*Fb1a2b3b4^-1%Fa1a2a3a4*(1/Fb1b2a3b4-1)%*Fa1b2b3b4*Fb1b2a3b4
Fb1a2a3b4PCalc = Fa1a2a3b4PCalc*Fa1b2b3b4^-1
Fa1a2b3b4PCalc = Fa1a2a3b4PCalc*Fb1b2a3b4^-1

Abox = Fa1b2b3b4 + Fb1a2b3b4 + Fb1b2a3b4
HalfAbox = Abox*Fb1b2b3a4
sdf = Fb1b2a3a4 + Fb1a2b3a4 + Fa1b2b3a4
B = (Fa1a2a3a4...  % this is the unevaluated terms
    - Fb1a2a3a4 - Fa1b2a3a4 - Fa1a2b3a4 - Fa1a2a3b4...
    + Fb1b2a3a4 + Fb1a2b3a4 + Fb1a2a3b4 + Fa1b2b3a4 + Fa1b2a3b4 + Fa1a2b3b4)


Bcalc = Abox*Fb1b2b3a4 +...
           - Fa1a2a3b4PCalc + Fa1b2a3b4PCalc + Fb1a2a3b4PCalc + Fa1a2b3b4PCalc


% bit of A box beneath LSL + relative size of Fa1a2b3 - the Fa1a2a3 box
musetting = Abox*normcdf(3,mu4,sigma44^2)...
     +(1/normcdf(A(4),mu4,sigma44^2)*Fa1a2a3a4-Fa1a2a3a4)... % should be = to Fa1a2a3b4P
     +(1/normcdf(A(4),mu4,sigma44^2)*Fa1a2a3a4-Fa1a2a3a4)
LBerror = Conform- LB
UBError = UB - Conform
figure(3)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(Conform,0,'b.','MarkerSize',30); grid on
% pdf1 = dsn([0:0.1:10],mu1,sigma1,alpha1);
% pdf2 = dsn([0:0.1:10],mu2,sigma2,alpha2);
% subplot(1,2,1)
% plot([0:0.1:10],pdf1,'.-')
% line([3 3], [0 0.4])
% line([7 7], [0 0.4])
% grid on
% subplot(1,2,2)
% plot([0:0.1:10],pdf2,'.-')
% line([3 3], [0 0.4])
% line([7 7], [0 0.4])
% grid on
%
% figure(3)
% plot(LB,0,'g.','MarkerSize',30); hold on
% plot(UB,0,'r.','MarkerSize',30); hold on
% plot(Conform,0,'b.','MarkerSize',30); grid on
%
