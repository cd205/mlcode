function [z] = mvnpdf_quad2d(x,y,mu,SIGMA)

[m,n] = size(x);
x_vec = reshape(x,m*n,1);
y_vec = reshape(y,m*n,1);
z_vec = mvnpdf([x_vec y_vec],mu,SIGMA);
z = reshape(z_vec,m,n);
size(z);
% log_x_vec = log(x_vec);
% log_y_vec = log(y_vec);
% z_vec = 1./(x_vec.*y_vec).*mvnpdf([log_x_vec log_y_vec],mu,sigma);
% z = reshape(z_vec,m,n);
end