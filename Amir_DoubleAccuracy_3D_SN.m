% Amir 3D method with Double accuracy implimentation
% Using Skew Normal distributions

clear all
clc
close all

AmirDoubleAccuracy = tic;
Amir = tic;
num = 10;
A = [3 3 3];
B = [7 7 7];
L = -10;
% loc1 = 4
% loc2 = 5;
% loc3 = 3.0; %3.10825;
alpha1 = -4;
alpha2 = -3;
alpha3 = -4;
scale11 = 1;
scale22 = 1;
scale33= 1.0;
scale_D = [scale11 scale22 scale33];
scale12 = 0.0;
scale13 = 0;
scale21 = 0.0;
scale23 = 0;
scale31 = 0; 
scale32 = 0;
% Specify means and calculate locations
mu1 = 5
mu2 = 4.5
mu3 = 3
loc1 = mu1 - scale11*(alpha1/sqrt(1+alpha1^2))*(sqrt(2/pi))
loc2 = mu2 - scale22*(alpha2/sqrt(1+alpha2^2))*(sqrt(2/pi))
loc3 = mu3 - scale33*(alpha3/sqrt(1+alpha3^2))*(sqrt(2/pi))
%mu1 = loc1 + scale11*(alpha1/sqrt(1+alpha1^2))*(sqrt(2/pi));
%mu2 = loc2 + scale22*(alpha2/sqrt(1+alpha2^2))*(sqrt(2/pi));
%mu3 = loc3 + scale33*(alpha3/sqrt(1+alpha3^2))*(sqrt(2/pi));
% Plot Distribution
subplot(1,3,1)
p_vec = linspace(-0,10,50);
snpdf1 = dsn(p_vec,loc1,scale11,alpha1);
snpdf2 = dsn(p_vec,loc2,scale22,alpha2);
snpdf3 = dsn(p_vec,loc3,scale33,alpha3);
plot(p_vec,snpdf1); grid on
line([A(1) A(1)], [0 max(snpdf1)],'Color',[1 0 0]);
line([B(1) B(1)], [0 max(snpdf1)],'Color',[0 1 0]);
xlabel('\mu_1')
subplot(1,3,2)
plot(p_vec,dsn(p_vec,loc2,scale22,alpha1)); grid on
line([A(2) A(2)], [0 max(snpdf2)],'Color',[1 0 0]);
line([B(2) B(2)], [0 max(snpdf2)],'Color',[0 1 0]);
xlabel('\mu_2')
subplot(1,3,3)
plot(p_vec,dsn(p_vec,loc3,scale33,alpha3)); grid on
line([A(3) A(3)], [0 max(snpdf3)],'Color',[1 0 0]);
line([B(3) B(3)], [0 max(snpdf3)],'Color',[0 1 0]);
xlabel('\mu_3')


ALPHA = [alpha1 alpha2 alpha3];
SCALE = [scale_D(1)^2 scale12^2 scale13^2;...
        scale21^2 scale_D(2)^2 scale23^2;...
        scale31^2 scale32^2 scale_D(3)^2];
LOC = [loc1 loc2 loc3];
MUS = [mu1 mu2 mu3];
%% Implement Stnadard Amri Method

% Define trivariate skew normal function
fun3d = @(X,Y,Z) dmsn_triplequad(X,Y,Z,LOC,SCALE,ALPHA);
% Integrate trivariate skew normal distribtuin between limits
Fa1b2b3 = triplequad(fun3d,L,A(1),L,B(2),L,B(3));
Fb1a2b3 = triplequad(fun3d,L,B(1),L,A(2),L,B(3));
Fb1b2a3 = triplequad(fun3d,L,B(1),L,B(2),L,A(3));
Fb1b2b3 = triplequad(fun3d,L,B(1),L,B(2),L,B(3));

LB = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3)
if LB < 0
    LB = 0
end
UB = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3])

