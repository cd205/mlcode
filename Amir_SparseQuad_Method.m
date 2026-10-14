%% Amir_SparseQuad %%
clear all
clc
%%% INPUTS %%%
sig = 2
5;
num = 7;
Lower = -2.8; % lower bound to integrate from
A = -sig.*ones(1,num); % input of all the lower bounds
B = sig.*ones(1,num);  % input of all the upper bounds
global Variability
Variability.Mu = zeros(1,length(B));
Variability.Sigma = diag(ones(1,length(B)),0);
start2 = tic;
options = spset('GridType','Clenshaw-Curtis','Vectorized','off');
fnorm = @(x1,x2,x3,x4,x5,x6,x7) mvnpdf(([x1,x2,x3,x4,x5,x6,x7]),Variability.Mu,Variability.Sigma);
% z = spvals(fnorm,num,[Lower B(1);Lower B(2);Lower B(3);Lower B(4)],options);  
% F_quad = spquad(z)
% toc(start2)
F_quad_Exact = mvncdf(A,B,Variability.Mu,Variability.Sigma)


for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    limits(i,:) = [temp1];
    clear temp1
end
z = spvals(fnorm,num,limits,options);  
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

% SOLVE THE CDFS USING MONTE CARLO INTEGRATION %
clear Fs
for i = 1:length(CDF_Lims(:,1))
    clear Limits
  
    limits(:,1) = Lower.*ones(length(CDF_Lims(:,1)),1);
    limits(:,2) = CDF_Lims(i,:)';
    limits;
    z = spvals(fnorm,num,limits,options);  
    Fs(i) = spquad(z);
end
time2 = toc(start2);
Lower_P2 = max(F_B - sum(Fs),0);
Upper_P2 = F_B - max(Fs);

disp(['Amir Sparse Quadrature Method: Run time = ', num2str(time2)])
disp(['Lower bound: ', num2str(Lower_P2), ' Upper bound: ', num2str(Upper_P2)])

