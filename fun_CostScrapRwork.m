function [P_con,P_srp,P_rwk] = fun_CostScrapRwork(mu_L,mu_R,mu_N,mu_B,sigma_L,sigma_R,sigma_N,sigma_B,LSL,USL)

N = mu_N;
B = mu_B;
% Draw 6sigma box around nominal point
tolL = 6*sigma_L;
tolR = 6*sigma_R;

%% Find the upper and lower spec limits of the actflow function through 
% the box
L_vecF = linspace(mu_L-2*tolL,mu_L+2*tolL,50);
R_vecF = linspace(mu_R-2*tolR,mu_R+2*tolR,50);

for i = 1:length(L_vecF)
    LF = L_vecF(i);
    for j = 1:length(R_vecF)
        RF = R_vecF(j);
        actflow(j,i) = (pi*RF*RF*LF/1E6 - B)*N;
    end
end

%% work out intersects
[L_p R_p] = meshgrid(L_vecF,R_vecF);
SpecLimContours = contour(L_p,R_p,actflow,[9 11]);%,'Color','w','LineWidth',2);
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
   P_srp = NaN;
   P_rwk = NaN;
   P_con = NaN;
else
    LSL_Contour = SpecLimContours([2:SpecLimContours(1,2)+1],:);
    USL_Contour = SpecLimContours([SpecLimContours(1,2)+3]:end,:);
    % determine if both contours are still in the design space
    LSL_empty = isempty(LSL_Contour);
    USL_empty = isempty(USL_Contour);
    if  LSL_empty==1 || USL_empty==1
        P_srp = NaN;
        P_rwk = NaN;
        P_con = NaN;
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
        X9I_vec_empty = isempty(X9I_vec);  % check if there are intersects
        X11I_vec_empty = isempty(X11I_vec);   % check if there are intersects
        if X9I_vec_empty || X11I_vec_empty
            P_srp = NaN;
            P_rwk = NaN;
            P_con = NaN;
        else
            %% Find scrap
            a = mu_L - tolL; % Left
            b = mu_L + tolL; % Right bound
            c = mu_R - tolR; % bottom
            d = @(L) interp1(LSL_Contour(:,1),LSL_Contour(:,2),L,'spline',0); % lower performance spec
            
            fun = @(L,R) mvnpdf_quad2d(L,R,[mu_L mu_R],[sigma_L^2 sigma_R^2]);
            P_srp = quad2d(fun,a,b,c,d,'MaxFunEvals',500);
            
            %% Find Rework
             %% Find Rework
            if [mu_L,mu_R] < interp1(USL_Contour(:,1),USL_Contour(:,2),mu_L,'linear',0)
                a = X11I_vec(1,1); % if nominal is below USL line use intersection point
            else a = mu_L - tolL;  % otherwise use actual limit
            end  
            b = mu_L + tolL;  
            c = @(L) interp1(USL_Contour(:,1),USL_Contour(:,2),L,'spline',0); % upper performance spec
            d = mu_R + tolR; % top
            
            fun = @(L,R) mvnpdf_quad2d(L,R,[mu_L mu_R],[sigma_L^2 sigma_R^2]);
            P_rwk = quad2d(fun,a,b,c,d,'MaxFunEvals',500);
            
            
            %% Find Conformance
            P_con = 1 - P_srp - P_rwk;
        end
    end
end