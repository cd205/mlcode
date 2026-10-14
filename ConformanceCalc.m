function [P_success,P_fail,cpk] = ConformanceCalc(mu_L,mu_R,mu_N,mu_B,sigma_L,sigma_R,sigma_N,sigma_B,USL,LSL,n)

mu = [mu_L mu_R mu_N mu_B];
SIGMA = [sigma_L^2 0 0 0; 0 sigma_R^2 0 0; 0 0 sigma_N^2 0; 0 0 0 sigma_B^2];
data = mvnrnd(mu,SIGMA,n);
actflow = (pi.*data(:,2).*data(:,2).*data(:,1)./1E6 - data(:,4)).*data(:,3);
N_USL = length(find(actflow>USL));
N_LSL = length(find(actflow<LSL));
N_S = length(find(actflow>LSL & actflow<USL));
P_USL = N_USL/n;
P_LSL = N_LSL/n;
P_fail = (N_USL+N_LSL)/n;
P_success = N_S/n;
S = capability(actflow,[LSL,USL]);
cpk = S(1).Cpk;