% simulate the cutting of an outer diameters (do) with mean 'mu1' and
% variation 'sig11'.  Given an inner diameter 'di' with variance 'sig22'
% determine the thickness 't'.  If the thickness values are above a certain
% limit 'tlim' find the relevent 'do' values that can be reworked to try to
% get the 't' values under 'tlim'. 

% The function 'funz' is the thickness variation 't = do-di', determined 
% by the  a convolution of do-di. 'pdfc' is f_X(x)*Pr{Y+tlim<x} which is 
% the solution to Pr{X|X>Y+tlim}.

% We are after the mean and distribution of the 'do' values that caused
% t>tlim.  Note this will be a distribution small than 'do'.

clear all
close all
clc
sig11 = 0.8;
sig22 = 2;
mu1 = 9
mu2 = 5
tlim = 4
xvec = linspace(-20,20,50000);
yvec = xvec;
z = xvec+yvec;
f_do = normpdf(xvec,mu1,sig11);
f_di = normpdf(xvec,mu2,sig22);

funz = @(z) (1/(sqrt(2*pi*(sig11^2+sig22^2))))*exp(-(z-(mu1-mu2)).^2./(2*(sig11^2+sig22^2)));
% see http://en.wikipedia.org/wiki/Sum_of_normally_distributed_random_variables

figure;
plot(xvec,f_do,'-'); hold on; grid on
plot(xvec,f_di,'r-'); hold on
plot(z,funz(z),'m-')

Q_ge4 = integral(funz,tlim,inf)

% for i = 1:length(z)
%     CDF_funz(i) = integral(funz,-inf,z(i));
% end
% 
% 
% figure;
% plot(z,CDF_funz,'.-'); grid on
% xlabel('z'); ylabel('Cumulative Density')



pdfc =  normpdf(xvec,mu1,sig11).*(normcdf(xvec,mu2+tlim,sig22));
figure;
plot(xvec,pdfc,'r-');  grid on; 
%xlim([-4 6])
[val pos] = max(pdfc)
MeanPDFC = xvec(pos)  % mean value of 'do's' that lead to 't>tlim'
Qint=trapz(xvec,pdfc) % proportion of 'do's' that lead to 't>tlim'


pts = 1e6;
X = mu1+(randn(pts,1)*(sig11));
Y = mu2+(randn(pts,1)*(sig22));
Z=X-Y;
posZ = find(Z>tlim);
totalover = length(posZ)/pts % proportion of 'do's' lead to 't>tlim'
Mean_X_over = mean(X(posZ))  
figure; hist(X(posZ),100); grid on; hold on
line([Mean_X_over Mean_X_over],[0,0.5e5],'Color',[1 0 0])

[f,x] = ksdensity(X(posZ),'function','pdf','npoints',1000);
trapz(x,f)
fFun = @(xi) interp1(x,f,xi,'spline') - 0.5

Mu_x = fsolve(fFun,MeanPDFC) % mean value of 'do's' that lead to 't>tlim' 
figure;
plot(x,f,'.'); grid on; hold on
line([Mu_x Mu_x],[0,0.5],'Color',[1 0 0])
plot(xvec,pdfc*(1/Qint),'r-')
%xlim([-4 6])
line([MeanPDFC MeanPDFC],[0,0.5],'Color',[0 1 0.4])

