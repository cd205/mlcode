function [out] = dmsn_Integral3(x,y,z,MU,SIGMA,ALPHA)

[m,n] = size(x);
x_vec = reshape(x,m*n,1);
y_vec = y;%reshape(y,m*n,1)
z_vec = z;%reshape(z,m*n,1)
for i = 1:length(x_vec);
    out_vec(i) = dmsn([x_vec(i) y_vec z_vec],MU,SIGMA,ALPHA);
end
out = reshape(out_vec,m,n);
size(out); % Check size of z should be same as input size necessary for the 
% triplequad function. 
end