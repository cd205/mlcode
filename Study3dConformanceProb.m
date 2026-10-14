% Study 3D conformance problem

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
A = [3 3 3];
B = [8 8 8];
L = -10;
mu1 = 4;
mu2 = 5;
mu3 = 3%.412; %3.10825;
alpha1 = 0;
alpha2 = 0;
alpha3 = 0;
sigma11 = 0.7;
sigma22 = 0.7;
sigma33 = 0.7;
sigma12 = 0.0;
sigma13 = 0.65;
sigma21 = 0.0;
sigma23 = 0.0;
sigma31 = 0.65; 
sigma32 = 0.0;
ALPHA = [alpha1 alpha2 alpha3];
SIGMA = [sigma11^2 sigma12^2 sigma13^2;...
        sigma21^2 sigma22^2 sigma23^2;...
        sigma31^2 sigma32^2 sigma33^2];
MU = [mu1 mu2 mu3]


r = mvnrnd(MU,SIGMA,1000);
figure;
plot3(r(:,1),r(:,2),r(:,3),'+')
axis([0 8 0 8 0 8])
line([A(1) A(1)],[2 8],'color',[1 0 0])
line([B(1) B(1)],[2 8],'color',[1 0 0])
line([2 8],[B(1) B(1)],'color',[1 0 0])
line([2 8],[A(1) A(1)],'color',[1 0 0])
grid on;
xlabel('x1')
ylabel('x2')
zlabel('x3')

% Define trivariate skew normal function
% fun3d = @(X,Y,Z) dmsn_triplequad(X,Y,Z,MU,SIGMA,ALPHA);
% % Integrate trivariate skew normal distribtuin between limits
% Fa1a2a3 = triplequad(fun3d,L,A(1),L,A(2),L,A(3));
% Fa1a2b3 = triplequad(fun3d,L,A(1),L,A(2),L,B(3));
% Fa1b2a3 = triplequad(fun3d,L,A(1),L,B(2),L,A(3));
% Fa1b2b3 = triplequad(fun3d,L,A(1),L,B(2),L,B(3));
% Fb1a2a3 = triplequad(fun3d,L,B(1),L,A(2),L,A(3));
% Fb1a2b3 = triplequad(fun3d,L,B(1),L,A(2),L,B(3));
% Fb1b2a3 = triplequad(fun3d,L,B(1),L,B(2),L,A(3));
% Fb1b2b3 = triplequad(fun3d,L,B(1),L,B(2),L,B(3));

Fa1a2a3 = mvncdf([L L L],A,MU,SIGMA); 
Fa1a2b3 = mvncdf([L L L],[A(1),A(2),B(3)],MU,SIGMA);
Fa1b2a3 = mvncdf([L L L],[A(1),B(2),A(3)],MU,SIGMA);
Fa1b2b3 = mvncdf([L L L],[A(1),B(2),B(3)],MU,SIGMA);
Fb1a2a3 = mvncdf([L L L],[B(1),A(2),A(3)],MU,SIGMA);
Fb1a2b3 = mvncdf([L L L],[B(1),A(2),B(3)],MU,SIGMA);
Fb1b2a3 = mvncdf([L L L],[B(1),B(2),A(3)],MU,SIGMA);
Fb1b2b3 = mvncdf([L L L],B,MU,SIGMA);


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
    + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3

check = mvncdf([3 3 3],[7 7 7],MU,SIGMA)
U = Fa1a2a3 + Fa1a2b3 + Fa1b2a3 + Fb1a2a3;
if abs(check-Conform)>0.01
    disp('ERROR, conform is not equal to check')
end
LB = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3)
if LB < 0
    LB = 0
end
UB = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3])

