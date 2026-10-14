clear all
clc

xrange = linspace(-10,10,20);
yrange = linspace(-10,10,20);
mu_x = 0;
mu_y = 0;
omega_x = 1;
omega_y = 1;
alpha_x = 0;
alpha_y = 0;

pdf_x = dsn(xrange,mu_x,omega_x,alpha_x);
plot(xrange,pdf_x,'-.')