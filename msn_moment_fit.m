function est=msn_moment_fit(y)
%31-12-97: simple fit pf MSN distribution using moments
%display('MLE con metodo momenti');
k=size(y,2);
m_y=mean(y);
var_y=cov(y);
y0=(y'-repmat(m_y',1,size(y,1)))./repmat(sqrt(diag(var_y)),1,size(y,1));
gamma1=mean((y0').^3);
out=(abs(gamma1)>0.99527);
gamma1(out)=sign(gamma1(out)).*0.995;
a=sign(gamma1).*(2.*abs(gamma1)./(4-pi)).^0.33333;
delta=sqrt(pi/2).*a./sqrt(1+a.^2);
m_z=delta.*sqrt(2/pi);
omega=sqrt(diag(var_y)'./(1-m_z.^2));
Omega=var_y+(omega.*m_z)'*(omega.*m_z);
xi=m_y-omega.*m_z;
O_cor=diag(1./omega)*Omega*diag(1./omega);
O_cor=(O_cor'+O_cor)./2;
O_inv=inv(O_cor);
tmp=1-delta*O_inv*delta';
if tmp<=0 
   tmp=0.0001;
   admissible=0;
else
   admissible=1;
end;
alpha=(O_inv*delta')'./sqrt(tmp);
est=struct('xi',xi,'Omega',Omega,'alpha',alpha,'Omega_cor',O_cor,...
   'omega',omega,'delta',delta,'skewness',gamma1,...
   'admissible',admissible);






