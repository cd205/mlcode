

x1 = linspace(20,50,20); % alpha
x2 = linspace(12,24,20); % beta
x3 = linspace(0,20,20);  % gamma
x4 = linspace(5,8,20);  % L/D

FFCE = @(x1,x2,x3,x4) 7.305 - 3.789.*x1 - 1.819.*x2 + 2.028.*x3 - 0.233.*x4...
     + 1.054.*x1.*x2 - 6.892.*x1.*x3 - 2.892.*x1.*x4 - 0.859.*x2.*x3 - 0.048.*x2.*x4...
     + 1.079.*x3.*x4 + 4.924.*x1.^2 + 1.033.*x2.^2 + 3.905.*x3.^2 + 1.251.*x4.^2;
 [X1 X2] = meshgrid(x1,x3);
 X = [X1(:),X2(:)];
 
 
 
 
 S = FFCE(X(:,1),30,X(:,2),6);
 S = reshape(S,length(x1),length(x2))
%  for i = 1:length(x1)
%      for j = 1:length(x2)
%          F(j,i) = FFCE(x1(i),x2(j),x3,x4);
%      end
%  end
figure(1)
surf(x1,x2,S)
xlabel('x1'); ylabel('x2')