function dp=cp_to_dp(param) 
%cp_to_dp dp_to_cp
%Conversion between equivalent parametrizations
% 
%DESCRIPTION
% 
%Convert direct to centred parameters of the skew-normal distribution,
%and viceversa
% 
%USAGE
% 
%cp_to_dp(param)
%dp_to_cp(param)
% 
%REQUIRED ARGUMENTS
% 
%param	a vector of length al least three. If length(param) is m+2, then
%the first m components refer to the regression coefficients (or the
%location parameter, in case m is 1), and the remaining two components
%refer to scale and shape, respectively; their role is preserved across
%parametrizations.
% 
%VALUE
% 
%a vector of the same length of param, representing param in the
%alternative parametrization; cp_to_dp converts centred to direct
%parameters, dp_to_cp converts direct to centred parameters.
% 
%DETAILS
% 
%The advantages of using the centred parametrization, rather than the
%direct one, are discussed in the reference below.
% 
%REFERENCES
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%sn_mle, sn_em
% 
%EXAMPLES
% 
%cp = dp_to_cp([30,30,2,4])
%dp = cp_to_dp(cp)

if nargin<1 error('Argument is missing');
end;
b=sqrt(2/pi);
m=length(param)-2;
gamma1=param(m+2);
if abs(gamma1)>0.9952719 error('abs(gamma1)>0.9952719');
end;
A=sign(gamma1)*(abs(2*gamma1/(4-pi)))^(1/3);
delta=A/(b*sqrt(1+A^2));
lambda=delta/sqrt(1-delta^2);
E_Z=b*delta;
sd_Z=sqrt(1-E_Z^2);
location=param(1:m);
location(1)=param(1)-param(m+1)*E_Z/sd_Z;
scale=param(m+1)/sd_Z;
%dp(m+1).name='scale'; si utilizza una structure
%dp(m+2).name='shape';
dp=[location,scale,lambda];   