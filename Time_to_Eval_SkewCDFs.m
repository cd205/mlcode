%% Time for Skew CDF evaluation
clear all
clc

nevals1 = 200;
nevals2 = 1;


X = linspace(0,3,20);
Y = linspace(0,3,20);
Z = linspace(0,3,20);
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
a1 = 1;
b1 = 2;
a2 = 1;
b2 = 2;
a3 = 1;
b3 = 2;

%% 1 variable - Quadrature method %%
fun = @(X) dsn(X,mu_x,omega_xx,alpha_x);
start1 = tic;
for i = 1:nevals1
        Int_1 = quad(fun,-10,a1);
end
Int_1
t1=toc(start1);
disp(['Time to evaluate 1 variable integral using quadrature is ', num2str(t1/nevals1), ' seconds.'])

%% 2 variable - Quadrature method %%
MU = [mu_x, mu_y];
OMEGA = [omega_xx omega_xy; omega_yx omega_yy];
ALPHA = [alpha_x alpha_y];
fun = @(X,Y) dmsn_quad2d(X,Y,MU,OMEGA,ALPHA);
start2 = tic;
for i = 1:nevals1
        Int_2 = quad2d(fun,-10,a1,-10,a2);
end
Int_2
t2=toc(start2);
disp(['Time to evaluate 2 variable integral using quadrature is ', num2str(t2/nevals1), ' seconds.'])

%% 3 variable - Quadrature method %%
MU = [mu_x, mu_y, mu_z];
OMEGA = [omega_xx omega_xy omega_xz;...
    omega_yx omega_yy omega_yz;...
    omega_zx omega_zy omega_zz];
ALPHA = [alpha_x alpha_y alpha_z];
fun = @(X,Y,Z) dmsn_triplequad(X,Y,Z,MU,OMEGA,ALPHA);
start3 = tic;
for i = 1:nevals2
    Int_3 = triplequad(fun,-10,a1,-10,a2,-10,a3);
end
Int_3
t3=toc(start3);
disp(['Time to evaluate 3 variable integral using quadrature is ', num2str(t3/nevals2), ' seconds.'])

%% 3 variable - Monte Carlo method B %%
%        b                 N
%       /           (b-a)*SUM f(xn)
%       |  f(x) ~= -----------------     error is 1/sqrt(N) does not depend
%       /                  N             on dimensions of integral
%        a
%F is the vectorized function to be evaluated
%bound is a vector representing the x,y,z bounds to the integrals
%N is the number of samples to use in the approximation
%e.g. MonteCarlo(inline('x.*y.*z'), [0 1 0 1 0 1], 1000)
fun = @(X,Y,Z) dmsn_MC(X,Y,Z,MU,OMEGA,ALPHA);
start3b = tic;
for i = 1:nevals2
    Int_3b = MonteCarlo(fun, [-10 a1 -10 a2 -10 a3], 100000);
end
Int_3b
t3b=toc(start3b);
disp(['Time to evaluate 3 variable integral using Monte Carlo is ', num2str(t3b/nevals2), ' seconds.'])

%% 3 variable - Monte Carlo method C %%

n = 1e5 % more points = more accuracy. Relative error goes as 1/sqrt(n)
opt.maxArray = 1e5;
opt.noerror = 0;
%opt.tol = 2e-4;
opt.time = 60;
opt.warnOff = 0;
h.b = [ [-10,a1];[-10,a2];[-10,a3]];
h.cond = {};
h.funcs = {@fun3dmsn};
start3c = tic;
for i = 1:nevals2
    [Int_3c info] = mcint(h, n, opt);
end
disp('Integral:')
Int_3c(:,:,1)
if opt.noerror==0
    disp('Error:')
    Int_3c(:,:,2)
end
t3b=toc(start3c);
disp(['Time to evaluate 3 variable integral using Monte Carlo is ', num2str(t3b/nevals2), ' seconds.'])
