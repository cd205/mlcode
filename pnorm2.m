function p2=pnorm2(x,y,rho)
%pnorm2
%Bivariate normal integral
% 
%DESCRIPTION
% 
%Computes the cumulative distribution function of a bivariate normal
%distribution with standardized marginals.
% 
%USAGE
% 
%pnorm2(x, y, rho)
% 
%REQUIRED ARGUMENTS
% 
%x	a numerical value representing the first coordinate
% 
%y	a numerical value representing the second coordinate
% 
%rho	a numerical value representing the correlation; it must be
% 	between -1 and 1.
% 
%VALUE
% 
%a numerical value with the required probability
% 
%DETAILS
% 
%The input parameters must be all scalars.
% 
%This function is based on function T_Owen.
% 
%SEE ALSO
% 
%T_Owen
% 
%EXAMPLES
% 
%p = pnorm2(1.2, 0.5, 0.67)

if nargin<3 error('3 arguments are required');
end;
if (abs(rho)==1) warning off;
end;
x=reshape(x,1,size(x,1)*size(x,2));
y=reshape(y,1,size(y,1)*size(y,2));
rho=reshape(rho,1,size(rho,1)*size(rho,2));
if (length([x y rho])>3) 
   error('non-scalar arguments');
end;
if ((x==0) & (y==0))
   p2=0.25+asin(rho)/(2*pi);
   return;
end;
p=0.5*(normcdf(x)+normcdf(y));
if (x==0) 
   p=p-0.25*sign(y)
else
   p=p-T_Owen(x,(y-rho*x)/(x*sqrt(1-rho^2)));
end;
if (y==0) 
   p=p-0.25*sign(x)
else
   p=p-T_Owen(y,(x-rho*y)/(y*sqrt(1-rho^2)));
end;
if ((x*y<0)|((x*y==0)&((x+y)<0)))
   p=p-0.5;
end;
warning on;
p2=p;


