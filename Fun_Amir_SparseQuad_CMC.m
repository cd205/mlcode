%function [PLB UB]=Fun_Amir_SparseQuad_CMC(CUT1,CUT2,sigma1_D,sigma2_D,A,B,NOM)
clear all
close all
clc
tic
CUT1 = [6 3 4.1];
CUT2 = [5 3 3];
sigma1_D = [0.8 0.8 0.8];
sigma2_D = [0.8 0.8 0.8];
A = [3 3 3];
B = [7 7 7];
range = [-5 10]
flag = 1
% INPUTS -   A: List of all the lower bounds [a1,a2,...,an]
%            B: List of all the upper bounds [b1,b2,...,bn]
%            Mu: List of the means for each distribution [Mu1,Mu2,...,Mun]
%            Sigma: List of sigmas for each distribution [s1,s2,...,sn]

% OUTPUTS -  PL: The lower bound of the probability
%            PU: The upper bound of the probability
%


%sig = 2
%5;
num = length(A);
 Lower = 0; % lower bound to integrate from

options = spset('GridType','Clenshaw-Curtis','Vectorized','on','RelTol',1e-6,'AbsTol',1e-9,'MaxPoints',100000,'DimensionAdaptive','on','DimadaptDegree',1);

% Create the input vector for fnorm [x1,x2,...,xn].  The method used here 
% is not very elegent but surfices

[mvd,x,y,z] = mvnCMCdist(CUT1,CUT2,sigma1_D,sigma2_D,A,B,range,flag);
funCMC3d = @(x1,x2,x3) interp3(x,y,z,mvd,x1,x2,x3)

