clear all 
close all
R = linspace(1,10,100);
L = linspace(2,10,100);
B = 2
N = 200

for i=1:length(R)
    for j = 1:length(L)
        F(j,i) = (pi.*R(i)^2.*L(j)-B)*N;
    end
end

surf(R,L,F)