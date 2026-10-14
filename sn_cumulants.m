function cum=sn_cumulants(shape,n)
%sn_cumulants
%cumulants of the skew-normal distribution
% 
%DESCRIPTION
% 
%cumulants of the skew-normal distribution
% 
%USAGE
% 
%sn_cumulants(shape, n)
% 
%ARGUMENTS
% 
%shape	a vector of shape parameter (default is 0).
% 
%n	a scalar integer (default is 4).
% 
%VALUE
% 
%the cumulants up to order n of the skew-normal distribution with
%location=0, scale=1 and shape as selected
% 
%DETAILS
% 
%The moment generating function (hence the cumulant generating function)
%of the distribution is given in the refence below. The computations
%method used here is unproved analytically but it is seen to behave
%correctly up to the order which was checked (n=8).
% 
%REFERENCES
% 
%Azzalini, A. (1985). A class of distributions which includes the normal
%ones. Scand. J. Statist. 12, 171-178.
% 
%SEE ALSO
% 
%dsn,zeta
% 
%EXAMPLES
% 
%cum = sn_cumulants([0,1,2,5,10],4)

if nargin<2 n=4;
end;
if nargin<1 shape=0;
end;
if isnan(shape) shape=0;
end;
delta=shape./sqrt(1+shape.^2);
kv=cumulants_half_norm(n);
if length(kv)>n 
   kv=kv(1:(end-1));
end;
kv(2)=kv(2)-1;
[app2,app1]=meshgrid(1:n,delta);
kappa=app1.^app2.*repmat(kv,length(shape),1);
%for i=1:n
%   app(:,i)=(delta').^i;
%end;
%kappa=app.*repmat(kv,length(shape),1);
kappa(:,2)=kappa(:,2)+1;
cum=kappa;

function cum2=cumulants_half_norm(n)
if nargin<1
   n=4;
end;
n=max(n,2);
n=fix(2*ceil(n/2));
half_n=fix(n/2);
m=0:(half_n-1);
a=sqrt(2/pi)./(gamma(m+1).*(2.^m).*(2.*m+1));
signs=ones(1,half_n);
signs(2:2:end)=-1;
%a=reshape([signs.*a; zeros(1,half_n)],1,2*length(a));
a=[signs.*a; zeros(1,half_n)]; %per MATLAB una matrice e' anche 
                               %un vettore, letta per colonna
coeff=repmat(a(1),1,n);
for k=2:n
   ind=1:(k-1);
   coeff(k)=a(k)-sum(ind.*coeff(ind).*a(fliplr(ind)))./k;
end;
kappa=coeff.*gamma((1:n)+1);
kappa(2)=1+kappa(2);
cum2=kappa;
