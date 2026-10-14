% Christopher Dodd - 04/05/2011 - cd205@soton.ac.uk
%This function iterterats the equantion x_n+1=a(1-x_n) and draws a map
%x_n+1 vs. n_n

clear all
clc;
format 'long'
tic
count=1;
No = 3.87;          % max value of x_n
min=3.82;           % min value of x_n
div =2000;          % Number of Divisions
iters = 2000;       % NUmber of iterations
X(:,1:div+1) = rand(1,div+1); % Create inital vector

for r=min:(No-min)/div:No
    for i=2:iters              % Start loop of x values i.e x(n+1)=x(n)% 
        j=i-1;                 % inital guess
        x=r*(X(j,count))*(1-X(j,count));   % Logistic Equation
        X(i,count)=x;
    end
    r_plot(count) = r;
    count = count+1;
end

    figure(2)
    plot(r_plot,X(301:iters,:),'b.','MarkerSize',1)
    xlabel('a')
    ylabel('x')
    grid on
    hold on
    toc