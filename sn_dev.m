function dev=sn_dev(cp,X,y,traceout)
%sn_dev
%Deviance for skew-normal distributions
% 
%DESCRIPTION
% 
%Computes twice the negative log-likelihood (essentially, the deviance)
%for regression models with errors having a skew-normal distribution.
% 
%USAGE
% 
%sn_dev(cp, X, y, traceout)
% 
%REQUIRED ARGUMENTS
% 
%cp	a vector of initial values for the centred parameters, with
% 	length(cp)=size(X,2)+2
% 
%X	a matrix of explanatory variables. Missing values (NaN) are not
% 	allowed.
% 
%y	a vector contaning the observed variable. Missing values (NaN)
% 	are not allowed.
% 
%OPTIONAL ARGUMENTS
% 
%traceout logical value. If trace=1, details are printed. Default value is
% 	0.
% 
%VALUE
% 
%a numeric value
% 
%DETAILS
% 
%This is the objective function of sn_mle, whose documentation gives
%additional details.
% 
%SEE ALSO
% 
%sn_mle,msn_mle

if nargin<4 traceout=0;
end;
if nargin<3 error('Required arguments are missing');
end;
if isnan(traceout) traceout=0;
end;
%if isnan(X)
%   X=ones(length(y),1);
%end;
%-2*logL for centred parameters
y=reshape(y,length(y),1); %vettore colonna
m=size(X,2);
dp=cp_to_dp(cp); %vettore riga
location=X*dp(1:m)';
scale=dp(m+1);
%AVOID:logL=sum(log(dsn(y,location,dp(m+1),dp(m+2))));
z=(y-location)./scale;
nlogL=(length(y)*log(2.506628274631*scale)+0.5*sum(z.^2)-...
   sum(zeta(0,dp(m+2)*z)));
if traceout
   disp('sn.dev: (cp,logL)=');
   disp([cp,-nlogL]);
end;
dev=2*nlogL;
