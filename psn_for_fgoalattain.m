function minF = psn_for_fgoalattain(x)
cdf_N = psn([0:0.01:x],0.575,0.0833,-6);
format long
F = cdf_N(end);
minF = abs(0.5 - F);