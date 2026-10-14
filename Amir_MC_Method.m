%% Amir Probability bound Method
% uses MC integration therefore only useful in 4D and greater
clear all 
clc
tic
%% Set up MC integration uses mcint.m
n = 1e8;  %number of MC evaluations
opt.maxArray = 1e5;
opt.noerror = 0;
opt.time = 60; 
%opt.tol = 2e-4;
opt.warnOff = 0;

%%% Inputs %%%
sig = 4;
num = 3;

Lower = -20; % lower bound to integrate from
A = -sig.*ones(1,num) % input of all the lower bounds
B = sig.*ones(1,num)% input of all the upper bounds

global Variability
Variability.Mu = zeros(1,length(B));
Variability.Sigma = diag(ones(1,length(B)),0);

for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    h.b(i,:) = [temp1];
    clear temp1
end
h.cond = {};
h.funcs = {@Normfun_nD};  % this is the equation to be integrated
[I,info] = mcint(h, n, opt);
F_B = I(:,:,1);
% %disp(info);
% disp('Integral:')
% I(:,:,1)
% if opt.noerror==0
%     disp('Error:')
%     I(:,:,2)
% end

%% DETERMINE THE CDF EVALUATION LIMITS %%
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
 CDF_Lims
 
%% SOLVE THE CDFS USING MONTE CARLO INTEGRATION %%
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

Lower_P = max(F_B - sum(Fs),0)
Upper_P = F_B - max(Fs)
toc
check  = mvncdf(A,B,Variability.Mu,Variability.Sigma)

