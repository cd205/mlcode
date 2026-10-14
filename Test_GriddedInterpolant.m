%test griddedInterpolant
clear all
close all
clc
x = linspace(0,10,10);
y = x;
[X1,Y1] = meshgrid(x,y);
[X2,Y2] = ndgrid(x,y);
%[X,Y] = ndgrid(1:10,1:10);
V = @(X,Y) X.^2 +Y.^2.*cos(X./sqrt(Y)).^2;
S1 = V(X1(:),Y1(:));
S1 = reshape(S1,length(x),length(y));
S2 = V(X2(:),Y2(:));
S2 = reshape(S2,length(y),length(x));

figure;
subplot(1,2,1)
surf(x,y,S1)
xlabel('x')
ylabel('y')
subplot(1,2,2)
mesh(x,y,S1)

figure;
subplot(1,2,1)
surf(x,y,S2)
xlabel('x')
ylabel('y')
subplot(1,2,2)
mesh(x,y,S2)
% V = X.^2 + Y.^2;
% 
% 
% 
% F = griddedInterpolant(X,Y,V,'cubic');
% [Xq,Yq] = ndgrid(1:0.5:10,1:0.5:10);
% Vq = F(Xq,Yq);
% mesh(Xq,Yq,Vq);
