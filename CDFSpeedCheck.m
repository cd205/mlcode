
% these two are equivalent but the first uses matlabs solution
% the second uses the method illustrated by Nelson
clear all
clc
t1 = tic;
for i = 1 : 1000
F = mvncdf([3,3],[7,7],[5,5],[2,0;0,2]);
end
toc(t1)


t2 = tic;
for i = 1 : 1000
F = mvncdf([7,7],[5,5],[2,0;0,2]);
F = mvncdf([3,7],[5,5],[2,0;0,2]);
F = mvncdf([7,3],[5,5],[2,0;0,2]);
F = mvncdf([3,3],[5,5],[2,0;0,2]);
end
toc(t2)

% evaluate up to infinity
t3 = tic;
for i = 1 : 10000
F = mvncdf([3,3],[inf,inf],[5,5],[2,0;0,2]);
end
toc(t3)
F

% evaluate from infinity (standard problem) twice as fast
t4 = tic;
for i = 1 : 10000
F = mvncdf([7,7],[5,5],[2,0;0,2]);
end
toc(t4)
F