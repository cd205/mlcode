function [Cpdf] = FUN_2DCopula_Trun_Norm(x,y,CUT,SIGMA,A,B,R,p)
% Join a truncated pdf to a normal pdf using a copula
% note that the scraped components are removed from the first (truncated
% distribution).  This is achieve by multiplying the first (truncated 
% distribtuion) by I.
% Christopher Dodd - cd205@soton.ac.uk - 26/06/2013
% clear all
% close all
% clc
% CUT = [6 6]
% sig11 = 1;
% sig22 = 1;
% SIGMA = [sig11^2 0; 0 sig22^2]
% A = [3 3];
% B = [7 7];
% R = [0 10];
% x = 7
% y=x;
% p  = [1 0.5;0.5 1]

sig11 = sqrt(SIGMA(1,1));
sig22 = sqrt(SIGMA(2,2));
size_x = size(x); % record the size of the input vector 
                  % (size(y) will = size(x)).  Output will need to be the
                  % same size as the input vector.

xv = x(:); % put input into a column vector, this is required for 
yv = y(:); % couplapdf and copulacdf.

% [pdf1 cdf1]= Fun_TruncatedNormalDist(xv,CUT(1),sig11,A(1),B(1));
% I = not(abs(sign(sign(A(1)-xv) + sign(B(1)-xv))));
pdf1= Fun_TruncatedNormalDist_pdf(xv,CUT(1),sig11,A(1),B(1),R(2),0);
cdf1= Fun_TruncatedNormalDist_cdf(xv,CUT(1),sig11,A(1),B(1),R(2),0);
% pdf1 = I.*pdf1;
% cdf1 = I.*cdf1;
pdf2 = normpdf(yv,CUT(2),sig22);
cdf2 = normcdf(yv,CUT(2),sig22);

Cpdf = copulapdf('Gaussian',[cdf1,cdf2],p).*pdf1.*pdf2;
Ccdf = copulacdf('Gaussian',[cdf1,cdf2],p);
Cpdf = reshape(Cpdf,size_x(1),size_x(2));
Ccdf = reshape(Ccdf,size_x(1),size_x(2));

