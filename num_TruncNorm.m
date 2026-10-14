function ft = num_TruncNorm(mu,U,L,n,sig)
% Simulate a truncated normal distribution 


% INPUTS - mu: mean
%          U:  upper spec limit
%          L:  lower spec limit
%          n:  number of components

% Example 
% clear all
% close all
% clc
% mu = 5; U = 6; L = 3; n=1000000; sig=1;

      

ft = mu+(randn(n,1)*sig);

[pos] = find(ft<L | ft>U);
for i = 1:length(pos)
    temp =  mu+(randn(1,1)*sig);
   
    while temp<L || temp >U
         temp = mu+(randn(1,1)*sig);
    end
    ft(pos(i)) = temp;
end
