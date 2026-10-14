

%find optimum cut-measure cut strategy for 3D example 1
clear all
close all
clc
global fvalhist cutshist fvalhist2 cutshist2
time1 = tic;
flag = 0
%cuts = [6.3503,6.3350,6.3228,5.5105,5.5151,5.5188];
%cuts = [6.3696,6.3009,6.3724,5.5048,5.5254,5.5038];
cuts = [6 6 6 5 5 5];
options = optimset('Display','iter','MaxFunEvals',100,'OutputFcn', @outfun );
[x1 fval1] = fminsearch('Opt_Reverse_CMC_3d_Example1',cuts,options)
RunTime = toc(time1)

% means = [5 5 5]
% options = optimset('Display','iter','MaxFunEvals',10,'OutputFcn', @outfun2 );
% [x fval] = fminsearch('Opt_NORM_3d_Example1',means,options)



% 3D plot just changing cut 1 2 and 3
u = linspace(5.5,7.5,5);
[x,y,z] = meshgrid(u);
time2 = tic;
for i = 1:length(u)
    for j = 1:length(u)
        for k = 1:length(u)
            cuts = [x(j,i,k),y(j,i,k),z(j,i,k),5,5,5];
            [Prt_Total(j,i,k) Prt_Rwork(j,i,k)] = Opt_Reverse_CMC_3d_Example1(cuts);
        end
    end
end

% Plot 3D slice plot
if flag > 0
figure;
xslice = 6.5;
yslice =7.0;
zslice = 6;
slice(x,y,z,Prt_Total,xslice,yslice,zslice)
view(3);
xlabel('Cut1 dim x'); ylabel('Cut1 dim y'); zlabel('Cut1 dim z')
axis on; grid on;
colormap (jet(64)); colorbar('vertical');
%light; lighting flat; camlight('left'); 
shading interp;
alpha 0.7
axis square
h = colorbar;
ylabel(h, 'Production Cost');
toc(time2)
end