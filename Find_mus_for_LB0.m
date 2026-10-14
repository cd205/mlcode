

mu10 = 3
mu20 = 3
mu30 = 3
lb = [2 2 2]
ub = [5 5 5]

%%fun1 = @(mu1) abs(((1-normcdf(3,mu1,1))/normcdf(3,mu1,1))-2)
%fun2 = @(MU) abs(3*mvncdf([3,3,3],[MU],[1,1,1]) - mvncdf([3,3,3],[7,7,7],[MU],[1,1,1]))
%x1 = fmincon(fun1,mu10,[],[],[],[],2.5,5)
%x2  = fmincon(fun2,[mu10,mu20,mu30],[],[],[],[],lb,ub)

fun3 = @(MU) abs(2*(mvncdf([3,3],MU,[1,1])) - mvncdf([3,3],[7,7],MU,[1,1]))
x3 = fmincon(fun3,[mu10,mu20],[],[],[],[],lb(1:2),ub(1:2))