%s1 = struct('Fa1a2a3',Fa1a2a3,'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,...
%    'Fa1b2b3',Fa1b2b3,'Fb1a2a3',Fb1a2a3,'Fb1a2b3',Fb1a2b3,...
%    'Fb1b2a3',Fb1b2a3,'Fb1b2b3',Fb1b2b3)
AmirStandardTime = toc(Amir)
%% Implement double accuracy (See Rectangular Probabilties Report [Dodd 2013])
% The case where LB = 0
if LB == 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];      % These are all the possilbe terms
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
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];                   % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    Loc_LB = LOC; Loc_LB(MaxPPos) = []                  % Delete largest MU term corresponding to largest F(*1,*2,*3)
    scale_D_LB = scale_D; scale_D_LB(MaxPPos) = []   % Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
    A_LB = A; A_LB(MaxPPos) = []                     % Delete largest A term corresponding to largest F(*1,*2,*3)
    SN_pdf1 = @(X1) dsn(X1,Loc_LB(1),scale_D_LB(1),ALPHA(1));
    SN_pdf2 = @(X2) dsn(X2,Loc_LB(2),scale_D_LB(2),ALPHA(2));
    Delta = 1/quadl(SN_pdf1,L,A(1)) + ...
            1/quadl(SN_pdf2,L,A(2))% Calc Delta i.e. 
            % how much smaller is the sticking out box (the N box in
            % Rectangular Probabilties Report, [Dodd (2013)])
    % Calc the gradient dN/dMu
    Loc_Vec = linspace(2.5,3.5,5);
        for i = 1:length(Loc_Vec)
            SN_pdf3 = @(X3) dsn(X3,Loc_Vec(i),scale_D(MaxPPos),ALPHA(MaxPPos));
            P(i) = (1-quadl(SN_pdf3,L,A(MaxPPos)))/Delta;
        end
    AvgGrad = polyfit(Loc_Vec,P,1)  % fit a linear line through data
    dN_dMu = AvgGrad(1,1)
    SN_pdf4 = @(X4) dsn(X4,A(MaxPPos),scale_D(MaxPPos),ALPHA(MaxPPos))
    %SN_pdf5 = @(loc) dsn(A(MaxPPos),loc,scale_D(MaxPPos),ALPHA(MaxPPos))
    fun = @(Loc) (1-quadl(SN_pdf4,L,A(MaxPPos)))/Delta...
        + (Loc*dN_dMu - A(MaxPPos)*dN_dMu)...
        - (0.5 - Quad_SN_pdf5(L,A,Loc,scale_D,ALPHA,MaxPPos));
       % normcdf(A(MaxPPos),mu,sigma_D(MaxPPos)));
    x0 = 3;
    Loc_x = fzero(fun,x0) 
        if LOC(MaxPPos) < Loc_x
             LB_D = (UB-LB)/2+LB;
             UB_D = UB;
        elseif LOC(MaxPPos) > Loc_x
             LB_D = LB;
             UB_D = (UB-LB)/2+LB;
        else LB_D = (UB-LB)/2+LB;
             UB_D = (UB-LB)/2+LB;
        end
end
AmirDoubleAccTime = toc(AmirDoubleAccuracy)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Work it out exactly
StandardMethod = tic;
Fa1a2a3 = triplequad(fun3d,L,A(1),L,A(2),L,A(3));
Fa1a2b3 = triplequad(fun3d,L,A(1),L,A(2),L,B(3));
Fa1b2a3 = triplequad(fun3d,L,A(1),L,B(2),L,A(3));
Fa1b2b3 = triplequad(fun3d,L,A(1),L,B(2),L,B(3));
Fb1a2a3 = triplequad(fun3d,L,B(1),L,A(2),L,A(3));
Fb1a2b3 = triplequad(fun3d,L,B(1),L,A(2),L,B(3));
Fb1b2a3 = triplequad(fun3d,L,B(1),L,B(2),L,A(3));
Fb1b2b3 = triplequad(fun3d,L,B(1),L,B(2),L,B(3));

E = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
    + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3
StandardMthTime = toc(StandardMethod)

figure(2)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(LB_D,0,'k*','MarkerSize',15); hold on
plot(UB_D,0,'m*','MarkerSize',15); hold on
plot(E,0,'b.','MarkerSize',30); grid on
