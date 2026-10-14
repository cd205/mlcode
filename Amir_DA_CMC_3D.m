% Amir 3D method with Double accuracy implimentation

clear all
clc
close all
start1 = tic
num = 100;
A = [3 4 5];
B = [7 8 9];
L = -5;
% mu1 = 1;
% mu2 = 5.0;
% mu3 = 6.0; %3.10825;
cut1_1 = 6
cut1_2 = 7
cut1_3 = 8
cut2_1 = 5
cut2_2 = 6
cut2_3 = 7
sigma1_1 = 1;
sigma1_2 = 1;
sigma1_3 = 1;
sigma2_1 = 1;
sigma2_2 = 1;
sigma2_3 = 1;
%sigma_D = [sigma11 sigma22 sigma33];
sigma1_D = [sigma1_1 sigma1_2 sigma1_3];
sigma2_D = [sigma2_1 sigma2_2 sigma2_3];
CUT1 = [cut1_1 cut1_2 cut1_3];
CUT2 = [cut2_1 cut2_2 cut2_3];
%NOM = [5 5 5]
%SIMGA1 = [sigma_D(1)^2 sigma12^2 sigma13^2;...
       % sigma21^2 sigma_D(2)^2 sigma23^2;...
       % sigma31^2 sigma32^2 sigma_D(3)^2];
%SIGMA = [sigma_D(1)^2 sigma12^2 sigma13^2;...
        %sigma21^2 sigma_D(2)^2 sigma23^2;...
        %sigma31^2 sigma32^2 sigma_D(3)^2];
%MU = [mu1 mu2 mu3]

%% Compute trivariate distribution for a cut-measure-cut distribution

 %with Gaussian copula

p = [sigma1_1 0 0; 0 sigma1_2 0; 0 0 sigma1_3]; % parameter of Gaussian copula

u=linspace(0,10,num); % 1000 equidistant numbers

[x,y,z]=meshgrid(u); % create the grid (the points) on which the functions are evaluated

a = Fun_Cut_Measure_Cut_Dist(x,CUT1(1),CUT2(1),sigma1_D(1),sigma2_D(1),A(1),B(1)); % compute standard normal pdf values for x
b = Fun_Cut_Measure_Cut_Dist(y,CUT1(2),CUT2(2),sigma1_D(2),sigma2_D(2),A(2),B(2));
c = Fun_Cut_Measure_Cut_Dist(z,CUT1(3),CUT2(3),sigma1_D(3),sigma2_D(3),A(3),B(3));
for i = 1:length(z)
    zp(i) = z(1,1,i);  % Take 1D elements of 3D array.  z(1,1,:) is not 1D
    cp(i) = c(1,1,i);  % Take 1D elements of 3D array for c
end
figure(1)
subplot(1,2,1)
plot(x(1,:,1),a(1,:,1));hold on
plot(y(:,1,1),b(:,1,1),'r'); hold on
plot(zp,cp,'m');grid on
xlabel('x_{1,2,3}')
ylabel('Probability Density')
u = normcdf(x,5,1); % compute standard normal cdf values for x
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


figure(1)
subplot(1,2,2)
plot(x(1,:,1),u(1,:,1));hold on
plot(y(:,1,1),v(:,1,1),'r'); hold on
plot(zp,wp,'m');grid on
xlabel('x_{1,2,3}')
ylabel('Cumulative Density')
f = copulapdf('Gaussian',[u(:),v(:),w(:)],p); %compute the pdf of gaussian copula
mvd = reshape(f,num,num,num).*a.*b.*c; % create multivariate density from the product
% of the copula pdf and the marginal pdfs
% reshape f to avoid matrix
% dimension conflicts

%% Integrate the volumes (cubes)
fun = @(Xi,Yi,Zi) interp3(x,y,z,mvd,Xi,Yi,Zi)
% Fa1a2a3 = triplequad(fun,0,A(1),0,A(2),0,A(3))
% Fa1a2b3 = triplequad(fun,0,A(1),0,A(2),0,B(3))
% Fa1b2a3 = triplequad(fun,0,A(1),0,B(2),0,A(3))
Fa1b2b3 = triplequad(fun,0,A(1),0,B(2),0,B(3))
% Fb1a2a3 = triplequad(fun,0,B(1),0,A(2),0,A(3))
Fb1a2b3 = triplequad(fun,0,B(1),0,A(2),0,B(3))
Fb1b2a3 = triplequad(fun,0,B(1),0,B(2),0,A(3))
Fb1b2b3 = triplequad(fun,0,B(1),0,B(2),0,B(3))

%% Implement Stnadard Amri Method
LB = Fb1b2b3 - (Fa1b2b3 + Fb1a2b3 + Fb1b2a3)
if LB < 0
    LB = 0
end
UB = Fb1b2b3 - max([Fa1b2b3 Fb1a2b3 Fb1b2a3])

