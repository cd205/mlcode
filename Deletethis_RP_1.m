% delete
clear all
clc
x = [5 4 8 0 5 2 5];
y = [4];
x = reshape(x,length(x),1);
SIGMA = [1 0; 0 1]
A = [3 3];
B = [7 7];
CUT1 = [7 7];
CUT2 = [6 5];
cut1R = A+(B-CUT1);  % convert cut1 from near to USL to near LSL
cut2R = A+(B-CUT2);  % convert cut2 from near to USL to near LSL
RworkPrt = 0.2
TotEvals = 0
%if length(x)>length(y)
    df = zeros(length(x),1);
    % if x(i)>=A(1) && y>=A(2) 
    xGA1 = not(abs(sign(sign(A(1)-x) + sign(1000-x))))  % all x's greater than A1
    yGA2 = y>=A(2).*ones(length(x),1)
    Evals = xGA1.*yGA2
    yvec = y.*ones(length(x(find(xGA1==1))),1);
    cut1Rvec = [cut1R(1).*ones(length(x(find(xGA1==1))),1) cut1R(2).*ones(length(x(find(xGA1==1))),1)];
    cut2Rvec = [cut2R(1).*ones(length(x(find(xGA1==1))),1) cut2R(2).*ones(length(x(find(xGA1==1))),1)];
    df(find(xGA1==1)) = mvnpdf([x(find(xGA1==1)),yvec],cut1R,SIGMA) + RworkPrt*mvnpdf([x(find(xGA1==1)),yvec],cut2R,SIGMA)
    
    xLA1 = not(abs(sign(sign(-1000-x) + sign(A(1)-x)))) % all x's less than A1
    xGB1 = not(abs(sign(sign(B(1)-x) + sign(1000-x))))  % all x's greater than B1
    xLB1 = not(abs(sign(sign(-1000-x) + sign(B(1)-x))))  % all x's less than B1
    if y>=A(2)
        disp('statement number 1')
        yvec = y.*ones(length(x(find(xGA1==1))),1);
        cut1Rvec = [cut1R(1).*ones(length(x(find(xGA1==1))),1) cut1R(2).*ones(length(x(find(xGA1==1))),1)];
        cut2Rvec = [cut2R(1).*ones(length(x(find(xGA1==1))),1) cut2R(2).*ones(length(x(find(xGA1==1))),1)];
        df(find(xGA1==1)) = mvnpdf([x(find(xGA1==1)),yvec],cut1R,SIGMA) + RworkPrt*mvnpdf([x(find(xGA1==1)),yvec],cut2R,SIGMA)
        TotEvals = TotEvals + length(yvec)
    end
    while TotEvals<length(x) && y>=B(2) % top left corner
        disp('statement number 2')
        yvec = y.*ones(length(x(find(xLA1==1))),1)
        cut1Rvec = [cut1R(1).*ones(length(x(find(xLA1==1))),1) cut1R(2).*ones(length(x(find(xLA1==1))),1)];
        cut2Rvec = [cut2R(1).*ones(length(x(find(xLA1==1))),1) cut2R(2).*ones(length(x(find(xLA1==1))),1)];
        df(find(xLA1==1)) = mvnpdf([x(find(xLA1==1)),yvec],cut1R,SIGMA) + RworkPrt*mvnpdf([x(find(xLA1==1)),yvec],cut2R,SIGMA)
        TotEvals = TotEvals + length(yvec)
    end
    while TotEvals<length(x) && y<A(2) % bottom right side corner
        disp('statement number 3')
        yvec = y.*ones(length(x(find(xGB1==1))),1)
        cut1Rvec = [cut1R(1).*ones(length(x(find(xGB1==1))),1) cut1R(2).*ones(length(x(find(xGB1==1))),1)];
        cut2Rvec = [cut2R(1).*ones(length(x(find(xGB1==1))),1) cut2R(2).*ones(length(x(find(xGB1==1))),1)];
        df(find(xGB1==1)) = mvnpdf([x(find(xGB1==1)),yvec],cut1R,SIGMA) + RworkPrt*mvnpdf([x(find(xGB1==1)),yvec],cut2R,SIGMA)
        TotEvals = TotEvals + length(yvec)
    end
    while TotEvals<length(x) && y<B(2) % this does green region
        disp('statement number 4')
        yvec = y.*ones(length(x(find(xLB1==1))),1)
        cut1Rvec = [cut1R(1).*ones(length(x(find(xLB1==1))),1) cut1R(2).*ones(length(x(find(xLB1==1))),1)];
        cut2Rvec = [cut2R(1).*ones(length(x(find(xLB1==1))),1) cut2R(2).*ones(length(x(find(xLB1==1))),1)];
        df(find(xLB1==1)) = mvnpdf([x(find(xLB1==1)),yvec],cut1R,SIGMA) + RworkPrt*mvnpdf([x(find(xLB1==1)),yvec],cut2R,SIGMA)
        TotEvals = TotEvals + length(yvec)
    end
%end
% determine which elements are between A(1) and 1000
% gy1 = not(abs(sign(sign(A(2)-y) + sign(1000-y))))

