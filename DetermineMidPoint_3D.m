clear all
close all
clc

mu1 = 4;
mu2 = 4;
mu3 = linspace(3.1,3.2,30);


parfor i = 1:length(mu3)
    s1 = Fun_3DConformanceBox(mu1,mu2,mu3(i));
    LB(i) = s1.Fb1b2b3 - (s1.Fa1b2b3 + s1.Fb1a2b3 + s1.Fb1b2a3);
    if LB(i) < 0
        LB(i) = 0;
    end
    UB(i) = s1.Fb1b2b3 - max([s1.Fa1b2b3 s1.Fb1a2b3 s1.Fb1b2a3]);
    Conform(i) = s1.Conform
    UBerror(i) = s1.Fa1b2b3 + s1.Fb1a2b3;
    TwiceError(i) = 2*(s1.Fa1a2b3 + s1.Fa1b2a3 + s1.Fb1a2a3 - s1.Fa1a2a3);
end
    
LB
UB
UBerror
TwiceError

figure(1)
subplot(1,2,1)
plot(mu3,Conform-LB,'b.-'); hold on
plot(mu3,UB-Conform,'r.-')
xlabel('Location mu1 & mu2')
ylabel('Distance from exact solution to bounds')
legend('LB error','UB error')
grid on

subplot(1,2,2)
plot(mu3,TwiceError,'b.-'); hold on
plot(mu3,UBerror,'r.-')
xlabel('mu3')
ylabel('relative errors')
grid on