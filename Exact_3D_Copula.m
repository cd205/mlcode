
clear all
close all
clc

CUT1 = [3 3 3];
CUT2 = [3 3 3];
sigma1_D = [1 1 1];
sigma2_D = [1 1 1];
A = [3 3 3];
B = [7 7 7];
range = [0 10] 
num = length(A);
Lower = 0; % lower bound to integrate from
pnts = 100;

%% Compute the cut-measure-cut distributions and the CDF
p = [1 0 0; 0 1 0; 0 0 1]; % parameter of Gaussian copula

u=linspace(range(1),range(2),pnts); % 1000 equidistant numbers

[x,y,z]=meshgrid(u); % create the grid (the points) on which the functions are evaluated

[a a_RW] = Fun_Cut_Measure_Cut_Dist(x,CUT1(1),CUT2(1),sigma1_D(1),sigma2_D(1),A(1),B(1)); % compute standard normal pdf values for x
[b b_RW] = Fun_Cut_Measure_Cut_Dist(y,CUT1(2),CUT2(2),sigma1_D(2),sigma2_D(2),A(2),B(2));
[c c_RW] = Fun_Cut_Measure_Cut_Dist(z,CUT1(3),CUT2(3),sigma1_D(3),sigma2_D(3),A(3),B(3));
% a_RW, b_RW and c_RW are the rework rates from the first cut
CUT1_RWork = [a_RW,b_RW,c_RW];
for i = 1:length(z)
    zp(i) = z(1,1,i);  % Take 1D elements of 3D array.  z(1,1,:) is not 1D
    cp(i) = c(1,1,i);  % Take 1D elements of 3D array for c
end

%u = normcdf(x,5,1); % compute standard normal cdf values for x
for i = 1:length(u)
    for j = 1:length(u)
        u(j,:,i) = cumtrapz(x(j,:,i),a(j,:,i));
    end
end
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


% for i = 1:length(B)       % define h.b 
%     temp1 = [Lower,B(i)];
%     limits(i,:) = [temp1];
%     unit_limits(i,:) = limits(i,:)./(range(2)-range(1));
%     clear temp1
% end

a1 = find(x(1,:,1)<=A(1));
a2 = find(y(:,1,1)<=A(2));
a3 = find(zp<=A(3));
b1 = find(x(1,:,1)>=B(1));
b2 = find(y(:,1,1)>=B(2));
b3 = find(zp>=B(3));
ExactTime = tic;
Fa1a2a3 = copulacdf('Gaussian',[u(1,a1(end),1),v(a2(end),1,1),w(1,1,a3(end))],p);
Fa1a2b3 = copulacdf('Gaussian',[u(1,a1(end),1),v(a2(end),1,1),w(1,1,b3(1))],p);
Fa1b2a3 = copulacdf('Gaussian',[u(1,a1(end),1),v(b2(1),1,1),w(1,1,a3(end))],p);
Fa1b2b3 = copulacdf('Gaussian',[u(1,a1(end),1),v(b2(1),1,1),w(1,1,b3(1))],p);
Fb1a2a3 = copulacdf('Gaussian',[u(1,b1(1),1),v(a2(end),1,1),w(1,1,a3(end))],p);
Fb1a2b3 = copulacdf('Gaussian',[u(1,b1(1),1),v(a2(end),1,1),w(1,1,b3(1))],p);
Fb1b2a3 = copulacdf('Gaussian',[u(1,b1(1),1),v(b2(1),1,1),w(1,1,a3(end))],p);
Fb1b2b3 = copulacdf('Gaussian',[u(1,b1(1),1),v(b2(1),1,1),w(1,1,b3(1))],p);

Run_Time = toc(ExactTime)

s = struct('Fa1a2a3',Fa1a2a3,'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,...
    'Fa1b2b3',Fa1b2b3,'Fb1a2a3',Fb1a2a3,'Fb1a2b3',Fb1a2b3,'Fb1b2a3',Fb1b2a3,...
    'Fb1b2b3',Fb1b2b3)

Conform = Fb1b2b3 - Fb1b2a3 - Fb1a2b3 - Fa1b2b3 + Fb1a2a3 + Fa1b2a3 + Fa1a2b3 - Fa1a2a3
FinalRework = 1 - Conform
Scrap = Fb1b2b3 - Conform