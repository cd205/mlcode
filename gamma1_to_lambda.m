function g2l=gamma1_to_lambda(gamma1)
%gamma1_to_lambda
%Converts skewness to shape parameter of skew-normal distribution
% 
%DESCRIPTION
% 
%For a given value of the index of skewness (standardized third
%cumulant), the function finds the corresponding shape parameter of a
%skew-normal distribution.
% 
%USAGE
% 
%gamma1_to_lambda(gamma1)
% 
%REQUIRED ARGUMENTS
% 
%gamma1	a numeric vector of indices of skewness.
% 
%VALUE
% 
%a numeric vector of the corresponding shape parameters.
% 
%DETAILS
% 
%Feasible values for input must have
%abs(gamma1)<0.5*(4-pi)*(2/(pi-2))^1.5, which is about 0.99527. If some
%values of gamma1 are not in the feasible region, a warning message is
%issued, and NaN are returned.
% 
%See the reference below for the expression of the index of skewnnes of a
%skew-normal distribution.
% 
%REFERENCES
% 
%Azzalini, A. (1985). A class of distributions which includes the normal
%ones. Scand. J. Statist. 12, 171-178.
% 
%SEE ALSO
% 
%dsn
% 
%EXAMPLES
% 

max_gamma1=0.5*(4-pi)*(2/(pi-2))^1.5;
na=(abs(gamma1)>max_gamma1);
if any(na) warning('NaN generated');
end;
gamma1(na)=NaN;
a=sign(gamma1).*(2*abs(gamma1)/(4-pi)).^0.33333;
delta=sqrt(pi/2)*a./sqrt(1+a.^2);
lambda=delta./sqrt(1-delta.^2);
g2l=reshape(lambda,1,length(lambda)); %vettore riga
