
clear all
close all
clc

n = 1000000;
sigma = 1;
N_0 = 5;
N_s = 10;

figure(1)
data_0 = normrnd(N_0,sigma,n,1);
bins = [0:0.1:12];
[y_0 x_0] = hist(data_0,bins);
bar(x_0,y_0)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 max(y_0)],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 max(y_0)],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on

figure(2)
N_1 = 7;
bins = [0:0.1:12];
data_1 = normrnd(6,sigma,n,1);
[y_1 x_1] = hist(data_1,bins);
bar(x_1,y_1)
xlabel('Dimension')
ylabel('Number of samples')
grid on

InSpec8 = 0; % aim for 9 but take any that are less then 7 out
y_T = zeros(1,length(x_1));
for i=1:length(y_1)
    if x_1(i)<=7
        InSpec8 = InSpec8 + y_1(i);
        y_T(i) = y_T(i) + y_1(i);
    else
        y_T(i) = y_T(i);
    end
end
y_T
InSpec8

data_11 = normrnd(5,sigma,n-InSpec8,1);
[y_11 x_11] = hist(data_11,bins);
figure(3)
bar(x_11,y_11)
grid on

InSpec9 = 0;  % aim for 9 but take any that are less then 7 out
for i=1:length(y_11)
    if x_1(i)<=7
        InSpec9 = InSpec9 + y_11(i);
        y_T(i) = y_T(i) + y_11(i);
    else
        y_T(i) = y_T(i) + y_11(i);        
    end
end
sum(y_T)
InSpec9

figure(4)
bar(bins,y_T)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 max(y_T)],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 max(y_T)],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on
% 
% dist = [0:0.1:10];
% tol = 0.001+0.01*dist.^2;
% figure(1)
% subplot(1,2,1)
% plot(dist,tol,'.-')
% xlabel('dist')
% ylabel('tol')
% subplot(1,2,2)
% loglog(dist,tol,'.-')
% xlabel('dist')
% ylabel('tol')

% % for cpk=1.33 for a process with dim = 1000, tol = 0.012 or
% % cpk = tol/3sigma
% % so sigma = tol/3(cpk)
% % sigma = 0.0012/3(1.33) = 0.003
% X = [999.9:0.001:1000.1]
% nr = normpdf(X,1000,0.003);
% figure(2)
% plot(X,nr,'.-')
% grid on
% 
% X_1 = [4:0.01;6];
% tol = @(dist) 0.001+0.01*dist^2;
% tol = tol(N_s);
% cpk = 0.9;
% sigma = tol/(3*cpk);
% data_1 = normpdf(X,5,sigma)