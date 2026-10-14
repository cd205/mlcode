% Study 3D conformance problem iwth Cut-measure-cut distributions

% This file can deal with 1 D correlation corr13,31 for cut-measure-cut
% distributions and involves 5 evaluations of the CDF
tic
clear all
close all
clc

CUT1 = [8 6 5];
CUT2 = [6 5.5 3];
sigma_cut = [1 1 1];  % cut-measure-cut sigma
A = [3 3 3];
B = [8 8 8];
sigma11 = sigma_cut(1);        % Guassian copual sigma
sigma22 = sigma_cut(2);
sigma33 = sigma_cut(3);
sigma12 = 0.0;
sigma13 = 0.6;
sigma21 = 0.0;
sigma23 = 0.0;
sigma31 = 0.6; 
sigma32 = 0.0;
range = [0 10] 
num = length(A);
Lower = 0; % lower bound to integrate from
pnts = 1000000;

%% Compute the cut-measure-cut distributions and the CDF
p = [sigma11^2 sigma12^2 sigma13^2;...
     sigma21^2 sigma22^2 sigma23^2;...
     sigma31^2 sigma32^2 sigma33^2]; % parameter of Gaussian copula
 
x = linspace(range(1),range(2),pnts);
y = linspace(range(1),range(2),pnts);
z = linspace(range(1),range(2),pnts);

[a a_RW] = Fun_Cut_Measure_Cut_Dist(x,CUT1(1),CUT2(1),sigma_cut(1),sigma_cut(1),A(1),B(1)); % compute standard normal pdf values for x
[b b_RW] = Fun_Cut_Measure_Cut_Dist(y,CUT1(2),CUT2(2),sigma_cut(2),sigma_cut(2),A(2),B(2));
[c c_RW] = Fun_Cut_Measure_Cut_Dist(z,CUT1(3),CUT2(3),sigma_cut(3),sigma_cut(3),A(3),B(3));
% a_RW, b_RW and c_RW are the rework rates from the first cut
CUT1_RWork = [a_RW,b_RW,c_RW];

