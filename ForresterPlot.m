
j=0
for i=0:0.01:1
    j=j+1;
    f(j)=forrester(i);
end
plot(0:0.01:1,f,'b+-')
grid on
title('Forrester Function')
xlabel('x')
ylabel('f(x)')
min(f)