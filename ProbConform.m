function [NC] = ProbConform(Xplot,Eff35,MU,sig11,sig22,rho,pnts,MinEff)
% find Prob of conformance
[X,Y] = meshgrid(Xplot,Xplot); % create a grid of x,y cords (angle and dia)
% define correlation matrix
SIGMA = [sig11^2 rho*sig11*sig22; rho*sig11*sig22 sig22^2];
% generate points from normal distribtuion
x = mvnrnd(MU,SIGMA,pnts);

Eff35_int = interp2(X,Y,Eff35,x(:,1),x(:,2));

NC = size(find(Eff35_int <MinEff),1)/pnts; % calculate non-conformance