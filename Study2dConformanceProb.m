% Study the 2D conformance problem
clear all
clc
close all
% Exact Solution:
%   Exact:  F(b1,b2) - F(a1,b2,) - F(b1,a2) +F(a1,a2)
% Amir:
%   LB:     F(b1,b2) - {F(a1,b2,) + F(b1,a2)}
%   UB:     F(b1,b2) - MAX {F(a1,b2,), F(b1,a2)}


A = [3 3]
B = [8 8]
L = -10
mu1 = 4
mu2 = 4;
alpha1 = 0;
alpha2 = 0;
sigma11 = 0.7;
sigma22 = 0.7;
sigma12 = 0.0;
sigma21 = 0.0;
MU = [mu1 mu2];
ALPHA = [alpha1 alpha2];
SIGMA = [sigma11^2 sigma12^2; sigma21^2 sigma22^2]

r = mvnrnd(MU,SIGMA,1000);
figure;
plot(r(:,1),r(:,2),'+')
grid on
axis([0 10 0 10])
line([A(1) A(1)],[0 10],'color',[1 0 0])
line([0 10],[A(2) A(2)],'color',[1 0 0])
line([B(1) B(1)],[0 10],'color',[0 1 0])
line([0 10],[B(2) B(2)],'color',[0 1 0])
xlabel('x1')
ylabel('x2')

% Define bivariate skew normal function
fun2d = @(X,Y) dmsn_quad2d(X,Y,MU,SIGMA,ALPHA)

% Integrate bivariate skew normal distribtuin between limits
Fb1b2 = quad2d(fun2d,L,B(1),L,B(2));
Fa1b2 = quad2d(fun2d,L,A(1),L,B(2));
Fb1a2 = quad2d(fun2d,L,B(1),L,A(2));
Fa1a2 = quad2d(fun2d,L,A(1),L,A(2));
Conform = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2

check = mvncdf([A(1) A(2)],[B(1) B(2)],MU,SIGMA)

LB = Fb1b2 - (Fa1b2 + Fb1a2)
if LB < 0
    LB = 0
end
UB = Fb1b2 - max([Fa1b2,Fb1a2]);

s1 = struct('Fb1b2',Fb1b2,'Fa1b2',Fa1b2,'Fb1a2',Fb1a2,'Fa1a2',Fa1a2,...
    'Conform',Conform)

figure;
pdf1 = dsn([0:0.1:10],mu1,sigma11,alpha1);
pdf2 = dsn([0:0.1:10],mu2,sigma22,alpha2);
subplot(1,2,1)
plot([0:0.1:10],pdf1,'.-')
line([3 3], [0 0.4])
line([7 7], [0 0.4])
grid on
subplot(1,2,2)
plot([0:0.1:10],pdf2,'.-')
line([3 3], [0 0.4])
line([7 7], [0 0.4])
grid on

figure;
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(Conform,0,'b.','MarkerSize',30); grid on


mean1 = mu1+sigma11*(alpha1/sqrt(1+alpha1^2))*(sqrt(2/pi))