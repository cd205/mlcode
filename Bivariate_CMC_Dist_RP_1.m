% trivariate Cut-Measure-Cut
clear all
%close all
clc
flag = 1;
%cuts = [6.3696,6.3009,6.3724,5.5048,5.5254,5.5038];
cuts = [7 7 6 5];
CUT1 = [cuts(1) cuts(2)];
CUT2 = [cuts(3) cuts(4)];

sig11a = 1;
sig11b = sig11a;
sig22a = 1;
sig22b = sig22a;
sigma1 = [sig11a 0.0; 0.0 sig22a]
% sigma2_D = [1 1 1];
A = [3 3];
B = [7 7];
range = [0 10]; 
num = length(A);
Lower = 0; % lower bound to integrate from
pnts = 150
u=linspace(range(1),range(2),pnts); % 1000 equidistant numbers

[x,y]=meshgrid(u); % create the grid (the points) on which the functions are evaluated
X = [x(:) y(:)];

cut1R = A+(B-CUT1);  % convert cut1 from near to USL to near LSL
cut2R = A+(B-CUT2);  % convert cut2 from near to USL to near LSL


% now take CDFs to work out reworked dimensions
Fa1a2 = mvncdf([A(1) A(2)],cut1R,sigma1);
Fa1b2 = mvncdf([A(1) B(2)],cut1R,sigma1);
Fb1a2 = mvncdf([B(1) A(2)],cut1R,sigma1);
Fb1b2 = mvncdf([B(1) B(2)],cut1R,sigma1);


% Conformance
ConformPrt = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2   
% Scrap
ScrapPrt = 1 - Fb1b2
% Rework 
RworkPrt = Fb1b2 - ConformPrt


% RW_1 = Fa1b2b3 - Fa1b2a3 - Fa1a2b3 + Fa1a2a3
% RW_2 = Fb1a2b3 - Fb1a2a3 - Fa1a2b3 + Fa1a2a3
% RW_3 = Fb1b2a3 - Fb1a2a3 - Fa1b2a3 + Fa1a2a3
% RW_12 = Fa1a2b3 - Fa1a2a3
% RW_13 = Fa1b2a3 - Fa1a2a3
% RW_23 = Fb1a2a3 - Fa1a2a3
% RW_123 = Fa1a2a3

% RWtotal = RW_1 + RW_2 + RW_3 + RW_12 + RW_13 + RW_23 + RW_123

PRW1 = normcdf(A(1),cut1R(1),sig11a);
PRW2 = normcdf(A(2),cut1R(2),sig11a);

% % for RW_12, RW13, RW23 and RW123
% RW_1 = RW_1 + RW_12*PRW1/(PRW1+PRW2) + RW_13*PRW1/(PRW1+PRW3) + RW_123*PRW1/(PRW1+PRW2+PRW3)
% RW_2 = RW_2 + RW_12*PRW2/(PRW1+PRW2) + RW_23*PRW2/(PRW2+PRW3) + RW_123*PRW2/(PRW1+PRW2+PRW3)
% RW_3 = RW_3 + RW_13*PRW3/(PRW1+PRW3) + RW_23*PRW3/(PRW2+PRW3) + RW_123*PRW3/(PRW1+PRW2+PRW3)
% RWcheck = RW_1 + RW_2 + RW_3
c = 0
for i = 1:length(X)
    if X(i,1)>=A(1) && X(i,2)>=A(2) 
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1); 
        c = c+1;
    elseif X(i,1)<A(1) && X(i,2)>=B(2) % top left corner
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1); 
        c = c+1;
    elseif X(i,1)>=B(1) && X(i,2)<A(2) % bottom right side corner
        df(i) = mvnpdf(X(i,:),cut1R,sigma1) + RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);
        c = c+1;
    elseif X(i,1)<B(1) && X(i,2)<B(2)                % this does green region, the conformance
        df(i) = RworkPrt*mvnpdf(X(i,:),cut2R,sigma1);%  box is not accounted for due to the first 
        c = c+1;
    end                                              % if-statement which is evaluated before, thus 
end                                                  % any points in this box are automatically taken out 
MVD1 = reshape(df,pnts,pnts);    

%% Plot MVD1
figure(3)
surf(x,y,MVD1,'EdgeColor','none')
xlabel('Cut1 dim x'); ylabel('Cut1 dim y');
h = colorbar;
ylabel(h, 'Probability Density');
 
for i = 1:length(x)
    if x(i) >= LSL  % Conformance from first cut
        df(i) = normpdf(x(i),cut1R,sigma1) + PRwork.*normpdf(x(i),cut2R,sigma1);
    elseif x(i) < LSL
        df(i) = PRwork.*normpdf(x(i),cut2R,sigma1);
    end
end

