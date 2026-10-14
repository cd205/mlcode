function [x,y] = Circle(R)
angle = 0:2*pi/200:2*pi;
x = R*cos(angle);
y = R*sin(angle);
