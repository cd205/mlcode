function [stop] = outfun2(x2, optimValues, state)
global fvalhist2 cutshist2
stop = false;
fvalhist(optimValues.iteration+1) = optimValues.fval;
cutshist(optimValues.iteration+1,:) = x2;
%plot(x(1),x(2),'.');
%drawnow