function numdev=num_deriv(coefficients,FUN,X,y,freq)
%derivate seconde numeriche, se FUN da' il gradiente
values=feval(FUN,coefficients,X,y,freq);
p=length(values);
H=zeros(p,p);
h=zeros(1,p);
delta=[(abs(coefficients)+ 1.e-10)'.*1.e-5,repmat(1.e-06,p,1)];
max(delta');
for i=1:p,
   h(i)=delta(i);
   new_values=feval(FUN,coefficients+h,X,y,freq);
   H(:,i)=(new_values-values)'./delta(i);
   h(i)=0;
end;
numdev=(H+H')./2;
