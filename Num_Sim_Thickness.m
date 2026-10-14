
% simulate thickness numerical 
tic
clear all
close all
clc
n = 10000
sig11 = 1.5;
sig22 = 0.1;
mu1 = 0
mu2 = 0
tlim = 0.0
do = mu1+(randn(n,1)*sqrt(sig22));
%di = mu2+(randn(n,1)*sqrt(sig11));
di = num_TruncNorm(mu2,1,-4,n,sig11);

t = do-di;

figure;
hist(di,50); grid on
xlabel('Inner-Diameter')
figure;
hist(do,50); grid on
xlabel('Outer-Diameter')
figure;
hist(t,50); grid on
xlabel('Initial Thickness')


[pos] = find(t>tlim);% find all the rework thicknesses
length(pos)
figure; hist(do(pos),80); xlabel('Outer Diameter Over'); grid on
[pos2] = find(t<tlim);
do_over = do(pos);% find all the outer diameters that have to be re-cut (i.e. thickness too large)
do_OK =do(pos2);  % find all the outer diameters that are ok, i.e. thickness is in spec
mean_do = mean(do)
mean_do_over = mean(do_over)
mean_do_OK = mean(do_OK)
do_n = do;
while length(pos)>0
for i = 1:length(pos)
    
    old = do(pos(i));
    temp = mu1+randn(1,1);
    while temp>old
         temp = mu1+randn(1,1);
    end
    tempvec (i) = temp;
    do_n(pos(i)) = temp;
end
t = do_n-di;
[pos] = find(t>tlim) ;
end
Mean_t = mean(t)
Mean_do_n = mean(do_n)
Mean_temp = mean(tempvec)

figure;
hist(do,30); grid on; hold on
hist(do_n,80)
h = findobj(gca,'Type','patch');
set(h(2),'FaceColor','r','EdgeColor','k');
xlabel('Final Outer-Diameter')
figure;
hist(t,50); grid on
xlabel('Final Thickness')
toc


