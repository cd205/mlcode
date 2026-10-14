% generate a triavariate cut-meausre-cut model using copulas
close all
clear all
clc
cut1 = 6;
cut2 = 5;
sigma1 = 0.8;
sigma2 = 0.8;
sigma3 = 0.8;
LSL = 3;
USL = 7;
num = 100

 %with Gaussian copula

p = [1 0 0; 0 1 0; 0 0 1]; % parameter of Gaussian copula

u=linspace(0,10,num); % 1000 equidistant numbers

[x,y,z]=meshgrid(u); % create the grid (the points) on which the functions are evaluated

a = normpdf(x,5,sigma1); % compute standard normal pdf values for x
b = Fun_Cut_Measure_Cut_Dist(y,cut1,cut2,sigma1,sigma2,LSL,USL);
c = normpdf(z,4.9,sigma3);
for i = 1:length(z)
    zp(i) = z(1,1,i);  % Take 1D elements of 3D array.  z(1,1,:) is not 1D
    cp(i) = c(1,1,i);  % Take 1D elements of 3D array for c
end
figure(1)
subplot(1,2,1)
plot(x(1,:,1),a(1,:,1));hold on
plot(y(:,1,1),b(:,1,1),'r'); hold on
plot(zp,cp,'m');grid on
line([LSL LSL],[0 max(max(max(b)))])
line([USL USL],[0 max(max(max(b)))])
u = normcdf(x,5,1); % compute standard normal cdf values for x
%v = normcdf(y,3,0.7); % compute t3 cdf values for y
for i = 1:length(u)
    for j = 1:length(u)
        v(:,j,i) = cumtrapz(y(:,j,i),b(:,j,i));
    end
end
w = ones(length(u),length(u),length(u)); % 3D matric of ones
for j = 1:length(u)
    wp = cumtrapz(zp,cp)';
    w(:,:,j) = wp(j).*w(:,:,j);
end


figure(1)
subplot(1,2,2)
plot(x(1,:,1),u(1,:,1));hold on
plot(y(:,1,1),v(:,1,1),'r'); hold on
plot(zp,wp,'m');grid on ; hold on
f = copulapdf('Gaussian',[u(:),v(:),w(:)],p); %compute the pdf of gaussian copula
mvd = reshape(f,num,num,num).*a.*b.*c; % create multivariate density from the product
% of the copula pdf and the marginal pdfs
% reshape f to avoid matrix
% dimension conflicts
s1 = tic
for i = 1:10000
fp = copulacdf('Gaussian',[0.9,0.9,0.7],p);
end
fp
toc(s1)/i
%% Integrate the volumes (cubes)
% fun = @(Xi,Yi,Zi) interp3(x,y,z,mvd,Xi,Yi,Zi)
% Fa1a2a3 = triplequad(fun,0,LSL,0,LSL,0,LSL)
% Fa1a2b3 = triplequad(fun,0,LSL,0,LSL,0,USL)
% Fa1b2a3 = triplequad(fun,0,LSL,0,USL,0,LSL)
% Fa1b2b3 = triplequad(fun,0,LSL,0,USL,0,USL)
% Fb1a2a3 = triplequad(fun,0,USL,0,LSL,0,LSL)
% Fb1a2b3 = triplequad(fun,0,USL,0,LSL,0,USL)
% Fb1b2a3 = triplequad(fun,0,USL,0,USL,0,LSL)
% Fb1b2b3 = triplequad(fun,0,USL,0,USL,0,USL)