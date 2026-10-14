% Amir 3D method with Double accuracy implimentation

clear all
clc
close all

num = 10;
A = [3 3 3];
B = [7 7 7];
L = -10;
mu1 = 3;
mu2 = 6;
mu3 = 3.105; %3.10825;
alpha1 = 0;
alpha2 = 0;
alpha3 = 0;
sigma11 = 1;
sigma22 = 1;
sigma33= 1.0;
sigma_D = [sigma11 sigma22 sigma33];
sigma12 = 0.0;
sigma13 = 0;
sigma21 = 0.0;
sigma23 = 0;
sigma31 = 0; 
sigma32 = 0;
ALPHA = [alpha1 alpha2 alpha3];
SIGMA = [sigma_D(1)^2 sigma12^2 sigma13^2;...
        sigma21^2 sigma_D(2)^2 sigma23^2;...
        sigma31^2 sigma32^2 sigma_D(3)^2];
MU = [mu1 mu2 mu3]

%% Implement Stnadard Amri Method

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

LB = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3)
if LB < 0
    LB = 0
end
UB = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3])

s1 = struct('Fa1a2a3',Fa1a2a3,'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,...
    'Fa1b2b3',Fa1b2b3,'Fb1a2a3',Fb1a2a3,'Fb1a2b3',Fb1a2b3,...
    'Fb1b2a3',Fb1b2a3,'Fb1b2b3',Fb1b2b3)

%% Implement double accuracy (See Rectangular Probabilties Report [Dodd 2013])
% The case where LB = 0
if LB == 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3]      % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    V = P;                              % Set V = P then delete the 
    V(MaxPPos) = [];                    % largest term.
    LB_Eq = sum(V) - prod(V)
    if LB_Eq > 0.5
         LB_D = LB
         UB_D = (UB-LB)/2
    elseif LB_Eq < 0.5
         LB_D = (UB-LB)/2
         UB_D = UB
    else LB_D = (UB-LB)/2
         UB_D = (UB-LB)/2
    end
end 

% The case where LB > 0
if LB > 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3]                   % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    Mu_LB = MU; Mu_LB(MaxPPos) = []                  % Delete largest MU term corresponding to largest F(*1,*2,*3)
    sigma_D_LB = sigma_D; sigma_D_LB(MaxPPos) = []   % Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
    A_LB = A; A_LB(MaxPPos) = []                     % Delete largest A term corresponding to largest F(*1,*2,*3)
    Delta = 1/normcdf(A_LB(1),Mu_LB(1),sigma_D_LB(1)) + ...
            1/normcdf(A_LB(2),Mu_LB(2),sigma_D_LB(2))% Calc Delta i.e. 
            % how much smaller is the sticking out box (the N box in
            % Rectangular Probabilties Report, [Dodd (2013)])
    % Calc the gradient dN/dMu
    Mu_Vec = linspace(2.5,3.5,10);
        for i = 1:length(Mu_Vec)
            P(i) = (1-normcdf(A(MaxPPos),Mu_Vec(i),sigma_D(MaxPPos)))/Delta;
        end
    AvgGrad = polyfit(Mu_Vec,P,1)  % fit a linear line through data
    dN_dMu = AvgGrad(1,1)
    tic
    fun = @(mu) (1-normcdf(A(MaxPPos),A(MaxPPos),sigma_D(MaxPPos)))/Delta...
        + (mu*dN_dMu - A(MaxPPos)*dN_dMu)...
        - (0.5 - normcdf(A(MaxPPos),mu,sigma_D(MaxPPos)));
    x0 = 3;
    mu_x = fzero(fun,x0)
    df=toc
        if MU(MaxPPos) < mu_x
             LB_D = (UB-LB)/2+LB;
             UB_D = UB;
        elseif MU(MaxPPos) > mu_x
             LB_D = LB;
             UB_D = (UB-LB)/2+LB;
        else LB_D = (UB-LB)/2+LB;
             UB_D = (UB-LB)/2+LB;
        end
end

E = mvncdf([3 3 3],[7 7 7],MU,SIGMA)
figure(3)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(LB_D,0,'k*','MarkerSize',15); hold on
plot(UB_D,0,'m*','MarkerSize',15); hold on
plot(E,0,'b.','MarkerSize',30); grid on

alt =  max([Fa1b2b3,Fb1a2b3,Fb1b2a3])+((1- max([Fa1b2b3,Fb1a2b3,Fb1b2a3]))/Delta)
if alt < 0.5
    disp('LB to Middle')
elseif alt > 0.5
    disp('Middle to UB')
end
