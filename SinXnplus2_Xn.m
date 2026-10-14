% Christopher Dodd - 04/05/2011 - cd205@soton.ac.uk
% This function iterterats the equantion x_n+1=r*(sin(x_n) or 
% x_n+1=a(1-x_n) and draws a iteratemap x_n+2 vs. x_n
clear all
clc

%%% iterate the Logisitc Equation %%%
    r=[2.5];        % parameter
for j=1:length(r)
    x_0=0.5;        % Initial value of x
    N=40;           % Number of iterations
    x(1) = x_0;     % First value in vector x is x_0
    for i=1:N
        x(i+1) = r(j)*sin(x(i));  % Uncomment for sin map
        % x(i+1) = x_i+1=a(1-xi); % Uncomment for quadratic map
    end
    
    %%% plot the map and the diagonal line y=x %%%
    xn = 0:0.000001:3.14;
   % xn_1 = r(j)*(sin(xn));   % Uncomment for 1st iterative map
    xn_2 = r(j)*(sin(xn_1));  % Uncomment for 2nd iterative map
   % xn_3 = r(j)*(sin(xn_2))  % Uncomment for 3rd iterative map
    figure(1)
    xlabel('x_n')
    ylabel('x_{n+2}')
    hold on
    grid on
    plot(xn,xn,'r-')
    %%% plot intersect point %%%
    x1=xn; y1=xn_2; x2=xn; y2=xn;
    [x,y]=curveintersect(x1,y1,x2,y2); 
    plot(x1,y1,'b',x2,y2,'r',x,y,'k.','MarkerSize',15)
    hold on;
    
   %%% Plot the cobweb part %%%
    count = 1;
    for k = 1:1:N
        x1(count) = x(k);
        count=count+1;
    end
    N=length(x2);
    line([x2(1) x2(1)],[0 x2(2)],'Color','k')
        % Plot lines and arrows on the lines
        % Change x1 or x2 or x3 as appropriate for first, second and third
        % iterative mapping
    for ic=1:N-2
        line([x2(ic) x2(ic+1)],[x2(ic+1) x2(ic+1)],'Color','k')
        size=100*abs(x2(ic)-x2(ic+1));
        ARROWH([x2(ic) x2(ic+1)],[x2(ic+1) x2(ic+1)],'k',size);
        line([x2(ic+1) x2(ic+1)],[x2(ic+1) x2(ic+2)],'Color','k')
        size=100*abs(x2(ic)-x2(ic+1));
        ARROWH([x2(ic+1) x2(ic+1)],[x2(ic+1) x1(ic+2)],'k',size);
    end
    at=text(0.2,[max(xn_1)+0.02],['r=',num2str(r(j))]); set(at,'FontSize',10);
    hold on
end


 


 
 