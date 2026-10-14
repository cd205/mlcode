function mle=sn_mle(X,y,cp,plotit,traceout,iter_max,abs_tol)
%sn_mle
%Maximum likelihood estimation for skew-normal models
% 
%DESCRIPTION
% 
%Fits a skew-normal (SN) distribution to data, or fits a linear
%regression model with skew-normal errors, using maximum likelihood
%estimation.
% 
%USAGE
% 
%sn_mle(X, y, cp, plotit, traceout, iter_max, abs_tol)
% 
%REQUIRED ARGUMENTS
% 
%y	a vector contaning the observed variable. This is the response
% 	variable in case of linear regression. Missing values (NaN) are not
% 	allowed.
% 
%OPTIONAL ARGUMENTS
% 
%X 	a matrix of explanatory variables. If X is missing, then a
% 	one-column matrix of all 1's is created. If X is supplied, and an
% 	intercept term is required, then it must include a column of 1's.
% 	Missing values (NaN) are not allowed.
% 
%cp	a vector of initial values for the centred parameters, with
% 	length(cp)=size(X,2)+2
% 
%plotit	logical value, If plotit=1 (default)  a plot of the nonparametric 
%	estimate of variable y (or the residuals, in the case of regression),
%	and the parametric fit is superimposed. See below for details.
% 
%traceout logical value which controls printing of the algorithm
% 	convergence. If traceout=1, details are printed. Default value is 0.
% 
%iter_max this parameter is passed to the optimizer routine and
%	  represent the maximum number of iterations (default is 100);
%	  see the documentation of 'foptions' for its usage.
% 
%abs_tol  this parameter is passed to the optimizer routine and
%	  represent the absolute tolerance (default is 1e-5);
%	  see the documentation of 'foptions' for its usage.
%VALUE
% 
%a list containing the following components:
% 
%cp	a vector of length size(X,2)+2 with the centred parameters
% 
%logL	the log-likelihood at convergence
% 
%se	a vector of standard errors for the cp component
% 
%info	the observed information matrix for the cp component
% 
%options the list returned by the optimizer routine; see the documentation
% 	of 'foptions' for explanation of its components.
% 
%SIDE EFFECTS
% 
%If plotit=1, a plot is produced, as
%described above; see also DETAILS below.
% 
%DETAILS
% 
%The optimizer routine 'constr' is used, supplying gradient.
%Convergence is generally fast and reliable, but inspection of the
%returned message from 'options' is always appropriate. In suspect cases,
%re-run the function changing the starting cp vector.
% 
%If plotting operates, an histogram is plotted.
% 
%BACKGROUND
% 
%Background information on the SN distribution is given by Azzalini
%(1985). See  Azzalini and Capitanio (1998) for a more detailed
%discussion of the centred parametrization.
% 
%REFERENCES
% 
%Azzalini, A. (1985). A class of distributions which includes the normal
%ones. Scand. J. Statist. 12, 171-178.
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%dsn, sn_mle, msn_mle, constr, foptions
% 
%EXAMPLES
% 
%a = sn_mle(NaN,bmi)
%#
%a = sn_mle([ones(length(lbm),1),lbm,lbm^2],bmi)
if nargin<7 abs_tol=1e-5;
end;
if nargin<6 iter_max=100;
end;
if nargin<5 traceout=0;
end;
if nargin<4 plotit=1;
end;
if nargin<3 cp=NaN;
end;
if nargin<2 error('Required arguments are missing');
end;
if isnan(iter_max) iter_max=100;
end;
if isnan(traceout) traceout=0;
end;
if isnan(plotit) plotit=1;
end;
n=length(y);
y=reshape(y,n,1); %vettore colnna
miss=0;
if isnan(X) 
   X=ones(n,1);
   miss=1;
end;
m=size(X,2);
if isnan(cp) 
   [Q,R]=qr(X);
   coeff=R\(R'\(X'*y));
   residuals=y-X*coeff;
   s=sqrt(sum(residuals.^2)/n);
   gamma1=sum(residuals.^3)/(n*s^3);
   if abs(gamma1)>0.99527
      gamma1=sign(gamma1)*0.95;
   end;
   cp=[coeff',s,gamma1];
else
   if length(cp)~=m+2
      error('sixe(X,2)+2~=length(cp)');
   end;
end;
if traceout
   options(1)=1; %da' un resoconto del procedimento di conv a video
end;
options(2)=1e-7; %tol su cp
options(3)=abs_tol;
options(14)=(m+2)*iter_max;
[opt,options,lambda,hess]=constr('deviance',cp,options,...
   [repmat(-Inf,1,m),1e-10,-0.99527],...
   [repmat(Inf,1,m),Inf,0.99527],'grdnt',X,y,traceout);
cp=opt;
logL=-options(8)/2;
info=sn_dev_gh(cp,X,y);
info=info.info;
se=sqrt(diag(inv(info)))'; %vettore riga
if plotit
   dp0=cp_to_dp(cp);
   if miss
      y0=y;
      xlab=inputname(2); %il nome di y
   else
      y0=y-X*dp0(1:m)';
      dp0=[0,dp0(m+1),dp0(m+2)];
      xlab='residuals';
   end;
   [a,b]=hist(y0,n^(1/3)+sqrt(n)+1);
   a=a/sum(a)/abs(b(1)-b(2)); %prob=T
   bar(b,a,1); 
   xlabel(xlab);
   title(inputname(2));
   x=[min(y0),min(y0)+(1:99)*(max(y0)-min(y0))/99];
   hold on;
   if n<101
      plot(y0,zeros(n,1),'ko ');
   end;
   plot(x,dsn(x,dp0(1),dp0(2),dp0(3)),'r -');
   hold off;
end;
mle=struct('cp',cp,'logL',logL,'se',se,'info',info,'options',options);
%manca il match.call()
   
