% Mahalanobios Distance
%create a random vector

X = mvnrnd([0 0],[1 0.0001; .0001 1],100)

Y = [4,4]

D = mahal(Y,X)

figure;
scatter(X(:,1),X(:,2))
hold on
scatter(Y(:,1),Y(:,2),'r+'); grid on