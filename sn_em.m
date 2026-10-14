function fresult=sn_em(X,y,fixed,p_eps,l_eps,traceout,data)
%sn_em
%Fitting Skew-normal variables using the EM algorithm
% 
%DESCRIPTION
% 
%Fits a skew-normal (SN) distribution to data, or fits a linear
%regression model with skew-normal errors, using the EM algorithm to
%locate the MLE estimate. The estimation procedure can be global or it
%can fix some components of the parameters vector.
% 
%USAGE
% 
%sn_em(X, y, fixed, p_eps, l_eps, traceout, data)
% 
%REQUIRED ARGUMENTS
% 
%y	a vector contaning the observed variable. This is the response
% 	variable in case of linear regression.
% 
%OPTIONAL ARGUMENTS
% 
%X	a matrix of explanatory variables. If X is missing, then a
% 	one-column matrix of all 1's is created. If X is supplied, and an
% 	intercept term is required, then it must include a column of 1's.
% 
%fixed	a vector of length 3, indicating which components of the
% 	parameter vector must be regarded as fixed. If fixed=[NaN,NaN,NaN], which
% 	is the default setting, a global maximization is performed. If the 3rd
% 	component is given a value, then maximization is performed keeping that
% 	value fixed for the shape parameter. If the 3rd and 2nd parameters are
% 	fixed, then the scale and the shape parameter are kept fixed. No other
% 	patterns of the fixed values are allowed.
% 
%p_eps	numerical value which regulates the parameter convergence
% 	tolerance (default is 0.0001).
% 
%l_eps	numerical value which regulates the log-likelihood convergence
% 	tolerance (default is 0.01).
% 
%traceout logical value which controls printing of the algorithm
% 	convergence. If traceout=1, details are printed. Default value is 0.
% 
%data	logical value. If data=1, the returned list includes the
% 	original data. Default value is data=0.
% 
%VALUE
% 
%a list with the following components:
% 
%dp	a vector of the direct parameters, as explained in the
% 	references below.
% 
%cp	a vector of the centred parameters, as explained in the
% 	references below.
% 
%logL	the log-likelihood at convergence.
% 
%data	optionally (if data=1), a list containing X and y, as supplied
% 	on input, and a vector of residuals, which should have an approximate SN
% 	distribution with location=0 and scale=1, in the direct parametrization.
% 
%DETAILS
% 
%The function works using the direct parametrization; on convergence, the
%output is then given in both parametrizations.
% 
%This function is based on the EM algorithm; it is generally quite slow,
%but it appears to be very robust. See sn_mle for an alternative method,
%which also returns standard errors.
% 
%BACKGROUND
% 
%Background information on the SN distribution is given by Azzalini
%(1985). See  Azzalini and Capitanio (1998) for a more detailed
%discussion of the direct and centred parametrizations.
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
%dsn, sn_mle, cp_to_dp
% 
%EXAMPLES
% 
%a = sn_em(NaN,bmi)
%#
%a = sn_em([ones(length(lbm),1),lbm,lbm.^2],bmi)
%#
%fit = sn_em(NaN,y, [NaN, 2, 3], NaN, 0.001)

%1/10/98 (elaborando dal em.lm.sn del 2/12/97)
%EM per caso con uno/due/tre parametri ignoti, parametrizzando in
%modo "diretta" con (xi,omega,lambda); internamente usa peraltro
%"delta". Le componenti ignote sono i termini NaN di fixed, ma per
%semplicità assumiamo che un NaN implica che le componenti alla sua 
%sx sono NaN (e quindi il primo elemento di fixed è sempre NaN).
if nargin<7 data=0;
end;
if nargin<6 traceout=0;
end;
if nargin<5 l_eps=1e-2;
end;
if nargin<4 p_eps=1e-4;
end;
if nargin<3 fixed=NaN;
end;
if nargin<2 error('Required arguments are missing');
end;
if isnan(p_eps) p_eps=1e-4;
end;
if isnan(l_eps) l_eps=1e-2;
end;
if isnan(traceout) traceout=0;
end;
if isnan(data) data=0;
end;
n=length(y);
y=reshape(y,n,1); %vettore colonna
if (~(X~=NaN)) X=ones(n,1);
end;
nc=size(X,2);
if (~(fixed~=NaN)) fixed=repmat(NaN,1,3);
end;
if all(~isnan(fixed)) error('all parameters are fixed');
end;
if isnan(fixed(3))
   iter=1-log10(l_eps);
else
   iter=1;
end;
[Q,R]=qr(X);        %analogo di qrX=qr(X);
beta=R\(R'\(X'*y)); %analogo di qr.coef(qrX,y)
xi=X*beta;          %analogo di qr.fitted(qrX,y)
m=xi;
omega=fixed(2);
lambda=fixed(3);
delta=lambda./sqrt(1+lambda.^2);
s=sqrt(sum((y-xi).^2/n));
if isnan(fixed(3))
   gamma1=sum((y-m).^3)/(n*s^3);
   a=sign(gamma1).*(2*abs(gamma1)/(4-pi))^0.33333;
   delta=sqrt(pi/2)*a./sqrt(1+a^2);
   if abs(delta)>=1
      delta=sign(delta)/(1+1/n);
   end;
   lambda=delta./sqrt(1-delta.^2);
end;
mean_Z=sqrt(2/pi)*delta;
sd_Z=sqrt(1-mean_Z.^2);
if isnan(fixed(2))
   omega=s./sd_Z;
end;
if isnan(fixed(1))
   xi=m-s.*mean_Z./sd_Z;
end;
old_par=[beta',omega,lambda]; %beta e' un vettore colonna
diverge=1;
incr_logL=Inf;
logL=-Inf;
while (diverge>p_eps | incr_logL>l_eps),
   %E-step
   v=(y-xi)./omega;
   p=zeta(1,lambda.*v);
   u1=omega*(delta.*v+p.*sqrt(1-delta.^2));
   u2=omega.^2.*((delta.*v).^2+(1-delta.^2)+p.*v.*delta.*sqrt(1-delta.^2));
   %M-step
   for i=1:iter,
      beta=R\(R'\(X'*(y-delta*u1)));
      xi=X*beta;
      d=y-xi;
      Qsc=sum(d.^2-2*delta.*d.*u1+u2); %Qsc=scalare, per distinguerlo da Q della QR
      if isnan(fixed(2))
         omega=sqrt(Qsc/(2*n*(1-delta.^2)));
      end;
      r=2*sum(d.*u1)/Qsc;
      if isnan(fixed(3))
         delta=(sqrt((2*r)^2+1)-1)/(2*r);
      end;
   end;
   %convergence?
   lambda=delta./sqrt(1-delta.^2);
   param=[beta',omega,lambda];
   %restano da definire i nomi con 'struct'
   diverge=sum(abs(param-old_par)./(1+abs(old_par)))/(nc+2);
   old_par=param;
   a=sum(log(dsn(y,xi,omega,lambda)));
   incr_logL=a-logL;
   logL=a;
   if traceout      %da rifare quando param sara' 'struct'
      disp('parameters:')
      disp(param)
      disp('log-likelihood:')
      disp(logL)
   end;
end;
cp=dp_to_cp(param);
result=struct('dp',param,'cp',cp,'logL',logL);
if data
   result.data=struct('X',X,'y',y,'residuals',d/omega);
end;
fresult=result;
