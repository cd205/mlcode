function [PL PU]=Fun_Amir_SparseQuad_CMC(CUT1,CUT2,sigma1_D,sigma2_D,A,B,NOM)

% INPUTS -   A: List of all the lower bounds [a1,a2,...,an]
%            B: List of all the upper bounds [b1,b2,...,bn]
%            Mu: List of the means for each distribution [Mu1,Mu2,...,Mun]
%            Sigma: List of sigmas for each distribution [s1,s2,...,sn]

% OUTPUTS -  PL: The lower bound of the probability
%            PU: The upper bound of the probability
%
% EXAMPLE -  (this can be copied and pasted into the command window)
% A = [3 3 3]
% B = [7 7 7]
% Mu = [5 5 5]
% Sigma = [1 1 1]
% [PL PU]=Fun_Amir_SparseQuad(A,B,Mu,Sigma)
% Exact = mvncdf(A,B,Mu,Sigma)

%sig = 2
%5;
num = length(A);
Lower = -5; % lower bound to integrate from
global Variability
Variability.CUT1 = CUT1;
Variability.CUT2 = CUT2;
Variability.sigma1_D = sigma1_D;
Variability.sigma2_D = sigma2_D;
%Variability.Sigma = Sigma%diag(ones(1,length(B)),0);
%start2 = tic;
options = spset('GridType','Clenshaw-Curtis','Vectorized','on','RelTol',1e-6,'AbsTol',1e-9,'MaxPoints',100000,'DimensionAdaptive','on','DimadaptDegree',1);
%options = spset('RelTol',1e-6,'AbsTol',1e-9)

% Create the input vector for fnorm [x1,x2,...,xn].  The method used here 
% is not very elegent but surfices

% fnorm_Input_vec = sprintf('x%u,',1:num);
% fnorm_Input_vec(end) = []

% this goes to 12 dimensions, add more if nessesary
funCMC3d =  @(X,Y,Z) cmc_triplequad(X,Y,Z,Variability.CUT1,Variability.CUT2,Variability.sigma1_D,Variability.sigma2_D,A,B,NOM)
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
        CDF_Lims(i,:) = [fa,fb2];
    elseif exist('fb2') == 0
        CDF_Lims(i,:) = [fb1,fa];
    else
        CDF_Lims(i,:) = [fb1,fa,fb2];
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

PL = max(F_B - sum(Fs),0);
PU = F_B - max(Fs);


