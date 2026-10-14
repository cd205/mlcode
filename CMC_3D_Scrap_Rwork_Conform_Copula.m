% 3D Cut-measure-cut rework, coformance and scrap probability
% this codew integrates the trivariate CDF to infinity to determine 
% conformance and rework explicity  rather than from -infinity to calculate 
% scrap and conformance explicity.


clear all
close all
clc
CUT1 = [7 6 5.5];
CUT2 = [5 5 5];
sig11a = 1;
sig11b = sig11a;
sig22a = 1;
sig22b = sig22a;
sig33a = 1;
sig33b = sig33a;
sigma1_D = [1 1 1];
sigma2_D = [1 1 1];
A = [3 3 3];
B = [7 7 7];
range = [0 10] 
num = length(A);
Lower = 0; % lower bound to integrate from
pnts = 50;

%% Compute the cut-measure-cut distributions and the CDF
p = [1 0 0; 0 1 0; 0 0 1]; % parameter of Gaussian copula

u=linspace(range(1),range(2),pnts); % 1000 equidistant numbers

[x,y,z]=meshgrid(u); % create the grid (the points) on which the functions are evaluated

[a a_RW] = Fun_Cut_Measure_Cut_Dist(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)); % compute standard normal pdf values for x
[b b_RW] = Fun_Cut_Measure_Cut_Dist(y,CUT1(2),CUT2(2),sig22a,sig22b,A(2),B(2));
[c c_RW] = Fun_Cut_Measure_Cut_Dist(z,CUT1(3),CUT2(3),sig33a,sig33b,A(3),B(3));
% a_RW, b_RW and c_RW are the rework rates from the first cut
CUT1_RWork = [a_RW,b_RW,c_RW];
for i = 1:length(z)
    zp(i) = z(1,1,i);  % Take 1D elements of 3D array.  z(1,1,:) is not 1D
    cp(i) = c(1,1,i);  % Take 1D elements of 3D array for c
end

