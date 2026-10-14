function est = MonteCarlo(F, bound, N)
     B = bound;
     R = rand(3, N);
     %Set the random samplings to the correct intervals
     R(1, :) = (B(2)-B(1))*R(1, :)+ B(1);
     R(2, :) = R(2, :)*(B(4) - B(3)) + B(3);
     R(3, :) = R(3, :)*(B(6) - B(5)) + B(5);
     Volume = (B(2)-B(1))*(B(4)-B(3))*(B(6)-B(5));
    
     parfor i = 1:N
        s(i) = feval(F, R(1,i), R(2,i), R(3,i));
     end
     total = sum(s);
     avgF = total/N;
     Approx = avgF*Volume;
     %fprintf('Approximation: %f', Approx);
     est = Approx;
