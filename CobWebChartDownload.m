%%% MAKES A COBWEB PLOT FOR A LOGISTIC MAP

% compute trajectory
a=4.0;          % parameter
x0=0.2          % Initial condition 
N=40;           % Number of iterations
x(1) = x0;    
for ic=1:N
 x(ic+1) = a*x(ic)*(1-x(ic)); 
end


% plot the map function and the line y=x
clf;
t = 0:0.01:1;
plot(t,a*(t.*(1-t)),'b-+'); hold on;
 axis('square'); axis([0 1 0 1]);
 set(gca,'XTick',(0:0.1:1),'YTick',(0:0.1:1))
 grid on;

 fplot('1*y',[0 1],'r');

 

% 
% %%%%%% STEP 3: PLOT COBWEB
%  line([x(1) x(1)],[0 x(2)],'Color','g') 
%   plot(x(1), x(1),'ko');
%  for ic=1:N-1
%   line([x(ic) x(ic+1)],[x(ic+1) x(ic+1)],'Color','g')  
%   line([x(ic+1) x(ic+1)],[x(ic+1) x(ic+2)],'Color','g')
%   plot(x(ic+1), x(ic+1),'ko');
%  end
%  line([x(N) x(N+1)],[x(N+1) x(N+1)],'Color','g')
%  
%    %%%%%% STEP 4: SIGN THE PLOT
%  at=text(0.1,0.82,['a=',num2str(a)]); set(at,'FontSize',12);
% 
%  
%  