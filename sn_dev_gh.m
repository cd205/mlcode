function gra=sn_dev_gh(cp,X,y,traceout)
%computes gradient of dev=-2*logL for centred parameters
%(and observed information matrix)
if nargin<4 traceout=0;
end;
if nargin<3 error('Required arguments are missing');
end;
if isnan(traceout) traceout=0;
end;
y=reshape(y,length(y),1); %vettore colonna
m=size(X,2);
n=size(X,1);
np=m+2;
score=repmat(NaN,1,np);
info=repmat(NaN,np,np);
beta=cp(1:m);
sigma=cp(m+1);
gamma1=cp(m+2);
lambda=gamma1_to_lambda(gamma1);
mu=X*beta'; %nx1=(nxm)*(mx1)
d=y-mu;
r=d/sigma;
E_Z=lambda*sqrt(2/(pi*(1+lambda^2)));
s_Z=sqrt(1-E_Z^2);
z=E_Z+s_Z*r;
p1=zeta(1,lambda*z);
p2=zeta(2,lambda*z);
omega=sigma/s_Z;
w=lambda*p1-E_Z;
DE_Z=sqrt(2/pi)/(1+lambda^2)^1.5;
Ds_Z=(-E_Z/s_Z)*DE_Z;
Dz=DE_Z+r*Ds_Z;
DDE_Z=(-3)*E_Z/(1+lambda^2)^2;
DDs_Z=-((DE_Z*s_Z-E_Z*Ds_Z)*DE_Z/s_Z^2+E_Z*DDE_Z/s_Z);
DDz=DDE_Z+r*DDs_Z;
score(1:m)=omega^(-2)*(X')*(y-mu-omega*w);
score(m+1)=(-n)/sigma+s_Z*sum(d.*(z-p1*lambda))/sigma^2;
score(m+2)=n*Ds_Z/s_Z-sum(z.*Dz)+sum(p1.*(z+lambda*Dz));
Dg_Dl=1.5*(4-pi)*E_Z^2*(DE_Z*s_Z-E_Z*Ds_Z)/s_Z^4;
score(m+2)=score(m+2)/Dg_Dl; %convert deriv wrt lambda to gamma1
%parte per procedure 'constr'
%dfdg='[0;0;0];'; %derivata del vincolo -1<0
%gra=-2*score;
%gra=['df=[',num2str(score),'];dg=',dfdg];
%fine parte per procedurea 'constr'
info(1:m,1:m)=omega^(-2)*(X')*(repmat((1-lambda^2*p2),1,m).*X);
info(1:m,m+1)=s_Z*(X')*((z-lambda*p1)+d.*(1-lambda^2*p2)*s_Z/sigma)...
   /sigma^2;
info(m+1,1:m)=info(1:m,m+1)';
info(m+1,m+1)=(-n)/sigma^2+2*s_Z*sum(d.*(z-lambda*p1))/sigma^3+...
   s_Z^2*sum(d.*(1-lambda^2*p2).*d)/sigma^4;
tmp=Ds_Z.*w+s_Z.*(p1+lambda^2*p2.*Dz-DE_Z);
info(1:m,m+2)=X'*(-2*Ds_Z.*d/omega+Ds_Z.*w+s_Z.*(p1+lambda*p2.*...
   (z+lambda.*Dz)-DE_Z))/sigma;
info(m+2,1:m)=info(1:m,m+2)';
info(m+1,m+2)=-sum(d.*(Ds_Z.*(z-lambda*p1)+s_Z.*(Dz-p1-p2*...
   lambda.*(z+lambda*Dz))))/sigma^2;
info(m+2,m+1)=info(m+1,m+2);
info(m+2,m+2)=n*(-DDs_Z.*s_Z+Ds_Z.^2)./s_Z.^2+sum(Dz.^2+z.*DDz)...
   -sum(p2.*(z+lambda*Dz).^2)-sum(p1.*(2*Dz+lambda*DDz));
info(np,:)=info(np,:)./Dg_Dl; %convert info wrt lambda to gamma1
info(:,np)=info(:,np)./Dg_Dl;
if traceout
   disp('grad.hessian: gradient=');
   disp(-2*score);
end;
gra=struct('gradient',-2*score,'info',info);


