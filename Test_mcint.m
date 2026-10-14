clear all
clc
%function Test_mcint
%% test the mcint problem on a simple integral %%
%  1  1
%  / /
%  | | (x1*x2*x3) dx3 dx2 dx1
%  / / 
%  0  0

% number of points to use
n = 1e1 % more points = more accuracy. Relative error goes as 1/sqrt(n)
opt.maxArray = 1e5;
opt.noerror = 0;
%opt.tol = 2e-4;
opt.time = 60;
opt.warnOff = 0;

%fun2D = @(x,y) x.*y;

h.b = [ [0,1];[0,1];[0,1]];
h.cond = {};
h.funcs = {@fun3D};

% function f = fun2D(x, par)
% f = x.*y

tic;
% change hypervolume !!HERE!! to change test
[I,info] = mcint(h, n, opt)
toc
%disp(info);
disp('Integral:')
I(:,:,1)
if opt.noerror==0
    disp('Error:')
    I(:,:,2)
end