figure(1)
subplot(1,2,1)
plot(x(1,:,1),a(1,:,1));hold on
plot(y(:,1,1),b(:,1,1),'r'); hold on
plot(zp,cp,'m');grid on
line([A(1) A(1)],[0 max(max(max(b)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--');
line([B(1) B(1)],[0 max(max(max(b)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--');
xlabel('x_{1,2,3}')
ylabel('Probability Density')

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

figure(1)
subplot(1,2,2)
plot(x(1,:,1),u(1,:,1));hold on
plot(y(:,1,1),v(:,1,1),'r'); hold on
plot(zp,wp,'m');grid on
line([A(1) A(1)],[0 max(max(max(v)))],'color',[0 1 0],'LineWidth',2,'LineStyle','--');
line([B(1) B(1)],[0 max(max(max(v)))],'color',[1 0 0],'LineWidth',2,'LineStyle','--');
xlabel('x_{1,2,3}')
ylabel('Cumulative Density')


%% Start of Amir method
for i = 1:length(B)       % define h.b 
    temp1 = [Lower,B(i)];
    limits(i,:) = [temp1];
    unit_limits(i,:) = limits(i,:)./(range(2)-range(1));
    clear temp1
end
pdf = copulapdf('Gaussian',[u(:),v(:),w(:)],p);  % compute the PDF
mvpdf = reshape(pdf,pnts,pnts,pnts).*a.*b.*c;    % reshape the PDF
f = copulacdf('Gaussian',[u(:),v(:),w(:)],p); %compute the pdf of gaussian copula
mvd = reshape(f,pnts,pnts,pnts).*u.*v.*w;


Cols_USL = find(x(1,:,1)>=B(1)); % find all elements >= to USL in x matrix
Rows_USL = find(y(:,1,1)>=B(1)); % find all elements >= to USL in y matrix
Dim3_USL = find(zp>=B(1));       % find all elements >= to USL in z matrix 
                                 % (recall zp are the elemnts in z(1,1,:))

F_B = copulacdf('Gaussian',[u(1,Cols_USL(1),1),v(Rows_USL(1),1,1),w(1,1,Dim3_USL(1))],p)

% Plot 3D slice plot
figure
xslice = 7;
yslice =6;
zslice = 5;
slice(x,y,z,mvpdf,xslice,yslice,zslice)
view(3);
xlabel('x1'); ylabel('x2'); zlabel('x3')
axis on; grid on;
colormap (jet(64)); colorbar('vertical');
%light; lighting flat; camlight('left'); 
shading interp;
alpha 0.7
axis square



%% Determine the CDF evaluation limits

for i = 1:length(B)
    cc = 0;
    % first limit
    for j1 = 1:i-1
        fb1(j1) = B(j1);
    end
    fa = [A(i)];
    for j2 = i+1:length(B)
        cc = cc + 1;
        fb2(cc) = B(j2);
    end
    % Check if variable have been created and the collate the CDFs to
    % evaluate
    if exist('fb1') == 0
        CDF_Lims(i,:) = [fa,fb2];
    elseif exist('fb2') == 0
        CDF_Lims(i,:) = [fb1,fa];
    else
        CDF_Lims(i,:) = [fb1,fa,fb2];
    end
    clear fb1
    clear fa
    clear fb2
    clear cc
end


clear Fs
for i = 1:length(CDF_Lims(:,1))
    clear Limits
    limits(:,1) = Lower.*ones(length(CDF_Lims(:,1)),1);
    limits(:,2) = CDF_Lims(i,:)'
    Cols_SL = find(x(1,:,1)>=limits(1,2)) % find all elements >= to USL in x matrix
    Rows_SL = find(y(:,1,1)>=limits(2,2)) % find all elements >= to USL in y matrix
    Dim3_SL = find(zp>=limits(3,2)) 
    %z = spvals(funCMC3d,num,limits,options);
    Fs(i) = copulacdf('Gaussian',[u(1,Cols_SL(1),1),v(Rows_SL(1),1,1),w(1,1,Dim3_SL(1))],p);
end

LB = max(F_B - sum(Fs),0)
UB = F_B - max(Fs)

Fb1b2b3 = F_B
Fa1b2b3 = Fs(1)
Fb1a2b3 = Fs(2)
Fb1b2a3 = Fs(3)
% 
% %% Start Dodd Double accuracy improvement 
% %% Find means of the Cut-measure-cut distributions %%
% tic
% dist1 = @(x1) Fun_Cut_Measure_Cut_Dist(x1,CUT1(1),CUT2(1),sigma1_D(1),sigma2_D(1),A(1),B(1));
% dist2 = @(x2) Fun_Cut_Measure_Cut_Dist(x2,CUT1(2),CUT2(2),sigma1_D(2),sigma2_D(2),A(2),B(2));
% dist3 = @(x3) Fun_Cut_Measure_Cut_Dist(x3,CUT1(3),CUT2(3),sigma1_D(3),sigma2_D(3),A(3),B(3));
% dist1_mu = @(mu1) quadl(dist1,0,mu1)-0.5;
% dist2_mu = @(mu2) quadl(dist2,0,mu2)-0.5;
% dist3_mu = @(mu3) quadl(dist3,0,mu3)-0.5;
% mu1 = fzero(dist1_mu,CUT2(1));
% mu2 = fzero(dist2_mu,CUT2(2));
% mu3 = fzero(dist3_mu,CUT2(3));
% MU = [mu1 mu2 mu3]
% toc
% %% Implement double accuracy (See Rectangular Probabilties Report [Dodd 2013])
% % The case where LB = 0
% 
% if LB == 0
%     LBTime = tic;
%     P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];      % These are all the possilbe terms
%     [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
%     V = P;                              % Set V = P then delete the 
%     V(MaxPPos) = [];                    % largest term.
%     LB_Eq = sum(V) - prod(V);
%     if LB_Eq > F_B/2  %F_B/2 should be 0.5 if there is not rework
%          LB_D = LB;
%          UB_D = (UB-LB)/2;
%     elseif LB_Eq < F_B/2  %F_B/2 should be 0.5 if there is not rework
%          LB_D = (UB-LB)/2;
%          UB_D = UB;
%     else LB_D = (UB-LB)/2;
%          UB_D = (UB-LB)/2;
%     end
% end 
% 
% % The case where LB > 0
% if LB > 0
%     LBTime = tic;
%     P = [Fa1b2b3,Fb1a2b3,Fb1b2a3];                   % These are all the possilbe terms
%     [MaxP MaxPPos] = max([Fa1b2b3,Fb1a2b3,Fb1b2a3]); % Find the largest 
%     CUT1_LB = CUT1; CUT1_LB(MaxPPos) = [];            % Delete largest CUT1 term corresponding to largest F(*1,*2,*3)
%     CUT2_LB = CUT2; CUT2_LB(MaxPPos) = [];            % Delete largest CUT1 term corresponding to largest F(*1,*2,*3)
%     sigma1_D_LB = sigma1_D; sigma1_D_LB(MaxPPos) = [];% Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
%     sigma2_D_LB = sigma2_D; sigma2_D_LB(MaxPPos) = [];% Delete largest sigma_D term corresponding to largest F(*1,*2,*3)
%     A_LB = A; A_LB(MaxPPos) = [];                     % Delete largest A term corresponding to largest F(*1,*2,*3)
%     B_LB = B; B_LB(MaxPPos) = [];
%    
%     FD1 = @(v1) Fun_Cut_Measure_Cut_Dist(v1,CUT1_LB(1),CUT2_LB(1),sigma1_D_LB(1),sigma2_D_LB(1),A_LB(1),B_LB(1));
%     FD2 = @(v2) Fun_Cut_Measure_Cut_Dist(v2,CUT1_LB(2),CUT2_LB(2),sigma1_D_LB(2),sigma2_D_LB(2),A_LB(1),B_LB(2));
%     Delta = 1/quad(FD1,0,A_LB(1)) + 1/quad(FD2,0,A_LB(2)); % Calc Delta i.e. 
%             % how much smaller is the sticking out box (the N box in
%             % Rectangular Probabilties Report, [Dodd (2013)])
%             % Calc the gradient dN/dMu
%     A_Vec = linspace(2.5,3.5,10);
%     FD3 = @(v3) Fun_Cut_Measure_Cut_Dist(v3,CUT1(MaxPPos),CUT2(MaxPPos),sigma1_D(MaxPPos),sigma2_D(MaxPPos),A(MaxPPos),B(MaxPPos));
%         for i = 1:length(A_Vec)
%             P(i) = quad(FD3,0,A_Vec(i))/Delta;
%         end
%     AvgGrad = polyfit(A_Vec,P,1);  % fit a linear line through data
%     dN_dMu = AvgGrad(1,1);
%     fun = @(LocA) (F_B/2)/Delta...   % F_B/2 should be about 0.5 depending on total rework
%         + (LocA*dN_dMu - A(MaxPPos)*dN_dMu)...
%         - (F_B/2 - quad(FD3,0,LocA)); % F_B/2 should be about 0.5 depending on total rework
%     %normcdf(A(MaxPPos),mu,sigma_D(MaxPPos)));
%     x0 = 3;
%     LocA_x = fzero(fun,x0);
%         if MU(MaxPPos) < LocA_x
%              LB_D = (UB-LB)/2+LB;
%              UB_D = UB;
%         elseif MU(MaxPPos) > LocA_x
%              LB_D = LB;
%              UB_D = (UB-LB)/2+LB;
%         else LB_D = (UB-LB)/2+LB;
%              UB_D = (UB-LB)/2+LB;
%         end
% end
% LB_time = toc(LBTime)
% %runtime = toc(start1)
% LB_D = LB_D
% UB_D = UB_D
% %E = mvncdf([3 3 3],[7 7 7],MU,SIGMA)
% figure(3)
% plot(LB,0,'g.','MarkerSize',30); hold on
% plot(UB,0,'r.','MarkerSize',30); hold on
% plot(LB_D,0,'k*','MarkerSize',15); hold on
% plot(UB_D,0,'m*','MarkerSize',15); grid on