function mle=msn_mle(X,y,freq,start,traceout,iter_max,x_tol)
%msn_mle
%Maximum likelihood estimation for multivariate skew-normal distribution
% 
%DESCRIPTION
% 
%Fits a multivariate skew-normal (MSN) distribution to data, or fits a
%linear regression model with multivariate skew-normal errors, using
%maximum likelihood estimation.
% 
%USAGE
% 
%msn_mle(X, y, freq, start, traceout, iter_max, x_tol)
% 
%REQUIRED ARGUMENTS
% 
%y	a matrix or a vector.  In y is a matrix, rows refer to
% 	observations, and columns to components of the multivariate
% 	distribution. In y is a vector, it is converted to a one-column matrix,
% 	and a scalar skew-normal distribution is fitted.
% 
%OPTIONAL ARGUMENTS
% 
%X	a matrix of covariate values. If missing, a one-column matrix of
% 	1's is created; otherwise, it must have the same number of rows of y.
% 
%freq	a vector of weights. If missing, a one-column matrix of 1's is
% 	created; otherwise it must have the same number of rows of y.
% 
%start	a list contaning the components beta,Omega, alpha, of the type
% 	described below. The dp component of the returned list from a previous
% 	call has the required format.
% 
%traceout logical value which controls printing of the algorithm
% 	convergence. If traceout=1, details are printed. Default value is 0.
% 
%iter_max maximum number of iterations. Default is 150.
%
%x_tol tolerance (default is 1e-8).
% 
%VALUE
% 
%a list containing the following components:
% 
%dp	a list containing the direct parameters beta, Omega, alpha.
% 	Here, beta is a matrix of regression coefficients with
% 	size(beta)=[size(X,1),size(y,2)), Omega is a covariance matrix of order
% 	size(y,2), alpha is a vector of shape parameters of length size(y,2).
% 
%se	a list containing the components beta, alpha, info. Here, beta
% 	and alpha are the standard errors for the corresponding point estimates;
% 	info is the observed information matrix for the working parameter, as
% 	explained below.
% 
%options messages from the optimisation routine; see the documentation
% 	of 'foptions' for explanation of its components.
% 
%DETAILS
% 
%The parameter freq is intended for use with grouped data, setting the
%values of y equal to the central values of the cells; in this case the
%resulting estimate is an approximation to the exact maximum likelihood
%estimate. If freq is not set, exact maximum likelihood estimation is
%performed.
% 
%The working parameter used in the maximization stage is
%[beta,alpha./omega], since a profile deviance (-2*log-likelihood) for
%this parameter is actually used; see Azzalini and Capitanio (1998) for
%details. The optimizer routine is called, supplying the gradient of the
%profile deviance. PP Although the function accepts a vector y as input,
%the use of sn_mle is recommended in the scalar case.
% 
% 
%BACKGROUND
% 
%The multivariate skew-normal distribution is discussed by Azzalini and
%Dalla Valle (1996); the (Omega,alpha) parametrization adopted here is
%the one of Azzalini and Capitanio (1998).
% 
%REFERENCES
% 
%Azzalini, A. and Dalla Valle, A. (1996). The multivariate skew-normal
%distribution. Biometrika 83, 715-726.
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%dmsn,sn_mle,msn_fit,foptions
% 
%EXAMPLES
% 
%# a simple case
%b = msn_mle(NaN,[lbm,bmi,ssf])
%#
%# a regressione case
%a = msn_mle([ones(length)lbm),1),lbm], bmi, NaN, NaN, NaN, NaN,1e-6)
%#
%# refine the previous outcome
%a1 = msn.mle([ones(length)lbm),1),lbm], bmi, NaN, a_dp, NaN, NaN,1e-9)

if nargin<7 x_tol=1e-8;
end;
if nargin<6 iter_max=150;
end;
if nargin<5 traceout=0;
end;
if nargin<4 start=NaN;
end;
if nargin<3 freq=NaN;
end;
if nargin<2 error('Required arguments are missing');
end;
if isnan(iter_max) iter_max=150;
end;
if isnan(traceout) traceout=0;
end;
if isnan(X) 
   X=ones(size(y,1),1);
end;
if isnan(freq) 
   freq=ones(1,size(y,1));
end;
k=size(y,2);
n=sum(freq);
m=size(X,2);
[Q,R]=qr(X);
coeff=R\(R'\(X'*y));
residuals=y-X*coeff;
if ~isstruct(start)
   beta=coeff;
   res=residuals;
   a=msn_moment_fit(res);
   Omega=a.Omega;
   omega=a.omega;
   alpha=a.alpha;
   if (~a.admissible) alpha=alpha/(1+max(abs(alpha)));
   end;
   beta(1,:)=beta(1,:)-omega.*a.delta.*sqrt(2/pi);
else
   beta=start.beta;
   Omega=start.Omega;
   alpha=start.alpha;
   omega=sqrt(diag(Omega))';
end;
al_om=alpha./omega;
if traceout
   disp('Initial parameters:');
   disp(beta);
   disp(al_om);
   disp(Omega);
   options(1)=1;
end;
param=[reshape(beta,1,m*k),al_om];
dev=msn_dev(param,X,y,freq);
options(2)=x_tol;
options(14)=iter_max*(m*k+k);
[opt,options,lambda,hess]=constr('msndeviance',param,options,...
   [repmat(-Inf,1,m*k+k)],...
   [repmat(Inf,1,m*k+k)],'msngrdnt',X,y,freq,traceout);
logL=-options(8)/2;
beta=reshape(opt(1:m*k),m,k);
al_om=opt(m*k+1:m*k+k);
xi=X*beta;
Omega=(y-xi)'*(repmat(freq',1,size(y,2)).*(y-xi))./n;
omega=sqrt(diag(Omega))';
alpha=al_om.*omega;
param=[omega,alpha];
info=num_deriv(opt,'msn_dev_grad',X,y,freq)/2;
se=sqrt(diag(inv(info)))';
se_beta=reshape(se(1:m*k),m,k);
se_alpha=se(m*k+1:m*k+k).*omega;
se=struct('beta',se_beta,'alpha',se_alpha,'info',info);
dp=struct('beta',beta,'Omega',Omega,'alpha',alpha);
mle=struct('dp',dp,'logL',logL,'se',se,'options',options);
%manca il match.call()
   
