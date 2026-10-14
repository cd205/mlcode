
function  F = Fun_ConvDiff_NormTrun(MU,sig,v)
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
Int_F = trapz(v,F)