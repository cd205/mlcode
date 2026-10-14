function ris=zeta(k,x)
%zeta
%Function log(2*P(x)) and its derivatives
% 
%DESCRIPTION
% 
%The function log(2 P(x)) and its derivatives up to order 4, if P(x)
%denotes the standard normal distribution function.
% 
%USAGE
% 
%zeta(k, x)
% 
%REQUIRED ARGUMENTS
% 
%k	an integer scalar.
% 
%x	a vector. Missing values (NaN) are allowed, but Infs are not.
% 
%VALUE
% 
%a vector; this is the k-th order derivative evaluated at x
% 
%DETAILS
% 
%k denotes the order of the derivative. If k is 0, the function is
%evaluated, using normcdf(x) for x>-35,  an asymptotic expansion otherwise.
%For k between 1 and 4, the derivative of that order is evaluated. For
%k>4, a warning message is issued, and a vector of NaN is returned.
% 
%This function is used by sn_dev and msn_dev, among others.
% 
%SEE ALSO
% 
%sn_mle, msn_mle
% 
%EXAMPLES
% 
%y = zeta(2,[-20:0.5:20])

%k integer in (0,4)
warning off; %sopprime gli eventuali warning (se x=0)
k=fix(k);
na=isnan(x);
x(na)=0;
if any(abs(x)==Inf) error('Inf not allowed');
end;
%it would work for k=0 but not for k>1
ok=(-35<x);
switch k
case 0, 
   ax=-x(~ok);
   ay=(-0.918938533204673)-0.5.*ax.^2-log(ax);
   y=repmat(NaN,1,length(x));
   if ~isempty(x(ok)) y(ok)=log(2*normcdf(x(ok)));
   end;
   y(~ok)=ay;
case 1,
   y=(-x).*(1+1./x.^2);
   if ~isempty(x(ok)) y(ok)=normpdf(x(ok))./normcdf(x(ok));
   end;
case 2,
   y=(-zeta(1,x).*(x+zeta(1,x)));
case 3,
   y=(-zeta(2,x).*(x+zeta(1,x))-zeta(1,x).*(1+zeta(2,x)));
case 4,
   y=(-zeta(3,x).*(x+2.*zeta(1,x))-2.*zeta(2,x).*(1+zeta(2,x)));
otherwise,
   warning on; %riattiva i warnings
   warning('k>4');
   y=repmat(NaN,1,length(x));
end;
warning on; %riattiva i warning
y(na)=NaN;
ris=y;
   



