% trivariate Cut-Measure-Cut
clear all
close all
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
sigma1 = [sig11a 0.0 0; 0.0 sig22a 0; 0 0 sig33a]
% sigma2_D = [1 1 1];
A = [3 3 3];
B = [7 7 7];
range = [0 10]; 
num = length(A);
Lower = 0; % lower bound to integrate from
pnts = 30
u=linspace(range(1),range(2),pnts); % 1000 equidistant numbers

[x,y,z]=meshgrid(u); % create the grid (the points) on which the functions are evaluated
zp = squeeze(z(1,1,:))';  % Take 1D elements of 3D array.  z(1,1,:) is not 1D 
X = [x(:) y(:) z(:)];

cut1R = A+(B-CUT1);  % convert cut1 from near to USL to near LSL
cut2R = A+(B-CUT2);  % convert cut2 from near to USL to near LSL


% now take CDFs to work out reworked dimensions
Fa1a2a3 = mvncdf([A(1) A(2) A(3)],cut1R,sigma1);
Fa1a2b3 = mvncdf([A(1) A(2) B(3)],cut1R,sigma1);
Fa1b2a3 = mvncdf([A(1) B(2) A(3)],cut1R,sigma1);
Fa1b2b3 = mvncdf([A(1) B(2) B(3)],cut1R,sigma1);
Fb1a2a3 = mvncdf([B(1) A(2) A(3)],cut1R,sigma1);
Fb1a2b3 = mvncdf([B(1) A(2) B(3)],cut1R,sigma1);
Fb1b2a3 = mvncdf([B(1) B(2) A(3)],cut1R,sigma1);
Fb1b2b3 = mvncdf([B(1) B(2) B(3)],cut1R,sigma1);

% Conformance
ConformPrt = - Fa1a2a3 + Fa1a2b3 + Fa1b2a3 - Fa1b2b3...
          + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3   
% Scrap
ScrapPrt = 1 - Fb1b2b3
% Rework 
RworkPrt = Fb1b2b3 - ConformPrt


RW_1 = Fa1b2b3 - Fa1b2a3 - Fa1a2b3 + Fa1a2a3
RW_2 = Fb1a2b3 - Fb1a2a3 - Fa1a2b3 + Fa1a2a3
RW_3 = Fb1b2a3 - Fb1a2a3 - Fa1b2a3 + Fa1a2a3
RW_12 = Fa1a2b3 - Fa1a2a3
RW_13 = Fa1b2a3 - Fa1a2a3
RW_23 = Fb1a2a3 - Fa1a2a3
RW_123 = Fa1a2a3

RWtotal = RW_1 + RW_2 + RW_3 + RW_12 + RW_13 + RW_23 + RW_123

PRW1 = normcdf(A(1),cut1R(1),sig11a);
PRW2 = normcdf(A(2),cut1R(2),sig11a);
PRW3 = normcdf(A(3),cut1R(3),sig11a);

% for RW_12, RW13, RW23 and RW123
RW_1 = RW_1 + RW_12*PRW1/(PRW1+PRW2) + RW_13*PRW1/(PRW1+PRW3) + RW_123*PRW1/(PRW1+PRW2+PRW3)
RW_2 = RW_2 + RW_12*PRW2/(PRW1+PRW2) + RW_23*PRW2/(PRW2+PRW3) + RW_123*PRW2/(PRW1+PRW2+PRW3)
RW_3 = RW_3 + RW_13*PRW3/(PRW1+PRW3) + RW_23*PRW3/(PRW2+PRW3) + RW_123*PRW3/(PRW1+PRW2+PRW3)
RWcheck = RW_1 + RW_2 + RW_3
c = 0
for i = 1:length(X)
    if X(i,1)>=A(1) && X(i,2)>=A(2) && X(i,3)>=A(3) 
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1); 
        c = c+1;
    elseif X(i,1)<A(1) && X(i,3)>=B(3) % top left
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1); 
        c = c+1;
    elseif X(i,2)<A(2) && X(i,3)>=B(3) % top front
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);  
        c = c+1;
    elseif X(i,1)>=B(1) && X(i,2)<A(2) && X(i,3)<B(3) % front side vertical
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);
        c = c+1;
    elseif X(i,1)>=B(1) && X(i,2)>=A(2) && X(i,3)<A(3) % right side bottom
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);  
        c = c+1;
    elseif X(i,1)<A(1) && X(i,2)>=B(2) && X(i,3)<B(3); % back left vertical
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);
        c = c+1;
    elseif X(i,1)>=A(1) && X(i,1)<B(1) && X(i,2)>=B(2) && X(i,3)<A(3) % back middle botom 
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);  
        c = c+1;
    elseif X(i,1)<B(1) && X(i,2)<B(2) && X(i,3)<B(3) % this does green region, the conformance
        df(i) = RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);%  box is not accounted for due to the first 
        c = c+1;
    end                                              % if-statement which is evaluated before, thus 
end                                                  % any points in this box are automatically taken out 
MVD1 = reshape(df,pnts,pnts,pnts);    

%% Plot MVD1
figure(5);
xslice = 3.5;
yslice = 3.5;
zslice = 3.5;
slice(x,y,z,MVD1,xslice,yslice,zslice)
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
PScrap = (1 - normcdf(USL,cut1R,sigma1)) + (1 - normcdf(USL,cut2R,sigma2));
PRwork = normcdf(LSL,cut1R,sigma1);
 
for i = 1:length(x)
    if x(i) >= LSL  % Conformance from first cut
        df(i) = normpdf(x(i),cut1R,sigma1) + PRwork.*normpdf(x(i),cut2R,sigma1);
    elseif x(i) < LSL
        df(i) = PRwork.*normpdf(x(i),cut2R,sigma1);
    end
end

