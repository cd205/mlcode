
function  F = Fun_Conv_NormTrun_neg(MU,sig,a,b,v,flag)
% For a convolution difference e.g. Z = X - Y
% Convulation Difference of Normal and Truncated distribution 
% flag determine which set of equations to use

% INPUTS: MU    - is a vector containing the means of the normal 
%                 distribution and trucated distribution.
%         sig   - is a vector containing the standard deviations of the 
%                 normal distribution and trucated distribution.    
%         a & b - are the lower and upper specification limit respectively 
%         v     - is the function argument f(v), i.e. for a value of v
%                 return f(v).
%         flag  - is 1 where mu_1 > mu_2 adn zerro otherwise, this
%                 determines the equation set to use.

% use these equations where mu_1 < mu_2
switch flag
case 0
c = (MU(2)-b)/sig(2);
d = (MU(2)-a)/sig(2);

GammaP = 1/(sqrt(2*pi*sig(2)^2)*(normcdf(d,0,1) - normcdf(c,0,1)))*(1/sqrt(2*pi*sig(1)^2));
dp = (sqrt(2)*(sig(1)^2*b + b*sig(2)^2 - sig(1)^2*MU(2) - sig(2)^2.*v - sig(2)^2*MU(1)))...
    ./(2*sig(1)*sig(2)*sqrt(sig(1)^2+sig(2)^2));
cp = (sqrt(2)*(sig(1)^2*a + a*sig(2)^2 - sig(1)^2*MU(2) - sig(2)^2.*v - sig(2)^2*MU(1)))...
    ./(2*sig(1)*sig(2)*sqrt(sig(1)^2+sig(2)^2));
F = GammaP.*(((sqrt(2*pi)*exp(-(MU(1)-MU(2)+v).^2./(2.*(sig(1)^2+sig(2)^2)))).*((erf(dp)-erf(cp)).*sig(1).*sig(2)))...
    ./(2.*sqrt(sig(1)^2+sig(2)^2)));

% use these equations where mu_1 > mu_2
case 1
c = (MU(2)-b)/sig(2);
d = (MU(2)-a)/sig(2);

GammaP = 1/(sqrt(2*pi*sig(2)^2)*(normcdf(d,0,1) - normcdf(c,0,1)))*(1/sqrt(2*pi*sig(1)^2));
cp = (sqrt(2)*(sig(1)^2*b + b*sig(2)^2 - sig(1)^2*MU(2) + sig(2)^2.*v - sig(2)^2*MU(1)))...
    ./(2*sig(1)*sig(2)*sqrt(sig(1)^2+sig(2)^2));
dp = (sqrt(2)*(sig(1)^2*a + a*sig(2)^2 - sig(1)^2*MU(2) + sig(2)^2.*v - sig(2)^2*MU(1)))...
    ./(2*sig(1)*sig(2)*sqrt(sig(1)^2+sig(2)^2));
F = GammaP.*(((sqrt(2*pi)*exp(-(-MU(1)+MU(2)+v).^2./(2.*(sig(1)^2+sig(2)^2)))).*((-erf(dp)+erf(cp)).*sig(1).*sig(2)))...
    ./(2.*sqrt(sig(1)^2+sig(2)^2)));
end