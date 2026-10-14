% PDF simple box

close all
clc

a = 1;
b = 2;
x0 = 2  % Inital starting point

% Area of the small box.  The area of the larger box: B=4*A
A = a^2

% Volumes of the 2 boxes
Vol_a = a^2 * normcdf(2,2,1)
Vol_b = b^2 * normcdf(3,2,1)

fun = @(mu) A * normcdf(2,mu,1) + 4*A * normcdf(3,mu,1)...
    - 4*A * normcdf(3,2,1);

x = fzero(fun,x0) % The value of mu such that the area out of the from the
                  % large box is equal to the area left in the small box.