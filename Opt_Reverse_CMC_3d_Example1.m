%function [Prt_Total_Cost Prt_Rwork_Cost] = Opt_Reverse_CMC_3d_Example1(cuts)
 clear all
% close all
 clc
flag = 1;
%cuts = [6.3696,6.3009,6.3724,5.5048,5.5254,5.5038];
cuts = [7 7 7 6 6 5];
CUT1 = [cuts(1) cuts(2) cuts(3)];
CUT2 = [cuts(4) cuts(5) cuts(6)];
sig11a = 1;
sig11b = sig11a;
sig22a = 1;
sig22b = sig22a;
sig33a = 1;
sig33b = sig33a;
% sigma1_D = [1 1 1];
% sigma2_D = [1 1 1];
A = [3 3 3];
B = [7 7 7];
range = [0 10]; 
num = length(A);
Lower = 0; % lower bound to integrate from
pnts = 30
%% Compute the cut-measure-cut distributions and the CDF
%p = [1 0.7 0.5; 0.7 1 0.4; 0.5 0.4 1] % parameter of Gaussian copula
p = [1 0.0 0; 0.0 1 0; 0 0 1];
u=linspace(range(1),range(2),pnts); % 1000 equidistant numbers

[x,y,z]=meshgrid(u); % create the grid (the points) on which the functions are evaluated
zp = squeeze(z(1,1,:))';  % Take 1D elements of 3D array.  z(1,1,:) is not 1D 

[a a_RW a_SCP] = Fun_Reverse_Cut_Measure_Cut_pdf(x(1,:,1),CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)); % compute standard normal pdf values for x
a = repmat(a,[length(u),1,length(u)]);
[b b_RW b_SCP] = Fun_Reverse_Cut_Measure_Cut_pdf(y(:,1,1),CUT1(2),CUT2(2),sig22a,sig22b,A(2),B(2));
b = repmat(b',[1,length(u),length(u)]);
[cp c_RW c_SCP] = Fun_Reverse_Cut_Measure_Cut_pdf(zp,CUT1(3),CUT2(3),sig33a,sig33b,A(3),B(3));
for j = 1:length(u)
   c(:,:,j) = repmat(cp(j),[length(u),length(u),1]);
end
% a_RW, b_RW and c_RW are the rework rates from the first cut
CUT1_RWork = [a_RW,b_RW,c_RW];
CUT1_Scrap = [a_SCP b_SCP c_SCP];


cp = squeeze(c(1,1,:))';  % Take 1D elements of 3D array for c


if flag > 0
    figure(1)
    subplot(1,2,1)
    plot(x(1,:,1),a(1,:,1));hold on
    plot(y(:,1,1),b(:,1,1),'r'); hold on
    plot(zp,cp,'m');grid on
    line([A(1) A(1)],[0 max(max(max(b)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--');
    line([B(1) B(1)],[0 max(max(max(b)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--');
    xlabel('x_{1,2,3}')
    ylabel('Probability Density')
end
% CDF for x
for i = 1:length(x(1,:,1))
    u(i) = quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,x(1,i,1));
end
u = repmat(u,[length(u),1,length(u)]); % repeat these columns across the 3D matrix
% CDF for y
for i = 1:length(x(1,:,1))
    v(i) = quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,y(i,1,1));
end
v = repmat(v',[1,length(u),length(u)]); % repeat these columns across the 3D matrix
% CDF for z
for i = 1:length(x(1,:,1))
    wp(i) = quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,zp(i));
end
for j = 1:length(u)
   w(:,:,j) = repmat(wp(j),[length(u),length(u),1]);
end


if flag > 0
    figure(1)
    subplot(1,2,2)
    plot(x(1,:,1),u(1,:,1));hold on
    plot(y(:,1,1),v(:,1,1),'r'); hold on; grid on
    plot(zp,wp,'m'); grid on
    line([A(1) A(1)],[0 max(max(max(u)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--');
    line([B(1) B(1)],[0 max(max(max(u)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--');
    xlabel('x_{1,2,3}')
    ylabel('Cumulative Density')
end



Fa1a2a3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,A(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,A(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,A(3))],p);
Fa1a2b3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,A(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,A(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,B(3))],p);
Fa1b2a3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,A(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,B(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,A(3))],p);
Fa1b2b3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,A(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,B(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,B(3))],p);
Fb1a2a3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,B(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,A(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,A(3))],p);
Fb1a2b3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,B(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,A(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,B(3))],p);
Fb1b2a3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,B(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,B(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,A(3))],p);
Fb1b2b3 = copulacdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),0,B(1)),...
    quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),0,B(2)),...
    quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),0,B(3))],p);

s1 = struct('Fa1a2a3',Fa1a2a3,...
           'Fa1a2b3',Fa1a2b3,'Fa1b2a3',Fa1b2a3,'Fb1a2a3',Fb1a2a3,...
           'Fa1b2b3',Fa1b2b3,'Fb1a2b3',Fb1a2b3,'Fb1b2a3',Fb1b2a3,...
           'Fb1b2b3',Fb1b2b3)
       
df = copulapdf('Gaussian',[u(:),v(:),w(:)],p);
MVDF = reshape(df,pnts,pnts,pnts).*a.*b.*c
%% Plot MVDF
figure(2)
xslice = 3.5;
yslice = 3.5;
zslice = 3.5;
slice(x,y,z,MVDF,xslice,yslice,zslice)
view(3);
xlabel('Cut1 dim x'); ylabel('Cut1 dim y'); zlabel('Cut1 dim z')
axis on; grid on;
colormap (jet(64)); colorbar('vertical');
%light; lighting flat; camlight('left'); 
shading interp;
alpha 0.7
axis square
h = colorbar;
ylabel(h, 'Probability Density');
         
% Conformance
ConformPrt = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
          + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3   
% Scrap
ScrapPrt = 1 - Fb1b2b3
% Rework 
RworkPrt = Fb1b2b3 - ConformPrt

      
%% Markov Chain to correct conformance and scrap amounts from reworked items

m11 = 1/(1-RworkPrt)
f12 = ConformPrt/(1-RworkPrt)
f13 = ScrapPrt/(1-RworkPrt)

%% Cost model
[Prt_Cost Prt_Rwork_Cost Prt_Scrap_Cost Prt_Total_Cost] =...
    CostModel_CMC_Example1(a_RW,b_RW,c_RW,m11,f13)
