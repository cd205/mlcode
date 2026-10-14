clear all
close all
clc

B = 0.002
L = linspace(20,40,40); % length
N = 50; % motor speed
R = linspace(20,60,40); % radius
actflow = ( pi().*R.*R.*L./1E6 - B ).*N

for i = 1:length(L)
    for j = 1:length(R)
        actflow(j,i) = ( pi().*R(j).*R(j).*L(i)./1E6 - B ).*N;
    end
end

figure;
surf(L,R,actflow)