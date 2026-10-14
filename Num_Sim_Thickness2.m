
% simulate thickness numerical 
tic
clear all
close all
clc
n = 1000000
sig11 = 1.5;
sig22 = 2;
mu1 = 9
mu2 = 5
tlim = 4
do = mu1+(randn(n,1)*sqrt(sig11));
%di = mu2+(randn(n,1)*sqrt(sig11));
di = num_TruncNorm(mu2,7,0,n,sig22);

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
mean_do_over = mean(do_over);
mean_di_over = mean(di(pos))
figure;
hist(di(pos),100); grid on
xlabel('di over')
mean_do_OK = mean(do_OK);
do_n = do;
di = di;
while length(pos)>0
    for i = 1:length(pos)
        do_n(pos(i)) = (mu1-mu2)+di(pos(i))+randn(1,1)*sig11;
        do_n_temp(i) = (mu1-mu2)+di(pos(i))+randn(1,1)*sig11;
    end
    t = do_n-di;
    [pos] = find(t>tlim);% find all the rework thicknesses
    length(pos);
end
figure;
hist(t,100); grid on
xlabel('Final Thickness')
figure;
hist(do_n,100); grid on
xlabel('Final do diameter')
figure(9)
hist(do_n_temp,100); grid on
xlabel('Reworked do diameter')
% Mean_t = mean(t)
% Mean_do_n = mean(do_n)
% Mean_temp = mean(tempvec)
% 
% figure;
% hist(do,30); grid on; hold on
% hist(do_n,80)
% h = findobj(gca,'Type','patch');
% set(h(2),'FaceColor','r','EdgeColor','k');
% xlabel('Final Outer-Diameter')
% figure;
% hist(t,50); grid on
% xlabel('Final Thickness')
% toc


