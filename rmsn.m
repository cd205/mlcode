function r=rmsn(n,xi,Omega,alpha)
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

%generates SN_k(xi,Omega,alpha) variates using transformation method
if nargin<4 error('missing required arguments');
end;
if isnan(xi) xi=zeros(size(x,2),1);
end;
if isnan(n) n=1;
end;
k=size(Omega,2);
Z=msn_quantities(xi,Omega,alpha);
y=normrnd(0,1,n,k)*chol(Z.Psi);
%each row of y is N_k(0,Psi)
abs_y0=abs(normrnd(0,1,n,1));
abs_y0=repmat(abs_y0,1,k);
delta=Z.delta;
z=repmat(delta',1,n).*abs_y0'+repmat(sqrt(1-delta.^2)',1,n).*y';
y=(repmat(xi',1,n)+repmat((Z.omega)',1,n).*z)';
r=y;
