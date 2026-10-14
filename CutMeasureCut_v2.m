
clear all
clc
close all

InitialBatch = 100000
nom = 5
sigma = 1
USL = 7
LSL = 3
depth1 = USL;

%% First cut - aim for USL
Cut1 = normrnd(depth1,sigma,InitialBatch,1);
bins = [0:0.5:12];
hist(Cut1,bins)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on
% Check what conforms and create 'Sample2' of parts that require a second 
% cut 
InSpec = 0;
c1 = 1;
c2 = 1;
for i = 1:length(Cut1)
    if Cut1(i)<=USL
        InSpec(c1) = Cut1(i);
        c1 = c1+1;
    else
        Sample2(c2) = Cut1(i);
        c2 = c2+1;
    end
end
length(InSpec)
length(Sample2)

%% Second cut - aim for nominal 
Cut2 = normrnd(nom,sigma,length(Sample2),1);
bins = [0:0.5:12];
figure(2)
hist(Cut2,bins)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on

x = [InSpec, Cut2'];

figure(3)
hist(x,bins)
xlabel('Dimension')
ylabel('Number of samples')
line([7 7],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
line([3 3],[0 InitialBatch/8],'color',[1 0 0],'LineWidth',2,'LineStyle','--')
grid on

