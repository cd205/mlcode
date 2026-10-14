
clear all
clc;
format 'long'


tic

c=0.5;
count=1;


div=100
X(:,1:div+1) = rand(1,div+1);
iters=600
r=[3.8 3.8282 3.83]
for p=1:3
    for i=2:iters % Start loop of x values i.e x(n+1)=x(n)% 
        j=i-1;                 % inital guess
        x=r(p)*(X(j,count))*(1-X(j,count));   % Logistic Equation
        X(i,count)=x;
    end
    n=[1:150]
    subplot(3,1,p)
    plot(n,X(451:iters),'b.-','MarkerSize',5)
    xlabel('n')
    ylabel('x_n')
    title(['r=',num2str(r(p))])
    grid on
    hold on
end

    toc