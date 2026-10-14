% D1_D2_T1_T2 surface plotting
clear all
close all
clc
MyNumber = 5
num = 20
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%% Vary D1 and D2 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch MyNumber
case 1
D3 = 1.35
D4 = 2.35
D1 = linspace(1.,5.0,num);
D2 = linspace(3.,9,num);
for i = 1:length(D1)
    for j = 1:length(D2)
        MU_0 = [D1(i), D2(j), D3, D4];
        OBJ(j,i) = Fun_D1_D2_T1_T2_Cost(MU_0);
    end
end
figure(11)
surf(D1,D2,OBJ)
xlabel('D1')
ylabel('D2')
zlabel('Profit')



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%% Vary T1 and T2 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 2
D1 = 5
D2 = 6
D3 = linspace(1.2,4.5,num);
D4 = linspace(2.0,5.5,num);
for i = 1:length(D3)
    for j = 1:length(D4)
        MU_0 = [D1, D2, D3(i), D4(j)];
        OBJ(j,i) = Fun_D1_D2_T1_T2_Cost(MU_0);
    end
end
figure(2)
surf(D3,D4,OBJ)
xlabel('T1')
ylabel('T2')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%% Vary D1 and T1 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 3
D1 = linspace(3.0,4.5,num);
D2 = 5
D3 = linspace(1.5,2.5,num);
D4 = 2.5
for i = 1:length(D1)
    for j = 1:length(D3)
        MU_0 = [D1(i), D2, D3(j), D4];
        OBJ(j,i) = Fun_D1_D2_T1_T2_Cost(MU_0);
    end
end
figure(3)
surf(D1,D3,OBJ)
xlabel('D1')
ylabel('T1')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%% Vary D1 and T2 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 4
D1 = linspace(3.0,4.7,num);
D2 = 5.0
D3 = 2.5
D4 = linspace(2.2,2.8,num);
for i = 1:length(D1)
    for j = 1:length(D4)
        MU_0 = [D1(i), D2, D3, D4(j)];
        OBJ(j,i) = Fun_D1_D2_T1_T2_Cost(MU_0);
    end
end
figure(4)
surf(D1,D4,OBJ)
xlabel('D1')
ylabel('T1')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                        %%% Vary D1, T1 and T2 %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case 5
D1 = linspace(3.8,4.5,num);
D2 = 6.2376
D3 = linspace(1.2,1.5,num);
D4 = linspace(2.25,2.45,num);
for i = 1:length(D1)
    for j = 1:length(D3)
        for k = 1:length(D4)
        MU_0 = [D1(i), D2, D3(j), D4(k)];
        OBJ(j,i,k) = Fun_D1_D2_T1_T2_Cost(MU_0);
        end
    end
end
figure(5)
xslice = 4.2;
yslice = 1.35;
zslice = 2.35;
slice(D1,D3,D4,OBJ,xslice,yslice,zslice); hold on
view(3);
xlabel('Diameter 1'); ylabel('Diameter 3'); zlabel('Diameter 4')
axis on; grid on;
colormap (jet(64)); colorbar('vertical');
%light; lighting flat; camlight('left'); 
shading interp;
alpha 1
axis square
h = colorbar;
ylabel(h, 'Profit');
axis([min(D1) max(D1) min(D3) max(D3) min(D4) max(D4)])



end