s1 = struct('Fa1a2a3',Fa1a2a3,'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,...
    'Fa1b2b3',Fa1b2b3,'Fb1a2a3',Fb1a2a3,'Fb1a2b3',Fb1a2b3,...
    'Fb1b2a3',Fb1b2a3,'Fb1b2b3',Fb1b2b3,'Fa1a2b3P',Fa1a2b3-Fa1a2a3,'Conform',Conform,'U',U)
Abox = Fa1b2b3 + Fb1a2b3
TwoB = 2*(Fa1a2b3 + Fa1b2a3 + Fb1a2a3 - Fa1a2a3) 
a_box = Fa1a2b3 - Fa1a2a3
b_box = Fb1a2a3 + Fa1b2a3
Bottom_A_Layer = Fb1a2a3 + Fa1b2a3
Top_A_Layer = Fa1b2b3-Fa1b2a3 + Fb1a2b3-Fb1a2a3
% Fa1b2a3P = Fa1b2a3 - Fa1a2a3
% Fb1a2a3P = Fb1a2a3 - Fa1a2a3
% musetting is bit of A box beneath LSL + relative size of Fa1a2b3 - the Fa1a2a3 box
% musetting = Abox*normcdf(3,mu3,SIGMA(1,1))...
     %+(1/normcdf(3,mu3,SIGMA(1,1))*Fa1a2a3-Fa1a2a3) % should be equal to TwoB/2 the lower bound error

figure(3)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(Conform,0,'b.','MarkerSize',30); grid on

LBerror = Conform - LB
UBerror = UB - Conform

if Fa1b2b3 + Fb1a2b3 - (Fa1b2b3*Fb1a2b3) > 0.5
    disp('BETWEEN LB AND MIDDLE')
elseif Fa1b2b3 + Fb1a2b3 - (Fa1b2b3*Fb1a2b3) < 0.5
    disp('BETWEEN MIDDLE AND UB')
end

%% Double accuracy method for LB>0
%Eqn B below is:  B = lower part of Abox + bit sticking out the top
%B = Abox*(normcdf(A(1),mu3,sigma33)) + (((Fa1a2a3/normcdf(A(1),mu3,sigma33)))-Fa1a2a3);

DetlaFa1a2a3 = Fa1a2a3 /...
    (normcdf(A(1),mu1,sigma11)*normcdf(A(2),mu2,sigma22)*normcdf(A(3),mu3,sigma33));
%Detla_D1D2 = 
if DetlaFa1a2a3 > 1
    Abox_Lower = (1 + (DetlaFa1a2a3-1)/2)*Fa1b2b3
    B = Abox_Lower + (((Fa1a2a3/normcdf(A(1),mu3,sigma33))*DetlaFa1a2a3^-1)-Fa1a2a3);
    disp('FIRST OPTION')
elseif DetlaFa1a2a3 <= 1
    B = Abox*(normcdf(A(1),mu3,sigma33)) + (((Fa1a2a3/normcdf(A(1),mu3,sigma33)))-Fa1a2a3);
end
% Determin which error is smaller thaus which bound is closest
if LB>0
    if 2*B > Abox
        disp('Between UB and Middle')
        figure(3)
        plot((UB-LB)/2+LB,0,'c*','MarkerSize',20); hold on
        plot(UB,0,'m*','MarkerSize',20);
    elseif 2*B < Abox
        disp('Between LB and Middle')
        figure(3)
        plot(LB,0,'c*','MarkerSize',20); hold on
        plot((UB-LB)/2+LB,0,'m*','MarkerSize',20);
    end
end
% 
% Fa1a2 = mvncdf([L L],[A(1),A(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
% Fa1b2P = mvncdf([L A(2)],[A(1),B(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
% Fb1a2P = mvncdf([A(1) L],[B(1),A(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
% Fb1b2 = mvncdf([L L],[B(1),B(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
% E = mvncdf([A(1) A(2)],[B(1),B(2)],[MU(1) MU(2)],SIGMA(1:2,1:2))
% T = Fa1a2 + Fa1b2P + Fb1a2P
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
