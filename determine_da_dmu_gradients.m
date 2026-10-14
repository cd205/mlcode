% mfile to find the gradients of de/dmu 's to determine the mu value at 
% which the lower bounds and upper bound errors are equal 

close all
clear all
clc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find de/dmu grad for 3D problem with sigma1 = 1
%                                      sigma2 = 1
%                                      sigma3 = 1
MU = linspace(2.5,3.5,5)
for i = 1:length(MU)
    P(i) = (1-normcdf(3,MU(i),1))/12.5988807;
end
Grad = gradient(P,[MU(2)-MU(1)])
g = polyfit(MU,P,1)
figure(1)
plot(MU,P,'.-')
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % find de/dmu grad for 3D problem with sigma1 = 1
% %                                      sigma2 = 0.6
% %                                      sigma3 = 0.4
% for i = 1:length(MU)
%     P(i) = (1-normcdf(3,MU(i),1))/27.228589
% end
% figure(2)
% plot(MU,P,'.-')
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % find de/dmu grad for 4D problem with sigma1 = 1
% %                                      sigma2 = 1
% %                                      sigma3 = 1
% %                                      sigma4 = 1
% for i = 1:length(MU)
%     P(i) = (1-normcdf(3,MU(i),1))/118.8684362
% end
% figure(3)
% plot(MU,P,'r.-')
% 
% for i = 1:length(MU)
%     P(i) = (1-normcdf(3,MU(i),1))/18.8845942
% end
% figure(4)
% plot(MU,P,'g.-')