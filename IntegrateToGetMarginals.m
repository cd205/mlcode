
clear all
close all
clc
nums = 121
U = [1.5 1.5];
L = [-1.5 -1.5];
rho = 0.0
sig11 = 1; sig22 = 1
MU = [0 0]; SIGMA = [sig11 rho*sig11*sig22; rho*sig11*sig22 sig22];
x1 = linspace(-4,4,nums); x2 = linspace(-4,4,nums);
[X1,X2] = meshgrid(x1,x2);
X = [X1(:) X2(:)];
fun = @(X1,X2) mvnpdf([X1 X2],MU,SIGMA);
surf(X1,X2,reshape(fun(X1(:),X2(:)),nums,nums));

% figure;
% %pdf = tmvnorm_2varCORR(X1(:),X2(:),MU,sig11,sig22,rho,L,U);
% pdf = @(X1,X2) exp( -1./(2*(1-rho^2)).*( ((X1-MU(1)).^2./(sig11^2)) + ((X2-MU(2)).^2./(sig22^2))...
%     - ((2*rho.*(X1-MU(1)).*(X2-MU(2)))./(sig11*sig22))  ) );
% 
% surf(X1,X2,reshape(pdf(X1(:),X2(:)),nums,nums))
% 
% figure;
% truncpdf = tmvnorm_2varCORR(X1,X2,MU,sig11,sig22,rho,L,U);
% surf(X1,X2,reshape(truncpdf ,nums,nums))
int1= @(x1)integral(@(x2)fun(x1,x2),-20,20,'ArrayValued',true);
% 

for i = 1:length(x1)
    marginal(i) = int1(x1(i));
    for j = 1:length(x2)
    t(j) = fun(x2(j),x1(i))./(U(1)-L(1));
    end
    test(i) = sum(t);
end
marg = normpdf(x1,MU(1),1);
figure;
plot(x1,marginal,'.-'); grid on; hold on
plot(x1,marg,'r+')
plot(x1,test,'k*')

%Truncpdf = tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U);
fun2 = @(X1,X2) tmvnorm_2var(X1,X2,MU,sig11,sig22,rho,L,U)
figure(3)
surf(X1,X2,reshape(fun2(X1,X2),nums,nums))
qSurf = integral2(fun2,-20,20,-20,20)
int2= @(x2)integral(@(x1)fun2(x1,x2),-100,100,'ArrayValued',true);

xn = linspace(-4,4,101);
for i = 1:length(xn)
    i
    marginal2(i) = int2(xn(i));
end

marg2 = @(x1)  Fun_TruncatedNormalDist_pdf(x1,MU(1),SIGMA(1,1),L(1),U(1),U(1),0);
figure(4);
plot(xn,marginal2,'.-'); grid on; hold on
plot(x1,marg2(x1),'r+')

q1 = trapz(xn,marginal2)
q2 = trapz(x1,marg2(x1))
qq1 = integral(marg2,-100,100)
%qq2 = integral(int2,-100,100)
pd = makedist('Normal')
t = truncate(pd,L(1),U(1))
plot(x1,pdf(t,x1),'g.')
q3 = trapz(x1,pdf(t,x1))

