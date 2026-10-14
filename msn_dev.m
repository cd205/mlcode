function dev=msn_dev(param,X,y,freq,traceout)
%msn_dev    Deviance for multivariate skew-normal distributions
% 
%DESCRIPTION
% 
%Computes twice the negative profile log-likelihood (essentially, a form
%of the deviance) for multivariate regression models with errors having a
%multivariate skew-normal distribution.
% 
%USAGE
% 
%msn_dev(param, X, y, freq, traceout)
% 
%REQUIRED ARGUMENTS
% 
%param	a numeric vector of parameter values.
%X	a matrix of explanatory variables. Missing values (NaN) are not allowed.
%y	a matrix contaning the response variable. Missing values (NaN) are not
% 	allowed.
%freq	a vector of weights, with length equal to size(y,1).
% 
%OPTIONAL ARGUMENTS
% 
%traceout  logical value. If trace=1, details are printed. Default value is 0.
% 
%VALUE
% 
%a numeric value.
% 
%SIDE EFFECTS
% 
%describe any side effects if they exist
% 
%DETAILS
% 
%This is the objective function of msn_mle, whose documentation gives
%additional details.
% 
%SEE ALSO
% 
%msn_mle,msn_fit,sn_mle

if nargin<5 traceout=0;
end;
%if nargin<4 freq=ones(1,size(y,1));
%end;
if isnan(traceout) traceout=0;
end;
k=size(y,2);
n=sum(freq);
m=size(X,2);
beta=reshape(param(1:(m*k)),m,k);
al_om=param((m*k+1):(m*k+k));
y0=y-X*beta;
Omega=(y0'*(y0.*repmat(freq',1,k)))./n;
logDet=log(det(2.*pi.*Omega));
if traceout
   disp('msn.dev:');
   disp([beta;al_om]);
end;
dev=n.*logDet-2.*sum(zeta(0,(y0*al_om')).*freq)+n.*k;
