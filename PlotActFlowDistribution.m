%%% plot the distribution of Pump flow output given distribution for the
%%% lenght and radius inputs
clear all
close all
clc
n = 1000000;
CostOpt_mu_L =  26.0662
CostOpt_mu_R = 29.6589
sigma_L = 1;
sigma_R = 0.8;
r=rmsn(n,[CostOpt_mu_L CostOpt_mu_R],[sigma_L^2 0;0 sigma_R^2],[0 0]);
%L_vec = r(:,1);
%R_vec = r(:,2);
N = 150;
B = 0.002;
actflow = (pi().*r(:,2).*r(:,2).*r(:,1)/1E6 - B).*N;
avg_actflow = mean(actflow)

figure(5)
plot(actflow,'.')
[y x] = hist(actflow,100);

bar(x,y)
xlabel('Flow rate')
ylabel('Number of samples')
line([10 10], [0 40000],'color',[0 1 0])
line([avg_actflow avg_actflow], [0 40000],'color',[1 0 0])
%F = ceil(10 * tiedrank(actflow) / length(actflow))


figure(2)
nrm = 13000.*(normpdf([9.4:0.01:10.8],10.132281747288358,0.135));
plot([9.4:0.01:10.8],nrm,'-')
hold on 
plot(x,y,'k-')