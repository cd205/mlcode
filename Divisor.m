clear all
close all
clc
U = 100
ns = U
vec1 = linspace(1,U,ns)
vec2 = vec1;
for i = 1:length(vec1)
    r(i,:) = vec1(i).*vec2;
end
r = r(:);
for i = 1:max(r)
    n1(i) = length(find(r==i));
end
figure(1)
plot(1:1:max(r),n1,'.','MarkerSize',20); grid on
xlabel('integer')
ylabel('number of occurances')
% figure(11)
% nbins = linspace(min(r),max(r),200);
% hist(r,nbins); grid on
% %hist(r); grid on
% xlabel('c')
% ylabel('Occurances')
% Mean = mean(r)
% Skew = skewness(r)
