% simple box with PDFs 2
clear all
clc
format long
x0 = 3

fun = @(mu) 1- (normcdf(3,mu,1)/0.5 + (1/11.6))

x = fzero(fun,x0) % The value of mu such that the area out of the from the
                  % large box is equal to the area left in the small box.
                  % mvncdf([-10 -10 3],[3 3 7],[4 4 mu],[1 0 0;0 1 0;0 0 1])
       % this equatioh (below) is b1-b1-a2 = 0
fun1 = @(mu) (2*normcdf(3,4,1)*normcdf(3,3,1)-2*normcdf(3,4,1)*normcdf(3,mu,1)) - (normcdf(3,4,1)^2*(1-normcdf(3,mu,1)))
x1 = fzero(fun1,x0)
    

%fun3 = @(mu) normcdf(3,3,1)/11.6 - (0.5-normcdf(3,mu,1))
% Take out 'a' from 'b' (b-a) but vol in 'a' is not lost from system, as a
% result 'a' gets bigger by mu2*da/dmu - mu1*da/dmu. So equation becomes:
%               a + (mu2*da/dmu - mu1*da/dmu) = b1 - b2   (b2 < b1)

fun3 = @(mu) 0.02515555*0.5 + (mu*0.01086 - 3*0.01086)...
    - (0.3168619*0.5 - 0.3168619*normcdf(3,mu,1))% + (mu*-0.12042 - 3*-0.12042)
x3 = fzero(fun3,x0)

% this one is 3D for sigma1,2,3 = 1
fun3b = @(mu) (1-normcdf(3,3,1))/12.5988807 + ((mu*0.031 - 3*0.031))...
        - (0.5 - normcdf(3,mu,1)) 
x3b = fzero(fun3b,x0)

% this one is 3D for sigma1 = 1, sigma2 = 0.6, sigma3 = 0.4
fun3bb = @(mu) (1-normcdf(3,3,1))/27.22859 + ((mu*0.014 - 3*0.014))...
        - (0.5 - normcdf(3,mu,0.4)) 
x3bb = fzero(fun3bb,x0)

% this one if 4D for sigma1,2,3,4 = 1
fun4 = @(mu) 0.00399334*0.5 + (mu*0.001566 - 3*0.001566)...
    + 3*(0.02513518*0.5) + (mu*0.00986 - 3*0.00986)...
    - (0.474681618*0.5 - 0.474681618*normcdf(3,mu,1))
x4 = fzero(fun4,x0)

fun4b = @(mu) (1-normcdf(3,3,1))/118.8684362 + (mu*0.0033 - 3*0.0033)...
     + 3*(1-normcdf(3,3,1))/18.8845942 + (mu*0.021 - 3*0.021)...
     - (0.5 - normcdf(3,mu,1))
 x4b = fzero(fun4b,x0)
% fun4 = @(mu) (1-normcdf(3,3,1))/118.8684362 + 3*(1-normcdf(3,3,1))/18.8845942...
%     - (0.5 - normcdf(3,mu,1))
% 
% x4 = fzero(fun4,x0)
% % 
% fun5 = @(mu) ((normcdf(3,3,1)/118.8684362) - ((normcdf(3,mu,1)-normcdf(3,3,1))/83.08135595))...
%     + (3*normcdf(3,3,1)/18.8845942) - ((normcdf(3,mu,1)-normcdf(3,3,1))/13.19911108)...
%     - (0.5 - normcdf(3,mu,1))
% 
% x5 = fzero(fun5,x0)

