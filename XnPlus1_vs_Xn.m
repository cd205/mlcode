
clear all
clc
No=40

for j=1:3
    r=[0.5 1 3.5]
    xn=[0:1/No:1];
    xn_1=[(r(j).*xn).*(1-xn)];
    figure(3)
    plot(xn,xn_1,'b-+')
    xlabel('x_n')
    ylabel('x_{n+1}')
   
    hold on
end
figure(3)
plot(xn,xn,'r-')