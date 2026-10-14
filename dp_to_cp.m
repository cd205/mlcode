function cp=dp_to_cp(param) 
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

%converts "direct" dp=(xi,omega,lambda) 
%to "centred" cp=(mu,sigma,gamma1)
if nargin<1 error('Argument is missing');
end;
m=length(param)-2;
omega=param(m+1);
lambda=param(m+2);
mu_Z=lambda*sqrt(2/(pi*(1+lambda^2)));
s_Z=sqrt(1-mu_Z^2);
gamma1=0.5*(4-pi)*(mu_Z/s_Z)^3;
sigma=omega*s_Z;
mu=param(1:m);
mu(1)=param(1)+sigma*mu_Z/s_Z;
%cp(m+1).name='sigma'; si utilizza una structure
%cp(m+2).name='skewness';
cp=[mu,sigma,gamma1];   