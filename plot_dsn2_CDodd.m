function prof=plot_dsn2_CDodd(x,y,xi,Omega,alpha)
%plot bivariate density SN_2(xi,Omega,alpha) computed at (x,y) grid

%da vedere per varargin
if nargin<5 error('Required arguments are missing');
end;
if any(size(Omega)~=[2 2]) error('dim(Omega)~=[2 2]');
end;
nx=length(x);
ny=length(y);
[X Y]=meshgrid(x,y);
%xoy=[reshape(X',size(X,1)*size(X,2),1),reshape(Y',size(Y,1)*size(Y,2),1)];
xoy=[reshape(Y',size(Y,1)*size(Y,2),1),reshape(X',size(X,1)*size(X,2),1)];
pdf=dmsn(xoy,xi,Omega,alpha);
pdf=reshape(pdf,nx,ny);
figure(3)
surf(x,y,pdf);
xlabel('x1'); ylabel('x2'); zlabel('Probability Density');
figure(4)
c=contour(y,x,pdf','k');
clabel(c);
prof=struct('x',x,'y',y,'density',pdf,...
   'xi',xi,'Omega',Omega,'alpha',alpha);

            
            
            


%% Example
% x = linspace(-3,3,30);
% y = linspace(-3,3,30);
% prof=plot_dsn2_CDodd(x,y,[0.0 0.0],[1 0;0 1],[0,0])
%    
   
     
