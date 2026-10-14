function f=quadratic(x)
%
%  f=quadratic(x)
% This function takes an input vector and sample data 
% and returns a prediction of a second order least 
% squares fit of the sample data at the location of
% the input vector.
%
% Inputs:  x (k x 1 vector where k < 3
%          ModelInfo.y (n x 1 vector)
%          ModelInfo.X (n x k vector)
%
% Outputs: f (scalar)
%
global ModelInfo
X=ModelInfo.X;
y=ModelInfo.y;
k=size(ModelInfo.X,2);

if k==1
A(:,1)=X(:).^2;
A(:,2)=X(:);
A(:,3)=ones(length(y),1);
a=inv(A'*A)*A'*y;
f=a(1)*x^2+a(2)*x+a(3);
else
A(:,1)=X(:,1).^2;
A(:,2)=X(:,2).^2;
A(:,3)=X(:,1).*X(:,2);
A(:,4)=X(:,1);
A(:,5)=X(:,2);
A(:,6)=ones(length(y),1);
a=inv(A'*A)*A'*y;
f=a(1)*x(1)^2+a(2)*x(2)^2+a(3)*x(1)*x(2)+a(4)*x(1)+a(5)*x(2)+a(6);
end
