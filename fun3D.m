function f=fun3D(x,par)
x
f = x(1,:).*x(2,:).*x(3,:);
%f = exp( -sqrt( (x(1,:).^2+x(2,:).^2) ) );