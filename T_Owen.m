function to=T_Owen(h,a,jmax,cut_point)
%T_Owen
%Owen's function
% 
%DESCRIPTION
% 
%Evaluates funtion T(h,a) studied by D.B.Owen
% 
%USAGE
% 
%T_Owen(h, a, jmax, cut_point)
% 
%REQUIRED ARGUMENTS
% 
%h	a numerical vector. Missing values (NaN) and Inf are allowed.
% 
%a	a numerical scalar. Inf is allowed.
% 
%OPTIONAL ARGUMENTS
% 
%jmax	an integer scalar value which regulates the accuracy of the
% 	result (default is 50). See DETAILS below for explanation.
% 
%cut_point	a scalar value which regulates the behaviour of the
% 		algorithm (default is 6). See DETAILS below for explanation.
% 
%VALUE
% 
%a numerical vector
% 
%DETAILS
% 
%If a>1 and 0<h<=cut_point, a series expansion is used, truncated after
%jmax terms. If a>1 and h>cut_point, an asymptotic approximation is used.
%In the other cases, various reflection properties of the function are
%exploited. See the reference below for more information.
% 
%BACKROUND
% 
%The function T(h,a) is useful for the computation of the bivariate
%normal distribution function and related quantities. See the reference
%below for more information.
% 
%REFERENCES
% 
%Owen, D. B. (1956). Tables for computing bivariate normal probabilities.
%Ann. Math. Statist. 27, 1075-1090.
% 
%SEE ALSO
% 
%pnorm2, psn
% 
%EXAMPLES
% 
%owen = T_Owen(1:10, 2)

if nargin<4 cut_point=6;
end;
if nargin<3 jmax=50;
end;
if nargin<2 error('Two required arguments are missing');
end;
if isnan(jmax) jmax=50;
end;
if isnan(cut_point) cut_point=6;
end;
if (length(a)>1) error('a must be a vector of length 1');
end;
aa=abs(a);
ah=abs(h);
if (aa==Inf) 
   to=0.5.*normcdf(-ah);
   return;
end;
if (aa==0) 
   to=zeros(1,length(h));
   return;
end;
na=isnan(h);
inf= (ah==Inf);
ah(na|inf)=0;
if (aa<=1)
   owen=T_int(ah,aa,jmax,cut_point);
else
   owen=0.5.*normcdf(ah)+normcdf(aa.*ah).*(0.5-normcdf(ah))- ...
      T_int(aa.*ah,(1/aa),jmax,cut_point);
end;
owen(na)=NaN;
owen(inf)=0;
to=owen*sign(a);

function ti=T_int(h,a,jmax,cut_point)
i=0:jmax;
low=(h<=cut_point);
hL=h(low);
hH=h(~low);
L=length(hL);
seriesL=zeros(1,L);
seriesH=zeros(1,length(h)-L);
if (L>0)
   [Y,X]=meshgrid(i,hL);
   b=fui(X,Y);
   tcumb=cumsum(b,2);
   for j=1:size(tcumb,2)
      b1(:,j)=tcumb(:,j).*(exp(-0.5.*hL.^2))';
   end;
   matr=ones(jmax+1,L)-(b1');
   jk=repmat([1 -1],1,jmax);
   jk=jk(1:(jmax+1))./(2.*i+1);
   for j=1:size(matr,2) 
      matr(:,j)=matr(:,j).*jk';
   end;
   matr=(matr')*(a.^(2.*i+1))';
   seriesL=(atan(a)-matr')./(2.*pi);
end;
if (length(hH)>0)
   seriesH=atan(a).*exp(-0.5.*(hH.^2).*a./atan(a)).* ...
      (1+0.00868.*(hH.^4).*a.^4)./(2.*pi);
end;
series=[seriesL seriesH];
app=1:length(h);
id=[app(low) app(~low)];
series(id)=series; %re-sets in original order
ti=series;


function ff=fui(h,i)
ff=(h.^(2.*i))./((2.^i).*gamma(i+1));