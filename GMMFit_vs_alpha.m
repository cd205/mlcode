% See how fitting improves with higher confidence levels 'alpha'
clear all
clc
num1 = 50
num2 = 50
mu1 = 1
mu2 = 2
sigma1 = 1
sigma2 = 1
alpha = 0.1;

alpha = [0.15 0.10 0.05 0.01 0.005 0.001];
for j = 1:length(alpha)
    parfor i = 1:1000
        ParamEsts(i,:) = Fun_GMMFit_MLE(num1,num2,mu1,mu2,sigma1,sigma2,alpha);
    end
    AvgParamEsts(j,:) = mean(ParamEsts)
end
