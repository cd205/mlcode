function pmsnc=plot_msn_cond(xi,Omega,alpha,fixed_comp,fixed_values,n)
%plot_msn_cond
%Plot of the density of a conditional skew-normal variate
% 
%DESCRIPTION
% 
%Plot of the exact and of the approximate density function of a
%multivariate skew-normal variate conditionally on the values taken on by
%some components.
% 
%USAGE
% 
%plot_msn_cond(xi, Omega, alpha, fixed_comp, fixed_values, n)
% 
%REQUIRED ARGUMENTS
% 
%xi	a numeric vector of length k, say, giving the location parameter.
% 
%Omega	a covariance matrix of dimension (k,k).
% 
%alpha	a numeric vector of length k, which regulates the shape of the
% 	density.
% 
%fixed_comp	a vector containing a subset of 1:k which selects the
% 		components whose values are to be fixed; it must be of length k-2.
% 
%fixed_values	a numeric vector of values taken on by the components
% 		fixed_comp; it must be of the same length of fixed_comp.
% 
%n	an integer value which determines the grid size of the density
% 	computations and plot (default is 35).
% 
%VALUE
% 
%a list containing the following elements:
% 
%cumulants, fit 	two lists as returned by msn_conditional
% 
%pdf	a list containing the coordinates x and y of the points where
% 	the densities have been evaluated, and the matrices f_exact and f_fitted
%  	of the exact and fitted conditional densities.
% 
%rel_error, abs_error	summary statistics of relative and absolute
% 			error of the approximation
% 
%SIDE EFFECTS
% 
%A contour plot of the exact and approximate densities is produced on a
%graphical device.
% 
%DETAILS
% 
% 
%REFERENCES
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%msn_conditional, dmsn
% 
%EXAMPLES
% 
%Omega = eye(3)+0.5.*ones(3,3)
%a = plot_msn_cond([0 0 0], Omega, [1:3], 3, -0.75)

% fa il grafico di Y_2|Y_1; assumiamo che dim(Y_2)=2.
if nargin<6 n=35;
end;
if nargin<5 error('missing required arguments');
end;
if isnan(n) n=35;
end;
fc=fixed_comp;
fv=fixed_values;
cond=msn_conditional(xi,Omega,alpha,fc,fv);
xi_c=cond.fit.xi;
O_c=cond.fit.Omega;
a_c=cond.fit.alpha;
if any(size(O_c)~=[2 2]) 
   error('length(alpha)-length(fixed_comp)~=2');
end;
scale1=sqrt(O_c(1,1));
scale2=sqrt(O_c(2,2));
delta=cond.fit.delta;
omega=O_c(1,2)./(scale1.*scale2);
x=linspace(xi_c(1)-3*scale1,xi_c(1)+3*scale1,n);
y=linspace(xi_c(2)-3*scale2,xi_c(2)+3*scale2,n);
plot(x,y,'  w');
title('Conditional multivariate SN pdf');
z1=(x-xi_c(1))./scale1;
z2=(y-xi_c(2))./scale2;
[X Y]=meshgrid(z1,z2);
xoy=[reshape(X',size(X,1)*size(X,2),1),reshape(Y',size(Y,1)*size(Y,2),1)];
pdf_fit=dsn2(xoy(:,1),xoy(:,2),delta(1),delta(2),omega)./(scale1*scale2);
pdf_fit=reshape(pdf_fit,length(x),length(y));
cond.pdf=struct('x',x,'y',y,'fitted',pdf_fit);
lvs=linspace(min(min(pdf_fit)),max(max(pdf_fit)),7);
hold on;
[capp,h1]=contour(x,y,pdf_fit',lvs,'r-');
%fino a qui per il calcolo della densita' approx;
%ora otteniamo quella esatta
numer=msn_pdf2_aux(x,y,xi,Omega,alpha,fc,fv);
marg=msn_marginal(xi,Omega,alpha,fc);
denom=dmsn(fv,marg.xi,marg.Omega,marg.alpha);
pdf_exact=numer./denom;
pdf_exact=reshape(pdf_exact,length(x),length(y));
hold on;
[cexa,h2]=contour(x,y,pdf_exact',lvs,'k--');
legend([h1(1),h2(1)],'approx','exact '); 
clabel(capp);
hold off;
cond.pdf.f_exact=pdf_exact;
relerr=reshape((pdf_fit-pdf_exact)./pdf_exact,1,length(x)*length(y));
abserr=abs(reshape((pdf_fit-pdf_exact),1,length(x)*length(y)));
cond.rel_error=struct('min',min(relerr),...
   'q1',prctile(relerr,25),...
   'median',median(relerr),...
   'mean',mean(relerr),...
   'q3',prctile(relerr,75),...
   'max',max(relerr));
cond.abs_error=struct('min',min(abserr),...
   'q1',prctile(abserr,25),...
   'median',median(abserr),...
   'mean',mean(abserr),...
   'q3',prctile(abserr,75),...
   'max',max(abserr));
pmsnc=cond;

function pdf2=msn_pdf2_aux(x,y,xi,Omega,alpha,fc,fv)
nx=length(x);
ny=length(y);
FV=repmat(reshape(fv,1,length(fv)),nx*ny,1);
X=repmat(NaN,nx*ny,length(alpha));
X(:,fc)=FV;
[X1 Y1]=meshgrid(x,y);
xoy=[reshape(X1',size(X1,1)*size(X1,2),1),reshape(Y1',size(Y1,1)*size(Y1,2),1)];
mfc=[];
for i=1:length(alpha) if i~=fc(1:length(fc)) mfc=[mfc i]; end;end; %computes -fc
X(:,mfc)=xoy;
pdf=dmsn(X,xi,Omega,alpha);
pdf=reshape(pdf,nx,ny);
pdf2=pdf;

function dens=dsn2(x,y,d1,d2,omega)
u=(x.*(d1-omega.*d2)+y.*(d2-omega.*d1))./...
   sqrt((1-omega.^2-d1.^2-d2.^2+2.*omega.*d1.*d2).*(1-omega.^2));
pdfn2=exp(-0.5.*(x.^2-2.*omega.*x.*y+y.^2)./(1-omega.^2))./...
   (2.*pi.*sqrt(1-omega.^2));
dens=2.*pdfn2.*normcdf(u);


