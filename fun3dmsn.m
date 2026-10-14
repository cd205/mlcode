function f = fun3dmsn(X,par)
mu_x = 1.5;
mu_y = 1.5;
mu_z = 1.5;
omega_xx = 0.5;        %      cov(x,x) cov(x,y) cov(x,z)
omega_yy = 0.5;        %  C = cov(y,x) cov(y,y) cov(y,z)
omega_zz = 0.5;        %      cov(z,x) cov(z,y) cov(z,z)
omega_xy = 0.2;
omega_xz = 0.15;
omega_yx = 0.2;
omega_yz = 0.15;
omega_zx = 0.15;
omega_zy = 0.1;
alpha_x = -3;
alpha_y = -4;
alpha_z = -5;
MU = [mu_x, mu_y, mu_z];
OMEGA = [omega_xx omega_xy omega_xz;...
    omega_yx omega_yy omega_yz;...
    omega_zx omega_zy omega_zz];
ALPHA = [alpha_x alpha_y alpha_z];
f = dmsn_MC(X(1,:),X(2,:),X(3,:),MU,OMEGA,ALPHA);