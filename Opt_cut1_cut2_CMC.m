% optimitse cut1 and cut2 for min cost
clear all
close all
clc

cut1vec = linspace(3,7,20)
cut2vec = linspace(3,7,20)
%[X Y] = meshgrid(cut1vec,cut2vec)

for i = 1:length(cut1vec)
    for j = 1:length(cut2vec)
    fvals(j,i) = Fun_Cut_Measure_Cut_Dist_Cost(cut1vec(i),cut2vec(j));
    end
end

surf(cut1vec,cut2vec,fvals)
xlabel('cut 1')
ylabel('cut 2')