%funCMC3d =  @(X,Y,Z) cmc_triplequad(X,Y,Z,Variability.CUT1,Variability.CUT2,Variability.sigma1_D,Variability.sigma2_D,A,B,NOM)
%funCMC3d =  @(X,Y,Z) mvnpdf([X,Y,Z],Variability.CUT2,Variability.sigma2_D)
% fnorm = {@(x1,x2) (mvnpdf([x1,x2],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3) (mvnpdf([x1,x2,x3],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4) (mvnpdf([x1,x2,x3,x4],Variability.Mu,Variability.Sigma))
%     @(x1,x2,x3,x4,x5) (mvnpdf([x1,x2,x3,x4,x5],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6) (mvnpdf([x1,x2,x3,x4,x5,x6],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6,x7) (mvnpdf([x1,x2,x3,x4,x5,x6,x7],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6,x7,x8) (mvnpdf([x1,x2,x3,x4,x5,x6,x7,x8],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6,x7,x8,x9) (mvnpdf([x1,x2,x3,x4,x5,x6,x7,x8,x9],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) (mvnpdf([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11) (mvnpdf([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11],Variability.Mu,Variability.Sigma));
%     @(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12) (mvnpdf([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12],Variability.Mu,Variability.Sigma))};

for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    limits(i,:) = [temp1];
    clear temp1
end
z = spvals(funCMC3d,num,limits,options);  
F_B = spquad(z)

% Determine the CDF evaluation limits

for i = 1:length(B)
    cc = 0;
    % first limit
    for j1 = 1:i-1
        fb1(j1) = B(j1);
    end
    fa = [A(i)];
    for j2 = i+1:length(B)
        cc = cc + 1;
        fb2(cc) = B(j2);
    end
    % Check if variable have been created and the collate the CDFs to
    % evaluate
    if exist('fb1') == 0
        CDF_Lims(i,:) = [fa,fb2]
    elseif exist('fb2') == 0
        CDF_Lims(i,:) = [fb1,fa]
    else
        CDF_Lims(i,:) = [fb1,fa,fb2]
    end
    clear fb1
    clear fa
    clear fb2
    clear cc
end


clear Fs
for i = 1:length(CDF_Lims(:,1))
    clear Limits
    limits(:,1) = Lower.*ones(length(CDF_Lims(:,1)),1);
    limits(:,2) = CDF_Lims(i,:)';
    limits;
    z = spvals(funCMC3d,num,limits,options);  
    Fs(i) = spquad(z);
end

LB = max(F_B - sum(Fs),0)
UB = F_B - max(Fs)



Fa1b2b3 = Fs(1)
Fb1a2b3 = Fs(2)
Fb1b2a3 = Fs(3)

%% Find means of the Cut-measure-cut distributions %%

dist1 = @(x1) Fun_Cut_Measure_Cut_Dist(x1,CUT1(1),CUT2(1),sigma1_D(1),sigma2_D(1),A(1),B(1));
dist2 = @(x2) Fun_Cut_Measure_Cut_Dist(x2,CUT1(2),CUT2(2),sigma1_D(2),sigma2_D(2),A(2),B(2));
dist3 = @(x3) Fun_Cut_Measure_Cut_Dist(x3,CUT1(3),CUT2(3),sigma1_D(3),sigma2_D(3),A(3),B(3));
dist1_mu = @(mu1) quadl(dist1,0,mu1)-0.5;
dist2_mu = @(mu2) quadl(dist2,0,mu2)-0.5;
dist3_mu = @(mu3) quadl(dist3,0,mu3)-0.5;
mu1 = fzero(dist1_mu,CUT2(1))
mu2 = fzero(dist2_mu,CUT2(2))
mu3 = fzero(dist3_mu,CUT2(3))
MU = [mu1 mu2 mu3]

%% Implement double accuracy (See Rectangular Probabilties Report [Dodd 2013])
% The case where LB = 0
if LB == 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];      % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    V = P;                              % Set V = P then delete the 
    V(MaxPPos) = [];                    % largest term.
    LB_Eq = sum(V) - prod(V);
    if LB_Eq > F_B/2  %F_B/2 should be 0.5 if there is not rework
         LB_D = LB;
         UB_D = (UB-LB)/2;
    elseif LB_Eq < F_B/2  %F_B/2 should be 0.5 if there is not rework
         LB_D = (UB-LB)/2;
         UB_D = UB;
    else LB_D = (UB-LB)/2;
         UB_D = (UB-LB)/2;
    end
end 

% The case where LB > 0
if LB > 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];                   % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    CUT1_LB = CUT1; CUT1_LB(MaxPPos) = [];            % Delete largest CUT1 term corresponding to largest F(*1,*2,*3)
    CUT2_LB = CUT2; CUT2_LB(MaxPPos) = [];            % Delete largest CUT1 term corresponding to largest F(*1,*2,*3)
    sigma1_D_LB = sigma1_D; sigma1_D_LB(MaxPPos) = [];% Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
    sigma2_D_LB = sigma2_D; sigma2_D_LB(MaxPPos) = [];% Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
    A_LB = A; A_LB(MaxPPos) = [];                     % Delete largest A term corresponding to largest F(*1,*2,*3)
    B_LB = B; B_LB(MaxPPos) = [];
   
    FD1 = @(v1) Fun_Cut_Measure_Cut_Dist(v1,CUT1_LB(1),CUT2_LB(1),sigma1_D_LB(1),sigma2_D_LB(1),A_LB(1),B_LB(1));
    FD2 = @(v2) Fun_Cut_Measure_Cut_Dist(v2,CUT1_LB(2),CUT2_LB(2),sigma1_D_LB(2),sigma2_D_LB(2),A_LB(1),B_LB(2));
    Delta = 1/quad(FD1,0,A_LB(1)) + 1/quad(FD2,0,A_LB(2)) % Calc Delta i.e. 
            % how much smaller is the sticking out box (the N box in
            % Rectangular Probabilties Report, [Dodd (2013)])
            % Calc the gradient dN/dMu
    A_Vec = linspace(2.5,3.5,10);
    FD3 = @(v3) Fun_Cut_Measure_Cut_Dist(v3,CUT1(MaxPPos),CUT2(MaxPPos),sigma1_D(MaxPPos),sigma2_D(MaxPPos),A(MaxPPos),B(MaxPPos));
        for i = 1:length(A_Vec)
            P(i) = quad(FD3,0,A_Vec(i))/Delta;
        end
    AvgGrad = polyfit(A_Vec,P,1)  % fit a linear line through data
    dN_dMu = AvgGrad(1,1)
    fun = @(LocA) (F_B/2)/Delta...   % F_B/2 should be about 0.5 depending on total rework
        + (LocA*dN_dMu - A(MaxPPos)*dN_dMu)...
        - (F_B/2 - quad(FD3,0,LocA)); % F_B/2 should be about 0.5 depending on total rework
    %normcdf(A(MaxPPos),mu,sigma_D(MaxPPos)));
    x0 = 3;
    LocA_x = fzero(fun,x0) 
        if MU(MaxPPos) < LocA_x
             LB_D = (UB-LB)/2+LB;
             UB_D = UB;
        elseif MU(MaxPPos) > LocA_x
             LB_D = LB;
             UB_D = (UB-LB)/2+LB;
        else LB_D = (UB-LB)/2+LB;
             UB_D = (UB-LB)/2+LB;
        end
end
toc
%runtime = toc(start1)

%E = mvncdf([3 3 3],[7 7 7],MU,SIGMA)
figure(3)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(LB_D,0,'k*','MarkerSize',15); hold on
plot(UB_D,0,'m*','MarkerSize',15); grid on
