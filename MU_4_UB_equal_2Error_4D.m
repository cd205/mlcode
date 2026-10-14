% Find balcne to make upper bound twice error on 4D
clear all
clc
x0 = 3

fun = @(mu) (1 - (normcdf(3,mu,1)*2 + 1/34.8) )%+ (normcdf(3,mu,1)*3 + (1/17.9089)) )

x = fzero(fun,x0) % The value of mu such that the area out of the from the
                  % large box is equal to the area left in the small box.
                  
