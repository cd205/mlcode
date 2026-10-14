function [out] = dmsn_triplequad(x,y,z,MU,SIGMA,ALPHA)

[m,n] = size(x);
x_vec = reshape(x,m*n,1);
y_vec = reshape(y,m*n,1);
z_vec = reshape(z,m*n,1);
out_vec = dmsn([x_vec y_vec z_vec],MU,SIGMA,ALPHA);
out = reshape(out_vec,m,n);
size(out); % Check size of z should be same as input size necessary for the 
% triplequad function. 
end