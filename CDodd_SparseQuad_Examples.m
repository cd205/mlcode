clear all
close all
clc

options = spset('RelTol',1e-6,'AbsTol',1e-9)

f = @(x,y) sin(x) + cos(y);
z = spvals(f,2,[0 pi; 0 pi],options)


x = linspace(0,pi,20);
y = x;
[X Y] = meshgrid(x,y);
exact = f(X,Y);

figure(1)
surf(x,y,exact)
xlabel('x')
ylabel('y')
zlabel('f(x,y)')

x1 = pi*rand(1,5);
x2 = pi*rand(1,5);
approx = spinterp(z,x1,x2)
error = max(abs(approx - f(x1,x2)))

figure(1) 
hold on
plot3(x1,x2,approx,'k.','MarkerSize',25)

figure(2)
plotgrid(8,2)