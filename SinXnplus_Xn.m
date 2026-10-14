clear all
clc

%%% iterate the Logisitc Equation %%%
    r=[0.8 1.4];        % parameter
for j=1:length(r)
    x_0=0.5;        % Initial value of x
    N=40;           % Number of iterations
    x(1) = x_0;     % First value in vector x is x_0
    for i=1:N
        x(i+1) = r(j)*sin(x(i))%x(i)*(1-x(i));
    end
    
    %%% plot the map and the diagonal line y=x %%%
    xn = 0:0.000001:3.14;
    xn_1 = r(j)*(sin(xn));
    %xn_2 = a(j)*(xn_1.*(1-xn_1));
    %xn_3 = a(j)*(xn_2.*(1-xn_2));
    plot(xn,xn_1,'b-');
    xlabel('x_n')
    ylabel('x_{n+1}')
    hold on
    grid on
    plot(xn,xn,'r-')
    if xn_1 == xn
        interest=xn_1
        plot(xn,interesct,'k.','Markersize',18)
        hold on
        clear intersect
    end
    
    %plot(0.4286, 0.4286,'k.','Markersize',18);
    %tp=text(0.4, 0.46,['x_{f3}^*']); set(tp,'FontSize',12);
    %plot(0.7143, 0.7143,'k.','Markersize',18);
    %tx=text(0.68, 0.75,['x_{f2}^*']); set(tx,'FontSize',12);
    %plot(0.8569, 0.8596,'k.','Markersize',18);
    %tq=text(0.82, 0.9,['x_{f4}^*']); set(tq,'FontSize',12);
    hold on;
    %grid on;
    %fplot('1*y',[0 1],'r'); % Plot the functio y=x
    
   %%% Plot the cobweb part %%%
    count = 1;
    for k = 1:1:N
        x1(count) = x(k);
        count=count+1;
    end
    N=length(x1);
    line([x1(1) x1(1)],[0 x1(2)],'Color','k')
    %plot(x2(1), x2(1),'k.','Markersize',12);
    for ic=1:N-2
        line([x1(ic) x1(ic+1)],[x1(ic+1) x1(ic+1)],'Color','k')
        size=100*abs(x1(ic)-x1(ic+1));
        ARROWH([x1(ic) x1(ic+1)],[x1(ic+1) x1(ic+1)],'k',size);
        line([x1(ic+1) x1(ic+1)],[x1(ic+1) x1(ic+2)],'Color','k')
        size=100*abs(x1(ic)-x1(ic+1));
        ARROWH([x1(ic+1) x1(ic+1)],[x1(ic+1) x1(ic+2)],'k',size);
        %plot(x2(ic+1), x2(ic+1),'k.','MarkerSize',12);
    end
%    line([x2(N) x2(N+1)],[x2(N+1) x2(N+1)],'Color','k')
    at=text(0.2,[max(xn_1)+0.02],['r=',num2str(r(j))]); set(at,'FontSize',10);
    hold on
end


 


 
 