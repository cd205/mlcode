% outer and inner diameters and thickness distribution calculations

clear all
close all
clc
sig11 = 0.5;
sig22 = 2;
mu1 = 10
mu2 = 5
tlim = 4.8
xvec = linspace(-20,20,5000);
yvec = xvec;
z = xvec+yvec;
f_do = normpdf(xvec,mu1,sig11);
%f_di = normpdf(xvec,mu2,sig22);
f_di = Fun_TruncatedNormalDist_pdf(yvec,mu2,sig22,0,7,7,0);

%funz = @(z) (1/(sqrt(2*pi*(sig11^2+sig22^2))))*exp(-(z-(mu1-mu2)).^2./(2*(sig11^2+sig22^2)));
% see http://en.wikipedia.org/wiki/Sum_of_normally_distributed_random_variables
flag = mu1>mu2 % check is mu1>mu2 as this determins which equation to use
               % in 'Fun_Conv_NormTrun_neg'
% funz is the shape of the thickness distribution
funz = @(z) Fun_Conv_NormTrun_neg([mu1 mu2],[sig11 sig22],0,7,z,flag)


figure;
plot(xvec,f_do,'-'); hold on; grid on
plot(xvec,f_di,'r-'); hold on
plot(z,funz(z),'g-')
xlabel('outer and inner diameters and thickness')

Q_ge_tlim = integral(funz,tlim,inf) % proportion of thickness that is too thick

% Truncated normal dist function
f_di_fun = @(v) Fun_TruncatedNormalDist_pdf(v,mu2+tlim,sig22,0+tlim,7+tlim,7+tlim,0);
f_di_fun2 = @(y) Fun_TruncatedNormalDist_pdf(y,mu2,sig22,0,7,7,0);
f_di_o_fun =@ (w) Fun_TruncatedNormalDist_pdf(w,mu2,sig22,0,7,7,0).*(1-normcdf(w,mu1-tlim,sig11));
% CDF of truncated normal dist.  recall that E(X|X>Y+tlim) is
% f_X(x)*Pr{Y<x} where Pr{Y<x} = F_Y(x)
TruncCDF_fun = @(vv) integral(f_di_fun,-inf,vv)


% The outerdiameter distribution of those that lead to too large
% thicknesses, i.e. the outer diameters that are reworked. 
%pdfc =  normpdf(xvec,mu1,sig11).*(normcdf(xvec,mu2+tlim,sig22));
for i = 1:length(xvec)
    f_do_o(i) =  normpdf(xvec(i),mu1,sig11).*TruncCDF_fun(xvec(i));
    f_di_o(i) = f_di_o_fun(yvec(i));
