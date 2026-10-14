function d=dmsn(x,xi,Omega,alpha)
%dmsn rmsn
%Multivariate skew-normal distribution
% 
%DESCRIPTION
% 
%Probability density function and random number generation for the
%multivariate skew-normal (MSN) distribution.
% 
%USAGE
% 
%dmsn(x, xi, Omega, alpha)
%rmsn(n, xi, Omega, alpha)
% 
%REQUIRED ARGUMENTS
% 
%x       either a vector of length k or a matrix with k columns, where k is
%length(alpha), giving the coordinates of the point(s) where the density
%must be avaluated.
% 
%Omega	a covariance matrix of dimension (k,k).
% 
%alpha	a numeric vector which regulates the shape of the density.
% 
%OPTIONAL ARGUMENTS
% 
%xi	a numeric vector of lenght k, or a matrix with k columns,
%representing the location parameter of the distribution. If xi is a
%matrix, its dimensions must agree with those of x (defaults is
%zeros(1,k)).
% 
%n	a numeric value which represents the number of random vectors to
%be drawn (default is 1).
% 
%VALUE
% 
%A vector of density values (dmsn), or a matrix of random points (rmsn).
% 
%DETAILS
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
% 
%EXAMPLES
% 
%x = linspace(-3,3,30)
%pdf = dmsn([x',zeros(30,1)], [0,0], eye(2), [2,3])
%#
%rnd = rmsn(50,[0,0], eye(2),[2,3])

%Density of Multivariate SN rv with parameters (xi,Omega,alpha)
%evaluated at x, which is either a k-vector or n x k matrix
if isnan(xi) xi=zeros(size(x,2),1);
end;
xi=reshape(xi,length(xi),1);
scale=sqrt(diag(Omega));
n=size(x,1);
k=size(x,2);
X=x'-repmat(xi,1,n);
z=X./repmat(scale,1,size(x,1));
Q=diag(X'*inv(Omega)*X); %diagonal of (x Omega^(-1) x^T)
Det=det(Omega);
pdf=2.*exp(-0.5.*Q).*normcdf(z'*reshape(alpha,length(alpha),1))./sqrt((2*pi)^k*Det);
d=pdf;
