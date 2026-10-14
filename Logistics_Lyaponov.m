clear all
clc

count=1;
X = zeros(10000:5001);
X(:,1:5001) = rand(1,5001);
%nn = 0
tic
for r=3:(4-3)/5000:4
    log_add = 0;
    for i=2:10000 % Start loop of x values i.e x(n+1)=x(n)% Start a parallel loop
        j=i-1;                 % inital guess
        x=r*(X(j,count))*(1-X(j,count));   % Logistic Equation
        X(i,count)=x;
        if i>300
           %nn = nn + 1;
           logs = log(abs(r-(2*r*x)));
           log_add = log_add + logs;
           lyaponov(count) = log_add/9699;
        end
        
    end
    r_plot(count) = r;
    count = count+1;
end
linex = [3 4];
liney = [0 0];
toc
figure(1)
subplot(2,1,1)
plot(r_plot,X(301:600,:),'b.','MarkerSize',1)
xlabel('r')
ylabel('x')
title('Logistics map x_{n+1} = r x_n (1-x_n)')
grid on
hold on
subplot(2,1,2)
plot(r_plot,lyaponov,'b+-','MarkerSize',2)
xlabel('r')

title('Lyapunov Exponents')
grid on
hold on
plot(linex,liney,'r-')


    