clear all
close all
clc
global fvalhist
options = optimset('OutputFcn', @outfun);


objfun=@(x) exp(x(1))*(4*x(1)^2+2*x(2)^2+x(1)*x(2)+2*x(2));
[x fval] = fminsearch(objfun, [-1 1], options)
