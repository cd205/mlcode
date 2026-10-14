% Amir method vs standard method for rectangular probability calculation
clear all
clc

mu_x = 1.5;
mu_y = 1.5;
mu_z = 1.5;
omega_xx = 0.5;        %      cov(x,x) cov(x,y) cov(x,z)
omega_yy = 0.5;        %  C = cov(y,x) cov(y,y) cov(y,z)
omega_zz = 0.5;        %      cov(z,x) cov(z,y) cov(z,z)
omega_xy = 0.1;
omega_xz = 0.1;
omega_yx = 0.1;
omega_yz = 0.1;
omega_zx = 0.1;
omega_zy = 0.1;
alpha_x = -5;
alpha_y = -5;
alpha_z = -5;


%% Standard method 2D scrap, rework and conformance%%
MU = [mu_x, mu_y];
OMEGA = [omega_xx omega_xy; omega_yx omega_yy];
ALPHA = [alpha_x alpha_y];

fun = @(X,Y) dmsn_quad2d(X,Y,MU,OMEGA,ALPHA);

start1 = tic;
for i = 1:1
RW_X = quad2d(fun,2,10,1,2);
RW_Y = quad2d(fun,1,2,2,10);
RW_XY = quad2d(fun,2,10,2,10);
SC_X = quad2d(fun,-10,1,-10,10);
SC_Y = quad2d(fun,-10,10,-10,1);
SC_XY = quad2d(fun,-10,1,-10,1);
Rwork_Total = RW_X + RW_Y + RW_XY;
Scrap_Total = SC_X + SC_Y - SC_XY;
Conformance = 1 - Rwork_Total - Scrap_Total;
Non_Conformance = 1 - Conformance;
end
Conformance
toc(start1)

%% Amir's bounds method 2D scrap, rework and conformance%%
start2 = tic;
for i = 1:1
F_b1b2 = quad2d(fun,-10,2,-10,2)
F_a1b2 = quad2d(fun,-10,1,-10,2)
F_b1a2 = quad2d(fun,-10,2,-10,1)
end
toc(start2)
Conformance_L = max(F_b1b2 - (F_a1b2 + F_b1a2),0)
Conformance_U = F_b1b2 - max(F_a1b2,F_b1a2)

%% try it in reverse
start3 = tic;
for i = 1:1
F_a1a2 = quad2d(fun,1,10,1,10)
F_a1b2 = quad2d(fun,1,10,2,10)
F_b1a2 = quad2d(fun,2,10,1,10)
end
toc(start3)
Conformance_L = max(F_a1a2 - (F_a1b2 + F_b1a2),0)
Conformance_U = F_a1a2 - max(F_a1b2,F_b1a2)

%% Standard Method 3D conformance ONLY %%
MU = [mu_x, mu_y, mu_z];
OMEGA = [omega_xx omega_xy omega_xz;...
    omega_yx omega_yy omega_yz;...
    omega_zx omega_zy omega_zz];
ALPHA = [alpha_x alpha_y alpha_z];
fun3d = @(X,Y,Z) dmsn_triplequad(X,Y,Z,MU,OMEGA,ALPHA)

F_b1b2b3 = triplequad(fun3d,-10,2,-10,2,-10,2);
%F_b1b2b3ccc = mvncdf([-10 -10 -10],[2 2 2],MU,OMEGA)
F_b1b2a3 = triplequad(fun3d,-10,2,-10,2,-10,1);
%F_b1b2a3ccc = mvncdf([-10 -10 -10],[2 2 1],MU,OMEGA)
F_b1a2b3 = triplequad(fun3d,-10,2,-10,1,-10,2);
%F_b1a2b3ccc = mvncdf([-10 -10 -10],[2 1 2],MU,OMEGA)
F_b1a2a3 = triplequad(fun3d,-10,2,-10,1,-10,1);
%F_b1a2a3ccc = mvncdf([-10 -10 -10],[2 1 1],MU,OMEGA)
F_a1b2b3 = triplequad(fun3d,-10,1,-10,2,-10,2);
%F_a1b2b3ccc =  mvncdf([-10 -10 -10],[1 2 2],MU,OMEGA)
F_a1b2a3 = triplequad(fun3d,-10,1,-10,2,-10,1);
%F_a1b2a3ccc = mvncdf([-10 -10 -10],[1 2 1],MU,OMEGA)
F_a1a2b3 = triplequad(fun3d,-10,1,-10,1,-10,2);
%F_a1a2b3ccc = mvncdf([-10 -10 -10],[1 1 2],MU,OMEGA)
F_a1a2a3 = triplequad(fun3d,-10,1,-10,1,-10,1);
%F_a1a2a3ccc = mvncdf([-10 -10 -10],[1 1 1],MU,OMEGA)

Conformance = +F_b1b2b3 - F_b1b2a3 - F_b1a2b3 + F_b1a2a3 - F_a1b2b3 +...
    F_a1b2a3 + F_a1a2b3 - F_a1a2a3

%[X1,X2,X3] = meshgrid(linspace(-5,5,25)',linspace(-5,5,25)',linspace(-5,5,25)');
%X = [X1(:),X2(:),X3(:)];
% xl = [1,1,1];
% xu = [2,2,2];
% Ccc = mvncdf(xl,xu,MU,OMEGA)

%% Amir Method 3D conformance ONLY %%
F_b1b2b3 = triplequad(fun3d,-10,2,-10,2,-10,2);
F_a1b2b3 = triplequad(fun3d,-10,1,-10,2,-10,2);
F_b1a2b3 = triplequad(fun3d,-10,2,-10,1,-10,2);
F_b1b2a3 = triplequad(fun3d,-10,2,-10,2,-10,1);

Conformance_L = max(F_b1b2b3 - (F_a1b2b3 + F_b1a2b3 + F_b1b2a3),0)
Conformance_U = F_b1b2b3 - max([F_a1b2b3, F_b1a2b3, F_b1b2a3])

%%% in reverse %%%
F_a1a2a3 = triplequad(fun3d,1,10,1,10,1,10);
F_b1a2a3 = triplequad(fun3d,2,10,1,10,1,10);
F_a1b2a3 = triplequad(fun3d,2,10,1,10,1,10);
F_a1a2b3 = triplequad(fun3d,1,10,1,10,2,10);

Conformance_L = max(F_a1a2a3 - (F_b1a2a3 + F_a1b2a3 + F_a1a2b3),0)
Conformance_U = F_a1a2a3 - max([F_b1a2a3, F_a1b2a3, F_a1a2b3])