end
% mean of di_over (di_o')
Q_f_di_o = integral(f_di_o_fun,-inf,inf)
int_f_di_o_fun = @(Y) integral(f_di_o_fun,-inf,Y)/Q_f_di_o - 0.5
mean_di_o = fsolve(int_f_di_o_fun,mu2)

figure;
plot(xvec,f_do_o,'r-');  grid on;  hold on
plot(yvec,f_di_o,'c-'); hold on
line([mean_di_o, mean_di_o],[0 max(f_di_o)],'Color',[0 0 0])
xlabel('do over adn di over')
[val pos] = max(f_do_o);
MeanPDFC = xvec(pos)  % mean value of 'do's' that lead to 't>tlim'
Qint=trapz(xvec,f_do_o) % proportion of 'do's' that lead to 't>tlim'
% This is the distribution 'do' (outer diameters) that lead to conforming thicknesses
f_do_OK = f_do-f_do_o; 

%% Numerical convolution 
xvec_s  = linspace(-10,10,2500)
T_fun = @(T) normpdf(T,mu1-mu2,sig11);
do_n = conv(f_di_o_fun(xvec_s),T_fun(xvec_s))*(xvec_s(2)-xvec_s(1));
fsdghjsdfghjdfsghj = length(do_n)
do_n = do_n(1:2:end);
fsdghjsdfghjdfsghj = length(do_n)
%%
% Plot the ok diameters and original diameters on same plot as the over
% diameters 
plot(xvec,f_do_OK,'g'); hold on
plot(xvec,f_do,'-'); hold on


% reworked outer diameters mean must be mu_do = mu_t + mu_di with sig11
% variation 
% reworked diameters assuming you know the di diameters
% f_do_n = 'thicktarget' + 'inner dia. giving t>tlim' + 'random variation'
tt = mu1-mu2; % thickness target
f_di_fun3 = @(y) Fun_TruncatedNormalDist_pdf(y,mu2+tt,sig22,0+tt,7+tt,7+tt,0)...
    *(1-normcdf(y,tt+mu1-tlim,sig11));
for i = 1:length(xvec)
    f_do_n(i) = f_di_fun3(yvec(i));%+f_do_OK(i) ;
    f_do_n2(i) = f_di_fun3(yvec(i))+f_do_OK(i);
end

for i  = 1:length(xvec)/2
    if i == 1
        do_n_final(i) = do_n(i)+ f_do_OK(i+1);
    else
        do_n_final(i) = do_n(i)+ f_do_OK(i*2);
    end
end

vec = linspace(0,15,2500);
figure;
plot(xvec,f_do_n); grid on; hold on
plot(xvec_s*2,do_n,'m-'); grid on; hold on
plot(xvec,f_do_n2,'r'); grid on; hold on
plot(xvec_s*2,do_n_final,'c'); hold on
xlabel('do_{n_final}')
plot(xvec,f_do_OK,'k')

%% numercal
% pts = 1e6;
% X = mu1+(randn(pts,1)*(sig11));
% %Y = mu2+(randn(pts,1)*(sig22));
% Y = num_TruncNorm(mu2,7,0,pts,sig22);
% Z=X-Y;
% figure;
% hist(X,80); grid on
% xlabel('Normal')
% figure;
% hist(Y,80); grid on
% xlabel('Truncated')
% figure;
% hist(Z,80); grid on
% xlabel('Initial Thickness')
% [thick,xthick] = ksdensity(Z,'npoints',1000);
% figure;
% plot(xthick,thick); hold on; grid on
% plot(z,funz(z),'g-')
% [f1,xf1] = ksdensity(X,'npoints',1000);
% figure;
% plot(xf1,f1); hold on; grid on
% plot(xvec,f_do,'g-')
% trapz(xf1,f1)
% trapz(xvec,f_do)
% [f2,yf2] = ksdensity(Y,'npoints',1000);
% figure;
% plot(yf2,f2); hold on; grid on
% plot(yvec,f_di,'g-')
% trapz(yf2,f2)
% trapz(yvec,f_di)


% posZ = find(Z>tlim);
% 
% [f3,yf3] = ksdensity(Y(posZ),'npoints',1000);
% plot(yf3,f3.*length(posZ)/pts,'k-')


%totalover = length(posZ)/pts % proportion of 'do's' lead to 't>tlim'
%Mean_X_over = mean(X(posZ))  
%figure; hist(X(posZ),100); grid on; hold on

%hist(Y(pos),100); grid on
%xlabel('di over')

%[f,x] = ksdensity(X(posZ),'function','pdf','npoints',1000);
%trapz(x,f)
%fFun = @(xi) interp1(x,f,xi,'spline') - 0.5

%Mu_x = fsolve(fFun,MeanPDFC) % mean value of 'do's' that lead to 't>tlim' 
%figure;
%plot(x,f,'.'); grid on; hold on
%line([Mu_x Mu_x],[0,0.5],'Color',[1 0 0])
%plot(xvec,pdfc*(1/Qint),'r-')
%xlim([-4 6])
%line([MeanPDFC MeanPDFC],[0,0.5],'Color',[0 1 0.4])


