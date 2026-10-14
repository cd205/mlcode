clear all
clc
x_0 = 1
y_0 = 1;
a = -1.5;
tc = 1;
for y_0 = -3:3
    x_0 = y_0
    %x_0 = y_0
    for t=0:0.001:3
        time(tc) = t;
        x(tc) = x_0*(exp(a*t));
        y(tc) = y_0*(exp(-t));
        tc=tc+1;

    end
end


        plot(x,y,'b.','MarkerSize',1)
        hold on