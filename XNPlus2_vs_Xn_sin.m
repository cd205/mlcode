
clear all
clc

%%% iterate the Logisitc Equation %%%
    a=[3.84];        % parameter
for j=1:length(a)
    x_0=0.6;        % Initial value of x
    N=40;           % Number of iterations
    x(1) = x_0;     % First value in vector x is x_0
    for i=1:N
        x(i+1) = a(j)*x(i)*(1-x(i));
    end
    
    %%% plot the map and the diagonal line y=x %%%
    xn = 0:0.000001:1;
    xn_1 = a(j)*(xn.*(1-xn));
    xn_2 = a(j)*(xn_1.*(1-xn_1));
    xn_3 = a(j)*(xn_2.*(1-xn_2));
    plot(xn,xn_2,'b-');
    xlabel('x_n')
    ylabel('x_{n+3}')
    hold on
    %plot(xn,xn,'r-')
    
    %%% Plot the intersect points %%%
    x1=xn; y1=xn; x2=xn; y2=xn_2; 
    [x,y]=curveintersect(x1,y1,x2,y2); 
    plot(x1,y1,'r',x2,y2,'b',x,y,'k.','MarkerSize',15)
    hold on 
    %plot(xn,xn,'r-')
    xt1=0.42:0.001:0.54;
    yt1=-xt1;
    plot(xt1,(yt1+0.976),'k-')
    xt2=0.52:0.001:0.56;
    grid on
    yt2=-xt2;
    plot(xt2,yt2,'m-')
    grid on
    plot(0.4286, 0.4286,'k.','Markersize',18);
    tp=text(0.4, 0.46,['x_{f3}^*']); set(tp,'FontSize',12);
    plot(0.7143, 0.7143,'k.','Markersize',18);
    tx=text(0.68, 0.75,['x_{f2}^*']); set(tx,'FontSize',12);
    plot(0.8569, 0.8596,'k.','Markersize',18);
    tq=text(0.82, 0.9,['x_{f4}^*']); set(tq,'FontSize',12);
    hold on;
    grid on;
    fplot('1*y',[0 1],'r'); % Plot the function y=x
    
    %%% Plot the cobweb part %%%
    count = 1;
    for k = 1:2:N
        x2(count) = x(k);
        count=count+1;
    end
    N=length(x2);
    line([x2(1) x2(1)],[0 x2(2)],'Color','k')
    %plot(x2(1), x2(1),'k.','Markersize',12);
    for ic=1:N-2
        line([x2(ic) x2(ic+1)],[x2(ic+1) x2(ic+1)],'Color','k')
        size=1800*abs(x2(ic)-x2(ic+1));
        ARROWH([x2(ic) x2(ic+1)],[x2(ic+1) x2(ic+1)],'k',size);
        line([x2(ic+1) x2(ic+1)],[x2(ic+1) x2(ic+2)],'Color','k')
        ARROWH([x2(ic+1) x2(ic+1)],[x2(ic+1) x2(ic+2)],'k',size);
        %plot(x2(ic+1), x2(ic+1),'k.','MarkerSize',12);
    end
%    line([x2(N) x2(N+1)],[x2(N+1) x2(N+1)],'Color','k')
    at=text(0.2,[max(xn_1)+0.02],['a=',num2str(a(j))]); set(at,'FontSize',10);
end


 


 
 