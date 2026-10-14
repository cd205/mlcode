function Ddev=msn_dev_grad(param,X,y,freq,traceout)
if nargin<5 traceout=0;
end;
if isnan(traceout) traceout=0;
end;
k=size(y,2);
n=sum(freq);
m=size(X,2);
beta=reshape(param(1:(m*k)),m,k);
al_om=param((m*k+1):(m*k+k));
y0=y-X*beta;
Omega=(y0'*(y0.*repmat(freq',1,k)))./n;
p1=zeta(1,(y0*al_om')');
Dbeta=X'*(y0.*repmat(freq',1,k))*inv(Omega)...
   -((X.*repmat(freq',1,m))'*p1')*al_om;
Dal_om=((y0.*repmat(freq',1,k))'*p1')';
if traceout
   disp('gradient:');
   disp([Dbeta;Dal_om]);
end;
Ddev=-2.*[reshape(Dbeta,1,m*k),Dal_om];
