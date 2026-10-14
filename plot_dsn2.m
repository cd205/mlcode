function prof=plot_dsn2(x,y,xi,Omega,alpha)
%plot bivariate density SN_2(xi,Omega,alpha) computed at (x,y) grid

%da vedere per varargin
if nargin<5 error('Required arguments are missing');
end;
if any(size(Omega)~=[2 2]) error('dim(Omega)~=[2 2]');
end;
nx=length(x);
ny=length(y);
[X Y]=meshgrid(x,y);
xoy=[reshape(X',size(X,1)*size(X,2),1),reshape(Y',size(Y,1)*size(Y,2),1)];
pdf=dmsn(xoy,xi,Omega,alpha);
pdf=reshape(pdf,nx,ny);
c=contour(x,y,pdf','k');
clabel(c);
prof=struct('x',x,'y',y,'density',pdf,...
   'xi',xi,'Omega',Omega,'alpha',alpha);

            
            
            



   
   
     
