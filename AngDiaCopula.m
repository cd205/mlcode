function [TOTCopula ]=AngDiaCopula(X,f1s,f2s,pI2,pIC,pIS,sig11,sig22,MU,MU_rw,L,U,rho)
% Functions for single feature rework 
cd1 = @(lim) normcdf(lim,MU(1),sig11); 
cd1rw = @(lim) normcdf(lim,MU_rw(1),sig11);
cd2 = @(lim) normcdf(lim,MU(2),sig22); 
cd2rw = @(lim) normcdf(lim,MU(2),sig22);

MU_Rrw = L(1)+(U(1)-MU_rw); % reverse the sinlge feature rework as rework happens at lower limit
cd1Rrw = @(lim) normcdf(lim,MU_Rrw(1),sig11);

% pI2Rrwthis is needed for the truncated distribution for the single reature
% rework (due to different mean) 
pI2Rrw = copulacdf('Gaussian',[cd1Rrw(L(1)),cd2rw(U(2))],rho)...
       -copulacdf('Gaussian',[cd1Rrw(L(1)),cd2rw(L(2))],rho);
pdf1_Grid = normpdf(X(:,1),MU(1),sig11);
pdf2_Grid = normpdf(X(:,2),MU(2),sig22);
cdf1_Grid = normcdf(X(:,1),MU(1),sig11);
cdf2_Grid = normcdf(X(:,2),MU(2),sig22);

% single feature rework form stage 2 and stage 3
pdf1_rw_Grid = normpdf(X(:,1),MU_rw(1),sig11);
pdf2_rw_Grid = normpdf(X(:,2),MU(2),sig22);
cdf1_rw_Grid = normcdf(X(:,1),MU_rw(1),sig11);
cdf2_rw_Grid = normcdf(X(:,2),MU(2),sig22);


% work out where function will be zero, i.e. outside the limits. Aim is to
% generate a vecotr of zeros and ones, zero where function is outside of
% limits and a one where it is inside
IX1 = (X(:,1)>=L(1) & X(:,1)<=inf); IX2 = (X(:,2)>=L(2) & X(:,2)<=U(2)); 
%IX1 = (X(:,1)>=L(1)); IX2 = (X(:,2)>=L(2)); % includes scrap
%X = [X1(:) X2(:)];
IX = [IX1 IX2];
sizeIX = size(IX);
IXV = zeros(sizeIX(1),1);
% Generate zeros and ones vector indicating where function is inside limits

for i = 1:sizeIX(1)
if IX(i,1)==1 && IX(i,2)==1
    IXV(i) = 1;
end
end
%figure;
%plot3(X(:,1),X(:,2),IXV,'r.'); grid on

% Copula for dual rework
Cpdf1 = copulapdf('Gaussian',[cdf1_Grid,cdf2_Grid],rho).*pdf1_Grid.*pdf2_Grid;
Ccdf1 = copulacdf('Gaussian',[cdf1_Grid,cdf2_Grid],rho);
Trunn= IXV.*(Cpdf1); %Trunn = reshape(Trunn,length(xp1),length(xp2));
Cft =  (f1s(4)+f2s(4)+pIC+pIS).*((IXV.*(Cpdf1))./...
    (cd2(U(2))-cd2(L(2))-pI2));

% Cpdf1 = reshape(Cpdf1,length(xp2),length(xp3));
% Ccdf1 = reshape(Ccdf1,length(xp2),length(xp3));
% figure;
% mesh(xp2,xp3,Cpdf1)
% figure;
% mesh(xp2,xp3,Cpdf1)


%Cft = reshape(Cft,length(xp1),length(xp2));
%q_Cft  = trapz(xp2,trapz(xp1,Cft))


% Copula from single feature rework 
Cpdf1_rw = copulapdf('Gaussian',[cdf1_rw_Grid,cdf2_rw_Grid],0).*pdf1_rw_Grid.*pdf2_rw_Grid;
Trunn= IXV.*(Cpdf1_rw); %Trunn = reshape(Trunn,length(xp1),length(xp2));
%q_Trunn = trapz(xp2,trapz(xp1,Trunn));
Cft_rw = (f1s(2)+f1s(3)+f2s(2)+f2s(3)).*IXV.*(Cpdf1_rw)./...
    ((cd1Rrw(U(1)) - cd1Rrw(L(1)))*(cd2rw(U(2)) - cd2rw(L(2)))); % the denominator should really the 
% difference in the CDFs i.e. copulacdf(U(1),U(2) - copulacdf(L(1),L(2)
% as it should for dual feature rework above

%Cft_rw = reshape(Cft_rw,length(xp1),length(xp2));
%q_Cft_rw  = trapz(xp2,trapz(xp1,Cft_rw))
%Cpdf1_rw = reshape(Cpdf1_rw,length(x1),length(x2));
%Ccdf1_rw = reshape(Ccdf1_rw,length(x1),length(x2));
%Cft_rw = reshape(Cft_rw,length(xp1),length(xp2));
%Totalvol = q_Cft_rw + q_Cft
TOTCopula = Cft + Cft_rw;
%q_TOTCopula = trapz(xp2,trapz(xp1,TOTCopula)) % this is same check as TotalVol