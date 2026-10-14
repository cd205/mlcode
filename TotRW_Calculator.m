function TotRW = TotRW_Calculator(x,cut1,cut2,LSL,USL)
% Simulate rework instead of markov chain
% clear all
% close all
% clc
% cut1  = 6.3255;
% cut2 = 6.3255
% USL = 7;
% LSL = 3;
% x = linspace(0,12,100);


RW1P = 1-normcdf(USL,cut1,1);

d1 = Fun_Cut_Measure_Cut_pdf(x,cut1,cut2,1,1,LSL,USL);
p11_d1 = integral(@(x) Fun_Cut_Measure_Cut_pdf(x,cut1,cut2,1,1,LSL,USL),USL,inf); 
        % Rework from CMC dist i.e. rework after 2nd cut
        
d2 = extra_CMC(x,d1,p11_d1,cut2,cut2,1,1,LSL,USL);
p11_d2 =  integral(@(x)  extra_CMC(x,d1,p11_d1,cut2,cut2,1,1,LSL,USL),USL,inf);

d3 = extra_CMC(x,d2,p11_d2,cut2,cut2,1,1,LSL,USL);
p11_d3 =  integral(@(x)  extra_CMC(x,d2,p11_d2,cut2,cut2,1,1,LSL,USL),USL,inf);

d4 = extra_CMC(x,d3,p11_d3,cut2,cut2,1,1,LSL,USL);
p11_d4 =  integral(@(x)  extra_CMC(x,d3,p11_d3,cut2,cut2,1,1,LSL,USL),USL,inf); 

d5 = extra_CMC(x,d4,p11_d4,cut2,cut2,1,1,LSL,USL);
p11_d5 =  integral(@(x)  extra_CMC(x,d4,p11_d4,cut2,cut2,1,1,LSL,USL),USL,inf); 

d6 = extra_CMC(x,d5,p11_d5,cut2,cut2,1,1,LSL,USL);
p11_d6 =  integral(@(x)  extra_CMC(x,d5,p11_d5,cut2,cut2,1,1,LSL,USL),USL,inf); 

d7 = extra_CMC(x,d6,p11_d6,cut2,cut2,1,1,LSL,USL);
p11_d7 =  integral(@(x)  extra_CMC(x,d6,p11_d6,cut2,cut2,1,1,LSL,USL),USL,inf); 

d8 = extra_CMC(x,d7,p11_d7,cut2,cut2,1,1,LSL,USL);
p11_d8 =  integral(@(x)  extra_CMC(x,d7,p11_d7,cut2,cut2,1,1,LSL,USL),USL,inf); 

d9 = extra_CMC(x,d8,p11_d8,cut2,cut2,1,1,LSL,USL);
p11_d9 =  integral(@(x)  extra_CMC(x,d8,p11_d8,cut2,cut2,1,1,LSL,USL),USL,inf);

d10 = extra_CMC(x,d9,p11_d9,cut2,cut2,1,1,LSL,USL);
p11_d10 =  integral(@(x)  extra_CMC(x,d9,p11_d9,cut2,cut2,1,1,LSL,USL),USL,inf);

TotRW = sum([RW1P,p11_d1,p11_d2,p11_d3,p11_d4,p11_d5,p11_d6,p11_d7,p11_d8,p11_d9,p11_d10]);
% figure(1)
% plot(x,d1,'-'); grid on; hold on
% plot(x,d2,'r-'); hold on
% plot(x,d3,'k-'); hold on
% plot(x,d4,'m-'); hold on
% plot(x,d5,'c-'); hold on
% plot(x,d6,'y-'); hold on
% plot(x,d7,'g-'); hold on
% plot(x,d8,'b-');

%TotRW_Markov = 1/(1-RW1P) % THIS IS THE MARKOBV CHAIN APPROACH
