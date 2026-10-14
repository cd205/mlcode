function [df] = fun_3D_Copula_dist(x,y,z)%,CUT1,CUT2)

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
A = [3 3 3];
B = [7 7 7];
Range = [0 10]; 
p = [1 0.0 0; 0.0 1 0; 0 0 1];
%x=5; y=5; z=5;
for i = 1:length(x)
    [a(i) a_RW a_SCP] = Fun_Reverse_Cut_Measure_Cut_pdf(x(i),CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)); % compute standard normal pdf values for x
end
    [b b_RW b_SCP] = Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig22a,sig22b,A(2),B(2));
    
    [c c_RW c_SCP] = Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig33a,sig33b,A(3),B(3));
    
for i = 1:length(x)
    df(i) = copulapdf('Gaussian',[quad(@(x) Fun_Reverse_Cut_Measure_Cut_pdf(x,CUT1(1),CUT2(1),sig11a,sig11b,A(1),B(1)),Range(1),x(i)),...
        quad(@(y) Fun_Reverse_Cut_Measure_Cut_pdf(y,CUT1(2),CUT2(2),sig11a,sig11b,A(2),B(2)),Range(1),y),...
        quad(@(z) Fun_Reverse_Cut_Measure_Cut_pdf(z,CUT1(3),CUT2(3),sig11a,sig11b,A(3),B(3)),Range(1),z)],p).*a(i).*b.*c;
end