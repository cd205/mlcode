function [stop] = outfun(x, optimValues, state)
global fvalhist cutshist
stop = false;
fvalhist(optimValues.iteration+1) = optimValues.fval;
cutshist(optimValues.iteration+1,:) = x;
%plot(x(1),x(2),'.');
%drawnow