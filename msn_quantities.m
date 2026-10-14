function quant=msn_quantities(xi,Omega,alpha)
%msn_quantities
%Quantities related to the multivariate skew-normal distribution.
% 
%DESCRIPTION
% 
%Computes mean vector, variance matrix and other relevant quantities of a
%given multivariate skew-normal distribution.
% 
%USAGE
% 
%msn_quantities(xi, Omega, alpha)
% 
%REQUIRED ARGUMENTS
% 
%xi	numeric vector giving the location parameter, of length k, say.
% 	Missing values are not allowed.
% 
%Omega	a covariance matrix of size k by k. Missing values are not
% 	allowed.
% 
%alpha	numeric vector of shape parameter of length k. Missing values
% 	are not allowed.
% 
%VALUE
% 
%a list containing the following components
% 
%xi, Omega, alpha	as given on input
% 
%omega			vector of scale parameters
% 
%mean	numeric vector representing the mean value of the distribution
% 
%variance	variance matrix of the distribution
% 
%Omega_con, Omega_conc	correlation matrix and concentration matrix
% 			associated to Omega
% 
%Psi	covariance matrix of the equivalent (lambda,Psi) parametrization
% 
%lambda, delta	shape parameters of the marginal distributions, in two
% 		equivalent forms
% 
%gamma1	numeric vector with marginal indices of skewness
% 
%DETAILS
% 
%The meaning of the parameters is explained in the references below,
%especially Azzalini and Capitanio (1998).
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
%dmsn
% 
%EXAMPLES
% 
%a = msn_quantities([0,0], eye(2), [2,3])

%computes variuos quantities related to SN_k(xi,Omega, alpha)
if nargin<3 error('missing required arguments');
end;
k=length(alpha);
alpha=reshape(alpha,1,k);
if ((length(xi)~=k)|(any(size(Omega)~=[k k])))
   error('dimensions of arguments do not match');
end;
omega=sqrt(diag(Omega));
O_cor= diag(1./omega)*Omega*diag(1./omega);
tmp=sqrt(1+alpha*O_cor*alpha');
delta=O_cor*alpha'./tmp;
lambda=delta./sqrt(1-delta.^2);
D=diag(sqrt(1+lambda.^2));
Psi=D*(O_cor-(delta*delta'))*D;
Psi=(Psi+Psi')./2;
O_inv=inv(Omega);
oi=sqrt(diag(O_inv));
O_conc=diag(1./oi)*(-O_inv)*diag(1./oi);
O_conc=O_conc-diag(diag(O_conc))+eye(k);%1 on the dagonal of O_conc
muZ=delta.*sqrt(2/pi);
muY=xi'+omega.*muZ;
Sigma=diag(omega)*(O_cor-muZ*muZ')*diag(omega);
Sigma=(Sigma+Sigma')./2;
cv=muZ./sqrt(1-muZ.^2);
gamma1=0.5*(4-pi)*cv.^3;
quant=struct('xi',xi,'Omega',Omega,'alpha',alpha,'omega',omega',...
   'mean',muY','variance',Sigma,'Omega_cor',O_cor,'Omega_conc',...
   O_conc,'Psi',Psi,'lambda',lambda','delta',delta','skewness',gamma1');






