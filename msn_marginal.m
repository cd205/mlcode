function marg=msn_marginal(xi,Omega,alpha,comp)
%msn_marginal
%Marginal compontents of a multivariate skew-normal distribution
% 
%DESCRIPTION
% 
%Computes the marginal distribution of a subset of components of a
%multivariate skew-normal distribution.
% 
%USAGE
% 
%msn_marginal(xi, Omega, alpha, comp)
% 
%REQUIRED ARGUMENTS
% 
%xi	a numeric vector of length k, say, giving the location parameter.
% 
%Omega	a covariance matrix of dimension (k,k).
% 
%alpha   a numeric vector of length k, which regulates the shape of the density.
% 
%comp	a vector containing a subset of 1:k which selects the components
% 	whose values are to be fixed. A permutation of 1:k is allowed, and the
% 	components of comp' do not need to be sorted.
% 
%VALUE
% 
%a list containing the xi, Omega, alpha parameters for the marginal
%distribution.
% 
%DETAILS
% 
%See Azzalini and Capitanio (1998) for details.
% 
%REFERENCES
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%dmsn, msn_conditional
% 
%EXAMPLES
% 
%xi = [10,0,-30]
%Omega = 5*eye(3)+ones(3,3)
%alpha = [1,-3,5]
%marg31 = msn_marginal(xi,Omega,alpha,[3,1])

% calcola parametri della marginale associata a comp
% di una SN_k(xi,Omega,alpha).
if nargin<4 error('missing required arguments');
end;
xi=reshape(xi,1,length(xi));
comp=fix(comp);
k=length(alpha);
alpha=reshape(alpha,1,k);
if (length(comp)<k)
   if any((comp>k)|(comp<1)) error('comp makes no sense');
   end;
   scale=sqrt(diag(Omega))';
   O=diag(1./scale)*Omega*diag(1./scale);;
   mcomp=[];
   for i=1:k if i~=comp(1:length(comp)) mcomp=[mcomp i]; end;end; %computes -comp
   O11=O(comp,comp);
   O12=O(comp,mcomp);
   O21=O(mcomp,comp);
   O22=O(mcomp,mcomp);
   alpha1=alpha(comp)';
   alpha2=alpha(mcomp)';
   O22_1=O22-O21*inv(O11)*O12;
   a_sum=(alpha2'*O22_1*alpha2)';
   a_new=(alpha1+inv(O11)*O12*alpha2)'./sqrt(1+a_sum);
   O_new=diag(scale(comp))*O11*diag(scale(comp));
   result=struct('xi',xi(comp),'Omega',O_new,'alpha',a_new);
else
   if (length(comp)>k) error('comp makes no sense');
   end;
   if any(sort(comp)~=[1:k]) error('comp makes no sense');
   end;
   result=struct('xi',xi(comp),'Omega',Omega(comp,comp),...
      'alpha',alpha(comp));
end;
marg=result;
