function [z] = dmsn_quad2d(x,y,MU,SIGMA,ALPHA)


[m,n] = size(x);
x_vec = reshape(x,m*n,1);
y_vec = reshape(y,m*n,1);
z_vec = dmsn([x_vec y_vec],MU,SIGMA,ALPHA);
z = reshape(z_vec,m,n);
size(z); % Check size of z should be same as input size necessary for the 
% quad2D function. 
end