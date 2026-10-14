% Christopher Dodd - 04/05/2011 - cd205@soton.ac.uk
%This function iterterats the equantion x_n+1=r*(sin(x_n) and draws a map
%x_n+1 vs. n_n

clear all
clc;
format 'long'

tic

c=0.5;
count=1;
No = 4;          % max value of x_n
min=0;           % min value of x_n
div =5000;       % Number of Divisions
iters = 1500;    % NUmber of iterations
X(:,1:div+1) = rand(1,div+1); % Create inital vector

for r=min:(No-min)/div:No
       for i=2:iters               % Start loop of x values i.e x(n+1)=x(n) 
        j=i-1;                     % inital guess
        x=r*(sin(X(j,count)));     % Logistic Equation (sin)
        X(i,count)=x;
    end
    r_plot(count) = r;
    count = count+1;
end

    figure(2)
    plot(r_plot,X(1001:iters,:),'b.','MarkerSize',1)
    xlabel('r')
    ylabel('x')
    grid on
    hold on
    toc