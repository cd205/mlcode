clear all
%close all
clc
mu_L = 31.0345;%25.5172;%30.0;
mu_R = 32.4138%36.5517%8205;%24.95;
N = 150;
B = 0.002;
sigma_L = 1;
sigma_R = 0.8;
sigma_N = 0;
sigma_B = 0;%5.0E-05;
USL = 11;
LSL = 9;

%% scrap is -6sigma to line and -6sigma to line

% Draw 6sigma box around nominal point
tolL = 6*sigma_L;
tolR = 6*sigma_R;
% LL = [mu_L - tolL, mu_R - tolR];    % Lower left corner
% LU = [mu_L - tolL, mu_R + tolR];    % Upper left corner
% RU = [mu_L + tolL, mu_R + tolR];    % Upper right corner
% RL = [mu_L + tolL, mu_R - tolR];    % Lower right corner

%% Find the upper and lower spec limits of the actflow function through 
% the box
L_vec = linspace(mu_L-2*tolL,mu_L+2*tolL,50);
R_vec = linspace(mu_R-2*tolR,mu_R+2*tolR,50);

for i = 1:length(L_vec)
    L = L_vec(i);
    for j = 1:length(R_vec)
        R = R_vec(j);
        actflow(j,i) = (pi*R*R*L/1E6 - B)*N;
    end
end

%% Ploting %%
[L_p R_p] = meshgrid(L_vec,R_vec);
figure(1)
contourf(L_p,R_p,actflow,50)
colorbar
c=colorbar;
ylabel(c,'Actflow (ltrs/min)')
xlabel('L')
ylabel('R')
hold on
plot(mu_L,mu_R,'k.','MarkerSize',20)
line([mu_L-tolL mu_L-tolL],[mu_R-tolR mu_R+tolR],'Color','r','LineWidth',1);
line([mu_L-tolL mu_L+tolL],[mu_R+tolR mu_R+tolR],'Color','r','LineWidth',1);
line([mu_L+tolL mu_L+tolL],[mu_R+tolR mu_R-tolR],'Color','r','LineWidth',1);
line([mu_L+tolL mu_L-tolL],[mu_R-tolR mu_R-tolR],'Color','r','LineWidth',1);
hold on

%% work out intersects
SpecLimContours = contour(L_p,R_p,actflow,[9 11],'Color','w','LineWidth',2);
% column 1 is the start of contour 1 there the 1st number is the value of
% the contour and the 2nd number is the number of pairs 
SpecLimContours = SpecLimContours';
% Below are the x and y coords for the LSL and USL contour lines.  The
% SpecLimContours vecotr contains a 'contour identifier' specifing the
% value of the contour and number of x y pairs.  This is used to selcet the
% appropriate contours 

% determine if there is an entry in SpecLimContours, if not the contours
% are off the design space    
SpecLimContours_empty = isempty(SpecLimContours);
if SpecLimContours_empty==1
   P_Scrap = NaN
   P_Rwork = NaN
   P_conformance = NaN
else
    LSL_Contour = SpecLimContours([2:SpecLimContours(1,2)+1],:);
    USL_Contour = SpecLimContours([SpecLimContours(1,2)+3]:end,:);
    % determine if both contours are still in the design space
    LSL_empty = isempty(LSL_Contour);
    USL_empty = isempty(USL_Contour);
    if  LSL_empty==1 || USL_empty==1
        P_Scrap = NaN
        P_Rwork = NaN
        P_conformance = NaN
    else
       
        % intersect along countour of actflow = 9
        [x9L,y9L] = intersections(LSL_Contour(:,1),LSL_Contour(:,2),[mu_L-tolL mu_L-tolL],[mu_R-tolR mu_R+tolR]);
        [x9U,y9U] = intersections(LSL_Contour(:,1),LSL_Contour(:,2),[mu_L-tolL mu_L+tolL],[mu_R+tolR mu_R+tolR]);
        [x9R,y9R] = intersections(LSL_Contour(:,1),LSL_Contour(:,2),[mu_L+tolL mu_L+tolL],[mu_R+tolR mu_R-tolR]);
        [x9B,y9B] = intersections(LSL_Contour(:,1),LSL_Contour(:,2),[mu_L+tolL mu_L-tolL],[mu_R-tolR mu_R-tolR]);
        % intersect along countour of actflow = 11
        [x11L,y11L] = intersections(USL_Contour(:,1),USL_Contour(:,2),[mu_L-tolL mu_L-tolL],[mu_R-tolR mu_R+tolR]);
        [x11U,y11U] = intersections(USL_Contour(:,1),USL_Contour(:,2),[mu_L-tolL mu_L+tolL],[mu_R+tolR mu_R+tolR]);
        [x11R,y11R] = intersections(USL_Contour(:,1),USL_Contour(:,2),[mu_L+tolL mu_L+tolL],[mu_R+tolR mu_R-tolR]);
        [x11B,y11B] = intersections(USL_Contour(:,1),USL_Contour(:,2),[mu_L+tolL mu_L-tolL],[mu_R-tolR mu_R-tolR]);
        
        X9I_vec = [x9L,y9L;x9U,y9U;x9R,y9R;x9B,y9B];
        X11I_vec = [x11L,y11L;x11U,y11U;x11R,y11R;x11B,y11B];
        X9I_vec_empty = isempty(X9I_vec);  %check if there are intersects
        X11I_vec_empty = isempty(X11I_vec);   %check if there are intersects
        if X9I_vec_empty || X11I_vec_empty
            P_Scrap = NaN
            P_Rwork = NaN
            P_conformance = NaN
        else
            %% Plot intersects
            plot(X9I_vec(:,1),X9I_vec(:,2),'r.','MarkerSize',15)
            plot(X11I_vec(:,1),X11I_vec(:,2),'k.','MarkerSize',15)
            
            %% Find Scrap
            a = mu_L - tolL; % Left
            b = mu_L + tolL; % Right bound
            c = mu_R - tolR; % bottom
            d = @(L) interp1(LSL_Contour(:,1),LSL_Contour(:,2),L,'spline',0); % lower performance spec
            
            fun = @(L,R) mvnpdf_quad2d(L,R,[mu_L mu_R],[sigma_L^2 sigma_R^2]);
            P_Scrap = quad2d(fun,a,b,c,d)
            tic
            %% Find Rework
            if [mu_L,mu_R] < interp1(USL_Contour(:,1),USL_Contour(:,2),mu_L,'linear',0)
                a = X11I_vec(1,1) % if nominal is below USL line use intersection point
            else a = mu_L - tolL  % otherwise use actual limit
            end 
            b = mu_L + tolL  % otherwise use actual limit
            c = @(L) interp1(USL_Contour(:,1),USL_Contour(:,2),L,'spline',0); % upper performance spec
            d = mu_R + tolR; % top
            
            fun = @(L,R) mvnpdf_quad2d(L,R,[mu_L mu_R],[sigma_L^2 sigma_R^2]);
            P_Rwork = quad2d(fun,a,b,c,d)
            
            toc
            %% Find Conformance
            P_conformance = 1 - P_Scrap - P_Rwork
            
            %% Check result with MC run
            [P_success,P_fail,cpk] = ConformanceCalc(mu_L,mu_R,N,B,sigma_L,sigma_R,0,0,USL,LSL,10000000)
        end
    end
end
    
    

    
