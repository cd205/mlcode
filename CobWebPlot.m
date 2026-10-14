clear all
clc

%%% iterate the Logisitc Equation %%%
for j=1:4
    a=[3.15];        % parameter
    x_0=0.1;        % Initial value of x
    N=40;           % Number of iterations
    x(1) = x_0;     % First value in vector x is x_0
    for i=1:N
        x(i+1) = a(j)*x(i)*(1-x(i));
    end
    
    %%% plot the map and the diagonal line y=x %%%
    xn = 0:0.01:1;
    xn_1 = a(j)*(xn.*(1-xn));
    plot(xn,xn_1,'b-');
    xlabel('x_n')
    ylabel('x_{n+1}')
   
    hold on;
    %grid on;
    fplot('1*y',[0 1],'r'); % Plot the functio y=x
    
    %%% Plot the cobweb part %%%
    line([x(1) x(1)],[0 x(2)],'Color','k')
    %plot(x(1), x(1),'k.','Markersize',12);
    for ic=1:N-1
        line([x(ic) x(ic+1)],[x(ic+1) x(ic+1)],'Color','k')
        size=500*abs(x(ic)-x(ic+1));   %scale arrow size to length of lines
        ARROWH([x(ic) x(ic+1)],[x(ic+1) x(ic+1)],'k',size);
        line([x(ic+1) x(ic+1)],[x(ic+1) x(ic+2)],'Color','k')
        size=500*abs(x(ic+1)-x(ic+2));
        ARROWH([x(ic+1) x(ic+1)],[x(ic+1) x(ic+2)],'k',size);
        %plot(x(ic+1), x(ic+1),'k.','MarkerSize',12);
    end
    line([x(N) x(N+1)],[x(N+1) x(N+1)],'Color','k')
    at=text(0.5,[max(xn_1)+0.02],['a=',num2str(a(j))]); set(at,'FontSize',10);
end


 
 