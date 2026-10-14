function cond=msn_conditional(xi,Omega,alpha,fixed_comp,fixed_values)
%msn_conditional
%Cumulants and distribution of a skew-normal variate after conditioning
% 
%DESCRIPTION
% 
%Finds cumulants up to 3rd order of a multivariate skew-normal
%distribution conditionally on the values taken on by some of its
%components, and finds a multivariate skew-normal distribution with the
%same cumulants.
% 
%USAGE
% 
%msn_conditional(xi, Omega, alpha, fixed.comp, fixed.values)
% 
%REQUIRED ARGUMENTS
% 
%xi		a numeric vector of length k, say, giving the location
% 		parameter.
%Omega		a covariance matrix of dimension (k,k).
%alpha		a numeric vector of length k, which regulates the shape
% 		of the density.
%fixed_comp	a vector containing a subset of 1:k which selects the
% 		components whose values are to be fixed; it must be of
% 		length k-2.
%fixed_values	a numeric vector of values taken on by the components
% 		fixed_comp; it must be of the same length of fixed_comp.
% 
%VALUE
% 
%a list containing the following elements:
% 
%cumulants	a list containing mean vector, variance matrix, and
% 		indices of skewness of the conditional distribution.
%fit		a list containing the parameters of the fitted skew-normal
%  		distribution in the (xi,Omega ,alpha) parametrization, plus
% 		the vector delta.
% 
%DETAILS
% 
%See the reference below for details and background.
% 
%REFERENCES
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%plot_msn_cond, msn_marginal
% 
%EXAMPLES
% 
%Omega = eye(3)+0.5.*ones(3,3)
%a = msn_conditional(zeros(1,3), Omega, [1:3], 3, -0.75)

% Conditional multivariate SN (6/11/1997).
% Given a rv Y~SN_k(xi,Omega,alpha), this function computes 
% cumulants of conditional distribution, given that fixed_comp
% take on fixed_values:
% then it finds MSN with matching cumulants.
if nargin<5 error('missing required arguments');
end;
k=length(alpha);
h=length(fixed_comp);
if (any(size(Omega)~=[k,k])|(length(xi)~=k)|(h~=length(fixed_values)))
   error('dimensions of parameters do not match');
end;
fc=fixed_comp;
mfc=[];
for i=1:k if i~=fc(1:h) mfc=[mfc i]; end;end; %computes -fc
O=Omega;
O11=O(fc,fc);
O12=O(fc,mfc);
O21=O(mfc,fc);
O22=O(mfc,mfc);
o22=sqrt(diag(O22))'; %vettore riga
inv_O11=inv(O11);
xi1=xi(fc);
xi2=xi(mfc);
alpha1=alpha(fc)';
alpha2=alpha(mfc)';
O22_1=O22-O21*inv_O11*O12;
O22_b=imsqrt(O22)*O22_1*imsqrt(O22);
xi_c=xi2+(O21*inv_O11*(fixed_values-xi1)')';
a=sqrt(1.+(alpha2'*O22_b*alpha2)');
alpha_b=(alpha1+msqrt(O11)*inv_O11*O12*(alpha2./o22'))./a;
d2=(O22_b*alpha2)'./a;
x0=sum(alpha_b.*(fixed_values-xi1)'./sqrt(diag(O11)));
E_c=xi_c+zeta(1,x0).*o22.*d2;
var_c=O22_1+zeta(2,x0).*((o22.*d2)'*(o22.*d2));
gamma1=zeta(3,x0).*d2.^3./diag(O22_b+repmat(zeta(2,x0).*(d2').^2,1,size(O22_b,2)))'.^(1.5);
cum=struct('E_c',reshape(E_c,1,length(E_c)),'var_c',var_c,'gamma1',gamma1);
%cumulants are computed; now choose SN distn to fit them
a=sign(gamma1).*(2.*abs(gamma1)./(4-pi)).^0.33333;
E_z=a./sqrt(1+a.^2);
delta=E_z.*sqrt(pi/2);
omega=sqrt(diag(var_c)'./(1-E_z.^2))';
O_new=var_c+(omega.*E_z')*(omega.*E_z')';
xi_new=E_c-omega'.*E_z;
B=diag(1./omega);
m=(inv(B*O_new*B)*delta')';
a=m./sqrt(1-sum(delta.*m));
%cum2=msn.cumulants(xi_new,O_new,a)
cond=struct('cumulants',cum,'fit',struct('xi',xi_new,'Omega',O_new,...
   'alpha',a,'delta',delta));

function ms=msqrt(A)
ms=diag(sqrt(diag(A)));
function ims=imsqrt(A)
ims=diag(1./sqrt(diag(A)));







