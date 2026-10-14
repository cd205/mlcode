
function  F = Fun_Conv_NormTrun(MU,sig,a,b,v)
% http://www.columbia.edu/~st2511/notes/Convolution%20of%20truncated%20normal%20and%20normal.pdf
% For a convolution difference e.g. Z = X - Y
% MU_1 = is the negative one
% MU_2 = is the positive one
% Convulation Difference of Normal and Truncated distribution 
c = (MU(2)-b)/sig(2);
d = (MU(2)-a)/sig(2);

GammaP = 1/(sqrt(2*pi*sig(2)^2)*(normcdf(d,0,1) - normcdf(c,0,1)))*(1/sqrt(2*pi*sig(1)^2));
dp = (sqrt(2).*(sig(2).^2.*b+sig(2).^2.*MU(1)-v.*sig(2).^2+b.*sig(1).^2-sig(1).^2.*MU(2)))...
    ./(2.*sig(1).*sig(2).*sqrt(sig(1).^2+sig(2).^2));
cp = (sqrt(2).*(sig(2).^2.*a+sig(2).^2.*MU(1)-v.*sig(2).^2+a.*sig(1).^2-sig(1).^2.*MU(2)))...
    ./(2*sig(1).*sig(2).*sqrt(sig(1).^2+sig(2).^2));
F = GammaP.*(((sqrt(2*pi)*exp(-(-MU(1)+v-MU(2)).^2./(2.*(sig(1).^2+sig(2).^2)))).*((erf(dp)-erf(cp)).*sig(1).*sig(2)))...
    ./(2.*sqrt(sig(1)^2+sig(2)^2)));
%Int_F = trapz(v,F)