function [df] = fun_3D_Copula_dist_V2(x,y,z)%,CUT1,CUT2)
% clear all
% close all
% clc
cuts = [7 7 7 6 6 5];
CUT1 = [cuts(1) cuts(2) cuts(3)];
CUT2 = [cuts(4) cuts(5) cuts(6)];
sig11a = 1;
sig11b = sig11a;
sig22a = 1;
sig22b = sig22a;
sig33a = 1;
sig33b = sig33a;
sigma1 = [sig11a 0.0 0; 0.0 sig22a 0; 0 0 sig33a];
A = [3 3 3];
B = [7 7 7];
Range = [0 10]; 
p = [1 0.0 0; 0.0 1 0; 0 0 1];


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
          + Fb1a2a3 - Fb1a2b3 - Fb1b2a3 + Fb1b2b3;   
% Scrap
% ScrapPrt = 1 - Fb1b2b3
% Rework 
RworkPrt = Fb1b2b3 - ConformPrt;

c = 0;
for i = 1:length(x)
    if x(i)>=A(1) && y>=A(2) && z>=A(3) 
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1); 
        c = c+1;
    elseif x(i)<A(1) && z>=B(3) % top left
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1); 
        c = c+1;
    elseif y<A(2) && z>=B(3) % top front
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1);  
        c = c+1;
    elseif x(i)>=B(1) && y<A(2) && z<B(3) % front side vertical
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1);
        c = c+1;
    elseif x(i)>=B(1) && y>=A(2) && z<A(3) % right side bottom
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1);  
        c = c+1;
    elseif x(i)<A(1) && y>=B(2) && z<B(3); % back left vertical
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1);
        c = c+1;
    elseif x(i)>=A(1) && x(i)<B(1) && y>=B(2) && z<A(3) % back middle botom 
        df(i) = mvnpdf([x(i),y,z],cut1R,sigma1) + RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1);  
        c = c+1;
    elseif x(i)<B(1) && y<B(2) && z<B(3) % this does green region, the conformance
        df(i) = RworkPrt*mvnpdf([x(i),y,z],cut2R,sigma1);%  box is not accounted for due to the first 
        c = c+1;
    end                                              % if-statement which is evaluated before, thus 
end            
%%
