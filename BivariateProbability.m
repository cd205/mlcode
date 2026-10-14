% bivariate probability 
clear all
clc
mu_x = 5
mu_y = 6
sig_x = 0.7
sig_y = 0.5
x = 5
y = 5
rho = 0.0

Zx = (x - mu_x)/sig_x % normalised variables 
Zy = (y - mu_y)/sig_y % normalised variables 

% bivarite normal full function
BiPDF1 = (1/(2*pi*sig_x*sig_y*sqrt(1-rho^2)))*...
    exp(-(1/2*(1-rho^2))*(((x-mu_x)/sig_x)^2+((y-mu_y)/sig_y)^2-2*rho*((x-mu_x)/sig_x)*((x-mu_y)/sig_y)))
% bivarite normal function with normalised variables 
BiPDF2 = (1/(2*pi*sig_x*sig_y*sqrt(1-rho^2)))*exp(-((Zx^2+Zy^2-2*rho*Zx*Zy)/(2*(1-rho^2))))
% Matlab multivariate normal function
BiPDF3 = mvnpdf([x y],[mu_x mu_y],[sig_x^2 rho*sig_x*sig_y; rho*sig_x*sig_y sig_y^2])

%%
% normal funcion
Nx = 1/(sig_x*sqrt(2*pi))*exp(-(x-mu_x)^2/2*sig_x^2)
Ny = 1/(sig_y*sqrt(2*pi))*exp(-(y-mu_y)^2/2*sig_y^2)
MNx = normpdf(x,mu_x,sig_x)
MNy = normpdf(y,mu_y,sig_y)

%%
NxNy = Nx*Ny
MNxMNy1 = MNx*MNy
MNxMNy2 = normpdf(x,mu_x,sig_x)*normpdf(y,mu_y,sig_y)
%MNxMNy3 = mvnpdf([x y],[mu_x mu_y,[