%% Integration speed test of normal functions %%
clear all
clc
%%% INPUTS %%%
sig = 2;
num = 4;
Lower = -5; % lower bound to integrate from
A = -sig.*ones(1,num); % input of all the lower bounds
B = sig.*ones(1,num);  % input of all the upper bounds
global Variability
Variability.Mu = zeros(1,length(B));
Variability.Sigma = diag(ones(1,length(B)),0);

%% EXACT %%
Exact = mvncdf(A,B,Variability.Mu,Variability.Sigma)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AMIR'S METHOD - MONTE CARLO  %%
% Set up MC integration uses mcint.m
n = 1e8;  %number of MC evaluations
opt.maxArray = 1e5;
opt.noerror = 0;
opt.time = 60; 
%opt.tol = 2e-4;
opt.warnOff = 0;
start1 = tic;
for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    h.b(i,:) = [temp1];
    clear temp1
end
h.cond = {};
h.funcs = {@Normfun_nD};  % this is the equation to be integrated
[I,info] = mcint(h, n, opt);
F_B = I(:,:,1);
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
for i = 1:length(CDF_Lims(:,1))
    clear h
    clear I
    h.b(:,1) = Lower.*ones(length(CDF_Lims(:,1)),1);
    h.b(:,2) = CDF_Lims(i,:)';
    h.cond = {};
    h.funcs = {@Normfun_nD};  % this is the equation to be integrated
    [I,info] = mcint(h, n, opt);
    Fs(i) = I(:,:,1);
end

Lower_P1 = max(F_B - sum(Fs),0);
Upper_P1 = F_B - max(Fs);
time1 = toc(start1);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AMIR'S METHOD - SPARSE QUADRATURE  %%
start2 = tic;
options = spset('GridType','Clenshaw-Curtis','Vectorized','off');
fnorm = @(x1,x2,x3,x4) mvnpdf(([x1,x2,x3,x4]),Variability.Mu,Variability.Sigma);
% z = spvals(fnorm,num,[Lower B(1);Lower B(2);Lower B(3);Lower B(4)],options);  
% F_quad = spquad(z)
% toc(start2)
% F_quad_Exact = mvncdf(Lower.*ones(1,num),B,Variability.Mu,Variability.Sigma)


for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    limits(i,:) = [temp1];
    clear temp1
end
z = spvals(fnorm,num,limits,options);  
F_B = spquad(z);

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
disp(['Amir Monte Carlo Method: Run time = ', num2str(time1)])
disp(['Lower bound: ', num2str(Lower_P1), ' Upper bound: ', num2str(Upper_P1)])
disp(['Amir Sparse Quadrature Method: Run time = ', num2str(time2)])
disp(['Lower bound: ', num2str(Lower_P2), ' Upper bound: ', num2str(Upper_P2)])

