clear all
%close all
clc
%% Constants
N = 150;
B = 0.002;

%%
mu_R = 24.95;
mu_L = 35.11;
tolR = 0.8;
tolL = 1.0;

%% Calculate the flow output in the tolerance range selected 
TolR_Range = linspace(-1*tolR,tolR,50);
TolL_Range = linspace(-1*tolL,tolL,50);
R_vec = mu_R + TolR_Range;
L_vec = mu_L + TolL_Range;
for i = 1:length(TolR_Range)
    R = R_vec(i);
    for j = 1:length(TolL_Range)
        L = L_vec(j);
        actflow(j,i) = ( pi()*R*R*L/1E6 - B)*N;
    end
end

[RR LL] = meshgrid(R_vec,L_vec);

% figure(2)
% subplot(1,2,2)
% contourf(LL,RR,actflow,50)
% colorbar
% c=colorbar;
% ylabel(c,'Actflow (ltrs/min)')
% title('ActFlow output on nominal L and R within specified tols') 
% xlabel('L')
% ylabel('R')

%% This bigger picture %%
R_vec = linspace(20,60,50);
L_vec = linspace(20,60,50);
for i = 1:length(R_vec)
    R = R_vec(i);
    for j = 1:length(L_vec)
        L = L_vec(j);
        actflow(j,i) = ( pi()*R*R*L/1E6 - B)*N;
    end
end
Max_L = 24.9162;
Max_R = 29.6089;
[RR LL] = meshgrid(R_vec,L_vec);
figure(2)
contourf(LL,RR,actflow,50)
colorbar
c=colorbar;
ylabel(c,'Actflow') 
%title('ActFlow output vs. L and R showing upper and lower performance bounds and tolerance box')
xlabel('L')
ylabel('R')
hold on
plot(Max_L,Max_R,'g.','MarkerSize',18)
line([Max_L-tolL Max_L-tolL],[Max_R-tolR Max_R+tolR],'Color','r','LineWidth',1)
line([Max_L-tolL Max_L+tolL],[Max_R+tolR Max_R+tolR],'Color','r','LineWidth',1)
line([Max_L+tolL Max_L+tolL],[Max_R+tolR Max_R-tolR],'Color','r','LineWidth',1)
line([Max_L+tolL Max_L-tolL],[Max_R-tolR Max_R-tolR],'Color','r','LineWidth',1)
hold on
contour(LL,RR,actflow,[9,11],'Color','w')
text(30,30,'USL','color',[1 1 1])
text(25,25,'LSL','color',[1 1 1 ])