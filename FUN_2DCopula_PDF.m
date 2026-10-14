function C = FUN_2DCopula_PDF(x,y,CUT,SIGMA,A,B)

sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));

[pdf1 cdf1]= Fun_TruncatedNormalDist(x,CUT(1),sig11,A(1),B(1));
[pdf2 cdf2]= Fun_TruncatedNormalDist(y,CUT(2),sig22,A(2),B(2));

C = copulapdf('Gaussian',[cdf1,cdf2],SIGMA).*pdf1.*pdf2;
