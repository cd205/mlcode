% thickness caluclation
% determine the distribution of the wall thicknesses given the input
% distributions from the outer diameters 
clear all
close all
clc

sig11 = 1;
sig22 = 1;
SIGMA = [sig11^2 0.0 ;0.0 sig22^2]
A = [3 3];
B = [7 7];
CUT1 = [8 8];
CUT2 = CUT1;
CUT1R = A+(B-CUT1)  % convert cut1 from near to USL to near LSL
CUT2R = CUT1R;

sig11_D3 = 1.5;
sig11_D3Copula = 1
CUT_D3 = 4;

%u = rand(1,10000000);
CUT = [CUT1(1) CUT_D3]
x1 = linspace(0,10,100);
x2 = x1;
[X1 X2] = ndgrid(x1,x2);
X = [X1(:) X2(:)];
x = X(:,1);
y = X(:,2);
%Cpdf = @(x,y)FUN_2DCopula_Trun_Norm(x,y,CUT,SIGMA,A,B);
[pdf_D1 cdf_D1]= Fun_TruncatedNormalDist(x,CUT1(1),sig11,A(1),B(1));
%[pdf_D2 cdf_D2]= TruncatedNormalDist(y,CUT1R(2),sig22,A(2),B(2));
pdf_D3 = normpdf(y,CUT_D3,sig11_D3);
cdf_D3 = normcdf(y,CUT_D3,sig11_D3);
p = [sig11^2 0.0; 0.0 sig11_D3Copula^2]
Cpdf = copulapdf('Gaussian',[cdf_D1,cdf_D3],p).*pdf_D1.*pdf_D3;
Ccdf = copulacdf('Gaussian',[cdf_D1,cdf_D3],p);
Cpdf = reshape(Cpdf,length(x1),length(x2));
Ccdf = reshape(Ccdf,length(x1),length(x2));

figure(1)
h = surf(x1,x2,Cpdf'); hold on % invert the matrix for plotting hence Cpdf'
set(h,'edgecolor','none');%[0.7,0.7,0.7]);
colorbar
xlabel('x1')
ylabel('x2')
zlabel('probability density')
figure(2)
h = surf(x1,x2,Ccdf');
set(h,'edgecolor','none');%[0.7,0.7,0.7]);
colorbar
xlabel('x1')
ylabel('x2')
zlabel('cumulative density')

% determine thickness (D1 - D3) distribution

% tessalate the domain, divide into rectangles and record the probability
% densit in each rectange 
F = griddedInterpolant(X1,X2,Cpdf,'spline');
% [Xq,Yq] = ndgrid(0:0.1:10,0:0.1:10);
% Vq = F(Xq,Yq);
% figure;
% mesh(Xq,Yq,Vq);
range = [0 10];
nums = 160; % use even intervals, 10,20,40,80
xt1 = range(1)+(range(2)/nums)*0.5;
yt1 = range(1)+(range(2)/nums)*0.5;
xt = linspace(xt1,10-xt1,nums); % xt and yt are where the Cpdf is evaluated, i.e. 
yt = linspace(yt1,10-yt1,nums); % in the middle of each little square.
[Xt Yt] = ndgrid(xt,yt);
Base = ((range(2)-range(1))/nums)*((range(2)-range(1))/nums)
Vt = F(Xt,Yt);
figure(1)
plot3(Xt,Yt,Vt,'g.','MarkerSize',1); hold on
Int_density = sum(sum(Vt.*Base)) % should be 1
nparts = 1000;
for i = 1:nums
    for j = 1:nums
        t(i,j) = (Xt(i,j)-Yt(i,j));
        Numbers(i,j) = Vt(i,j)*Base*nparts;
    %marginal_x1(i) = sum(Vt(i,:));
    %marginal_y1(i) = sum(Vt(:,i));
    end
end
%plot3(Xt,Yt,Numbers,'c+','MarkerSize',10)
numsum = sum(sum(Numbers))
Numbers = Numbers(:);
tvec = min(min(t(:))):range(2)/nums:max(max(t(:)));
for i = 1:length(tvec)
    p = find(t(:)==tvec(i)); % 
    T1(i) = sum(Numbers(p));
end
figure(4)
bar(tvec,T1); grid on
sum_T1 = sum(T1)
%
% %[X Y] = meshgrid(0:2:10,0:2:10);
% x = linspace(0,10,1000);
% y = linspace(0,10,1000);
% [X,Y] = ndgrid(x,y);
% % Z = X.*Y
% % Z2 = X(:).*Y(:)
% % Z3 = reshape(Z2,length(X),length(Y))
% [pdf_D1 cdf_D1]= Fun_TruncatedNormalDist(Y(:),CUT1(1),sig11,A(1),B(1));
% cdf_D3 = normcdf(X(:),CUT_D3,sig11_D3);
% V = copulacdf('Gaussian',[cdf_D1,cdf_D3],p);
% V = reshape(V,length(X),length(Y));
% F = griddedInterpolant(X,Y,V,'spline');
% 
% 
% [Xq,Yq] = ndgrid(0:0.2:10,0:0.2:10);
% Vq = F(Yq,Xq);
% figure;
% surf(Xq,Yq,Vq);
% xlabel('x1')
% ylabel('x2')
% zlabel('Cumulative Probability')
% % input the y coordinate fitst the the x coordinate due to ndgrid
% xp = linspace(0,10,101);
% yp = xp;
% for i = 1:100
%     for j = 1:100
%         vols(j,i) = (F(yp(j+1),xp(i)) - F(yp(j),xp(i)))*(F(yp(j),xp(i+1)) - F(yp(j),xp(i)));
%     end
% end
% xpp = linspace(0.5,9.5,length(xp)-1);
% ypp = linspace(0.5,9.5,length(yp)-1);
% surf(xpp,ypp,vols)



% %%%% rv method %%%%%
% 
% D1rv = Fun_TruncatedInvNormalDist(u,CUT1(1),sig11,A(1),B(1));
% D3rv = norminv(u,CUT_D3,sig11_D3);
% 
% T1 = D1rv - D3rv;
% 
% 
% figure(1)
% plot(x,pdf_D1,'-'); grid on; hold on
% plot(x,pdf_D3,'r-')
% 
% figure(2)
% hist(T1,500);
% RW_T1 = sum(T1>3.2)/length(T1)
% Scrap_T1 = sum(T1<2.8)/length(T1)
% % determine how many compoentns will be reworked
% RW_T1_no = RW_T1*length(T1)
% u2 = rand(1,RW_T1_no);
% CUT3 = 3.2;
% % determine distribution of rewokred parts
% RW_rw = Fun_TruncatedInvNormalDist(u2,CUT3,sig11_D3,0,3.2);
% % recombine the distributions
% T1_new = [T1(T1<=3.2) RW_rw];
% figure(3)
% hist(T1_new,500)
% size(T1_new)
% 
% Totalscrap = sum(T1_new<2.8)/length(T1)
% 
% % x = 0:0.1:10; 
% % y = sin(x); 
% % plot(x,y,'.-')
% % 
% % u = [- 1 0.5 0 1]
% % % xi = 0:.25:10; 
% % % yi = interp1(x,y,xi); 
% % % plot(x,y,'o',xi,yi)