s1 = struct('Fa1b2b3',Fa1b2b3,'Fb1a2b3',Fb1a2b3,...
    'Fb1b2a3',Fb1b2a3,'Fb1b2b3',Fb1b2b3)

%% Implement double accuracy (See Rectangular Probabilties Report [Dodd 2013])
% The case where LB = 0
if LB == 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];      % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    V = P;                              % Set V = P then delete the 
    V(MaxPPos) = [];                    % largest term.
    LB_Eq = sum(V) - prod(V)
    if LB_Eq > 0.5
         LB_D = LB
         UB_D = (UB-LB)/2
    elseif LB_Eq < 0.5
         LB_D = (UB-LB)/2
         UB_D = UB
    else LB_D = (UB-LB)/2
         UB_D = (UB-LB)/2
    end
end 

% The case where LB > 0
if LB > 0
    P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];                   % These are all the possilbe terms
    [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
    CUT1_LB = CUT1; CUT1_LB(MaxPPos) = []             % Delete largest CUT1 term corresponding to largest F(*1,*2,*3)
    CUT2_LB = CUT2; CUT2_LB(MaxPPos) = []             % Delete largest CUT1 term corresponding to largest F(*1,*2,*3)
    sigma1_D_LB = sigma1_D; sigma1_D_LB(MaxPPos) = []   % Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
    sigma2_D_LB = sigma2_D; sigma2_D_LB(MaxPPos) = []   % Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
    A_LB = A; A_LB(MaxPPos) = []                     % Delete largest A term corresponding to largest F(*1,*2,*3)
    B_LB = B; B_LB(MaxPPos) = []
   
    FD1 = @(v1) Fun_Cut_Measure_Cut_Dist(v1,CUT1_LB(1),CUT2_LB(1),sigma1_D_LB(1),sigma2_D_LB(1),A_LB(1),B_LB(1))
    FD2 = @(v2) Fun_Cut_Measure_Cut_Dist(v2,CUT1_LB(2),CUT2_LB(2),sigma1_D_LB(2),sigma2_D_LB(2),A_LB(1),B_LB(2))
    Delta = 1/quad(FD1,0,A_LB(1)) + 1/quad(FD2,0,A_LB(2)) % Calc Delta i.e. 
            % how much smaller is the sticking out box (the N box in
            % Rectangular Probabilties Report, [Dodd (2013)])
            % Calc the gradient dN/dMu
    A_Vec = linspace(2.5,3.5,10);
    FD3 = @(v3) Fun_Cut_Measure_Cut_Dist(v3,CUT1(MaxPPos),CUT2(MaxPPos),sigma1_D(MaxPPos),sigma2_D(MaxPPos),A(MaxPPos),B(MaxPPos));
        for i = 1:length(A_Vec)
            P(i) = quad(FD3,0,A_Vec(i))/Delta;
        end
    AvgGrad = polyfit(A_Vec,P,1)  % fit a linear line through data
    dN_dMu = AvgGrad(1,1)
    fun = @(LocA) (0.5)/Delta...
        + (LocA*dN_dMu - A(MaxPPos)*dN_dMu)...
        - (0.5 - quad(FD3,0,LocA));
    %normcdf(A(MaxPPos),mu,sigma_D(MaxPPos)));
    x0 = 3;
    LocA_x = fzero(fun,x0) 
        if MU(MaxPPos) < mu_x
             LB_D = (UB-LB)/2+LB;
             UB_D = UB;
        elseif MU(MaxPPos) > mu_x
             LB_D = LB;
             UB_D = (UB-LB)/2+LB;
        else LB_D = (UB-LB)/2+LB;
             UB_D = (UB-LB)/2+LB;
        end
end
runtime = toc(start1)

%E = mvncdf([3 3 3],[7 7 7],MU,SIGMA)
figure(3)
plot(LB,0,'g.','MarkerSize',30); hold on
plot(UB,0,'r.','MarkerSize',30); hold on
plot(LB_D,0,'k*','MarkerSize',15); hold on
plot(UB_D,0,'m*','MarkerSize',15); hold on
%plot(E,0,'b.','MarkerSize',30); grid on

%%%%
x = linspace(0,10,100)
p1 = normpdf(x,5,1)
p2 = normpdf(x,6,1)
p3 = normpdf(x,7,1)
c1 = normcdf(x,5,1)
c2 = normcdf(x,6,1)
c3 = normcdf(x,7,1)
figure(1)
subplot(1,2,1)
plot(x,p1);hold on
plot(x,p2,'r'); hold on
plot(x,p3,'m');grid on
xlabel('x_{1,2,3}')
ylabel('Probability Density')

subplot(1,2,2)
plot(x,c1);hold on
plot(x,c2,'r'); hold on
plot(x,c3,'m');grid on
xlabel('x_{1,2,3}')
ylabel('Cumulative Density')
