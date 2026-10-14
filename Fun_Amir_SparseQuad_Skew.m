function [PL PU]=Fun_Amir_SparseQuad_Skew(A,B,Xi,Omega,Alpha)

% INPUTS -   A: List of all the lower bounds [a1,a2,...,an]
%            B: List of all the upper bounds [b1,b2,...,bn]
%            Xi: List of the means for each distribution [Xi1,Xi2,...,Xin]
%            Omega: A Covariance matrix 
%            Alpha: Vector of shape parameters

% OUTPUTS -  PL: The lower bound of the probability
%            PU: The upper bound of the probability
%
% EXAMPLE -  (this can be copied and pasted into the command window)
% A = [3 3 3]
% B = [7 7 7]
% Xi = [5 5 5]
% Omega = [1 1 1]
% Alpha = [ 0 0 0]
% [PL PU]=Fun_Amir_SparseQuad_Skew(A,B,Mu,Sigma)
% ExactNorm = mvncdf(A,B,Mu,Sigma)


num = length(A);
Lower = 0; % lower bound to integrate from
global Variability
Variability.Xi = Xi%zeros(1,length(B));
Variability.Omega = Omega%diag(ones(1,length(B)),0);
Variability.Alpha = Alpha
%start2 = tic;
options = spset('GridType','Clenshaw-Curtis','Vectorized','on','RelTol',1e-8,'AbsTol',1e-12,'MaxPoints',100000,'DimensionAdaptive','on','DimadaptDegree',1);
%options = spset('RelTol',1e-6,'AbsTol',1e-9)

% Create the input vector for fnorm [x1,x2,...,xn].  The method used here 
% is not very elegent but surfices

% fnorm_Input_vec = sprintf('x%u,',1:num);
% fnorm_Input_vec(end) = []

% this goes to 12 dimensions, add more if nessesary
fnorm = {@(x1,x2) (dmsn([x1,x2],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3) (dmsn([x1,x2,x3],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4) (dmsn([x1,x2,x3,x4],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5) (dmsn([x1,x2,x3,x4,x5],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6) (dmsn([x1,x2,x3,x4,x5,x6],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6,x7) (dmsn([x1,x2,x3,x4,x5,x6,x7],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6,x7,x8) (dmsn([x1,x2,x3,x4,x5,x6,x7,x8],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6,x7,x8,x9) (dmsn([x1,x2,x3,x4,x5,x6,x7,x8,x9],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10) (dmsn([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11) (dmsn([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11],Variability.Xi,Variability.Omega,Variability.Alpha));
    @(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12) (dmsn([x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12],Variability.Mu,Variability.Sigma))};

for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    limits(i,:) = [temp1];
    clear temp1
end
z = spvals(fnorm{num-1},num,limits,options);  
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
    z = spvals(fnorm{num-1},num,limits,options);  
    Fs(i) = spquad(z);
end

PL = max(F_B - sum(Fs),0);
PU = F_B - max(Fs);


