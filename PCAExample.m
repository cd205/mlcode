clear all
clc
close all

x1 = linspace(2,5,7); x2 = linspace(2,4,7)
[X1 X2] = meshgrid(x1,x2);
X = [X1(:) X2(:)];
Y = X(:,1).^3 - 0.0001.*(X(:,2));
figure;
surf(x1,x2,reshape(Y,7,7))

DATA = [Y,X(:,1),X(:,2)]

coeff = pca(DATA)