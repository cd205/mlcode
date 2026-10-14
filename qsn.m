function q=qsn(p,location,scale,shape,tol)
%dsn psn qsn rsn
%Skew-Normal Distribution
% 
%DESCRIPTION
% 
%Density function, distribution function, quantiles and random number
%generation for the skew-normal (SN) distribution.
% 
%USAGE
% 
%dsn(x, location, scale, shape)
%psn(q, location, scale, shape)
%qsn(p, location, scale, shape, tol)
%rsn(n, location, scale, shape)
% 
%REQUIRED ARGUMENTS
% 
%x	vector of quantiles. Missing values (NaN) are allowed.
%q	vector of quantiles. Missing values (NaN) are allowed.
%p	vector of probabilities. Missing values (NaN) are allowed.
% 
%OPTIONAL ARGUMENTS
% 
%location vector of location parameters (default is 0).
%scale	  vector of (positive) scale parameters (default is 1).
%shape	  vector of shape parameters. With 'psn' and 'qsn', it must 
%	  be of length 1 (default is 0).
%n	  sample size (default is 1).
%tol	  a scal value which regulates the accuracy of the result.
%         (default is 1e-8) 
%
%VALUE
% 
%density (dsn), probability (psn), quantile (qsn) or  random sample (rsn)
%from the skew-normal distribution with given location, scale and shape
%parameters.
% 
%BACKGROUND
% 
%The family of skew-normal distributions is an extension of the normal
%family, via the introdution of a shape parameter which regulates
%skewness; when shape=0, the skew-normal distribution reduces to the
%normal one.  The density of the SN distribution when location=0 and
%scale=1 is 2*dnorm(x)*pnorm(shape*x). A multivariate version of the
%distribution exists. See the references below for additional
%information.
% 
%DETAILS
% 
%psn make use of function T_Owen
% 
%REFERENCES
% 
%Azzalini, A. (1985). A class of distributions which includes the normal
%ones. Scand. J. Statist. 12, 171-178.
% 
%Azzalini, A. and Dalla Valle, A. (1996). The multivariate skew-normal
%distribution. Biometrika 83, 715-726.
% 
%SEE ALSO
% 
%T_Owen, dmsn, sn_mle
% 
%EXAMPLES
% 
%pdf = dsn([-3:0.1:3],0,1,3)
%cdf = psn([-3:0.1:3],0,1,3)
%qu = qsn([0.1:0.1:0.9],0,1,-2)
%rn = rsn(100, 5, 2, 5)

if nargin<5 tol=1e-8;
end;
if nargin<4 shape=0;
end;
if nargin<3 scale=1;
end;
if nargin<2 location=0;
end;
if nargin<1 error('Argument p (0=<p<=1) is missing');
end;
if isnan(tol) tol=1e-8;
end;
if isnan(location) location=0;
end;
if isnan(scale) scale=1;
end;
if isnan(shape) shape=0;
end;
na= (p<0)|(p>1)|(isnan(p));
zero= (p==0);
one= (p==1);
p(zero|one|na)=0.5;
cum=sn_cumulants(shape,4);
g1=cum(3)./cum(2).^(3/2);
g2=cum(4)./cum(2).^2;
x=norminv(p);
x=x+(x.^2+1).*g1./6+x.*(x.^2-3 ).*g2./ ...
   24-x.*(2.*x.^2-5).*g1.^2./36;
x=cum(1)+sqrt(cum(2)).*x; %a Cornish-Fisher start
max_err=1;
while (max_err>tol)
   x1=x-(psn(x,0,1,shape)-p)./dsn(x,0,1,shape);
   max_err=max(abs(x1-x)./(1.*abs(x)));
   x=x1;
end;
x(na)=NaN;
x(zero)=-Inf;
x(one)=Inf;
q=location+scale.*x;   