figure(1)
subplot(1,2,1)
plot(x,a);hold on
plot(y,b,'r'); hold on
plot(z,c,'m');grid on
line([A(1) A(1)],[0 max(max(max(b)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--');
line([B(1) B(1)],[0 max(max(max(b)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--');
xlabel('x_{1,2,3}')
ylabel('Probability Density')

% Cumultative Probability curves 
u = cumtrapz(x,a);
v = cumtrapz(y,b);
w = cumtrapz(z,c);

figure(1)
subplot(1,2,2)
plot(x,u);hold on
plot(y,v,'r'); hold on
plot(z,w,'m');grid on
line([A(1) A(1)],[0 max(max(max(v)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--');
line([B(1) B(1)],[0 max(max(max(v)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--');
xlabel('x_{1,2,3}')
ylabel('Cumulative Density')

mu1fun = @(x1) interp1(x,u,x1)-0.5;
mu2fun = @(y1) interp1(y,v,y1)-0.5;
mu3fun = @(z1) interp1(z,w,z1)-0.5;
mu1 = fzero(mu1fun,CUT2(1))
mu2 = fzero(mu2fun,CUT2(2))
mu3 = fzero(mu3fun,CUT2(3))


a1 = find(x<=A(1));
a2 = find(y<=A(2));
a3 = find(z<=A(3));
b1 = find(x>=B(1));
b2 = find(y>=B(2));
b3 = find(z>=B(3));

Fa1a2a3Alt = (interp1(x,u,A(1),'spline')*interp1(y,v,A(2),'spline')*...
    interp1(z,w,A(3),'spline'))
timing2 = tic;
Fa1a2a3 = copulacdf('Gaussian',[u(a1(end)),v(a2(end)),w(a3(end))],p);
Fa1a2b3 = copulacdf('Gaussian',[u(a1(end)),v(a2(end)),w(b3(1))],p);
Fa1b2a3 = copulacdf('Gaussian',[u(a1(end)),v(b2(1)),w(a3(end))],p);
Fa1b2b3 = copulacdf('Gaussian',[u(a1(end)),v(b2(1)),w(b3(1))],p);
Fb1a2a3 = copulacdf('Gaussian',[u(b1(1)),v(a2(end)),w(a3(end))],p);
Fb1a2b3 = copulacdf('Gaussian',[u(b1(1)),v(a2(end)),w(b3(1))],p);
Fb1b2a3 = copulacdf('Gaussian',[u(b1(1)),v(b2(1)),w(a3(end))],p);
Fb1b2b3 = copulacdf('Gaussian',[u(b1(1)),v(b2(1)),w(b3(1))],p);
time2 = toc(timing2)
toc
s = struct('Fa1a2a3',Fa1a2a3,'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,...
    'Fa1b2b3',Fa1b2b3,'Fb1a2a3',Fb1a2a3,'Fb1a2b3',Fb1a2b3,'Fb1b2a3',Fb1b2a3,...
    'Fb1b2b3',Fb1b2b3)

Conform = Fb1b2b3 - Fb1b2a3 - Fb1a2b3 - Fa1b2b3 + Fb1a2a3 + Fa1b2a3 + Fa1a2b3 - Fa1a2a3
U = Fa1a2a3 + Fa1a2b3 + Fa1b2a3 + Fb1a2a3;
LB = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3)
if LB < 0
    LB = 0
end
UB = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3])
Abox = Fa1b2b3 + Fb1a2b3
TwoB = 2*(Fa1a2b3 + Fa1b2a3 + Fb1a2a3 - Fa1a2a3) ;
a_box = Fa1a2b3 - Fa1a2a3;
b_box = Fb1a2a3 + Fa1b2a3;
Bottom_A_Layer = Fb1a2a3 + Fa1b2a3
Top_A_Layer = Fa1b2b3-Fa1b2a3 + Fb1a2b3-Fb1a2a3


figure(3)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(Conform,0,'b.','MarkerSize',30); grid on

LBerror = Conform - LB
UBerror = UB - Conform

%% Double accuracy method for LB>0
% 'DetlaFa1a2a3' determines how much larger the Fa1a2a3 box is with
% correlation
DetlaFa1a2a3 = Fa1a2a3/...
    (interp1(x,u,A(1),'spline')*interp1(y,v,A(2),'spline')*...
    interp1(z,w,A(3),'spline'))
% 'D2_D1' is the ratio of CDF up to the LSL of distributions 2 and 1.  
% This determines how much larger/smaller 'Fb1a2a3' is than 'Fa1b2a3' 
% which is used in 'Abox_Lower'.  When 'Fb1a2a3' and 'Fa1b2a3' are equal
% the last term in 'Abox_Lower' is '(DetlaFa1a2a3-1)/2'
D2_D1 = interp1(y,v,A(2))/interp1(x,u,A(1))
if DetlaFa1a2a3 > 1
    disp('Correlation makes difference to Fa1a2a3')
    % if correlations is present and makes a difference to the size of
    % Fa1a2a3 do the following:
    Abox_Lower = (1 + (DetlaFa1a2a3-1)/(1+D2_D1))*((Fa1b2b3+Fb1a2b3)/interp1(z,w,A(3),'spline')^-1)
    B = Abox_Lower + (((Fa1a2a3/interp1(z,w,A(3),'spline'))*DetlaFa1a2a3^-1)-Fa1a2a3);
elseif DetlaFa1a2a3 <= 1
    disp('No correlation')
    % if there is no correlation and Fa1a2a3 does not change size do this:
    B = Abox*(interp1(z,w,A(3),'spline')) + (((Fa1a2a3/interp1(z,w,A(3),'spline')))-Fa1a2a3);
end
% Determin which error is smaller thaus which bound is closest
if LB>0
    if 2*B > Abox
        disp('Between UB and Middle')
        figure(3)
        plot((UB-LB)/2+LB,0,'c*','MarkerSize',20); hold on
        plot(UB,0,'m*','MarkerSize',20);
    elseif 2*B < Abox
        disp('Between LB and Middle')
        figure(3)
        plot(LB,0,'c*','MarkerSize',20); hold on
        plot((UB-LB)/2+LB,0,'m*','MarkerSize',20);
    end
end