Mu_Vec = linspace(2.5,3.5,1000);
start1 = tic;
Delta = 784.7525;
for i = 1:length(Mu_Vec)
    fun_pdf = @(X) dsn(X,Mu_Vec(i),2,0);
    P1(i) = (1-quadl(fun_pdf,-10,3))/Delta;
    %P(i) = (1-normcdf(A(MaxPPos),Mu_Vec(i),sigma_D(MaxPPos)))/Delta;
end
toc(start1)

start2 = tic;
for i = 1:length(Mu_Vec)
    fun_pdf = @(X) dsn(X,Mu_Vec(i),1,0);
    %P(i) = (1-quad(fun_pdf,-10,3))/Delta;
    P2(i) = (1-normcdf(3,Mu_Vec(i),1))/Delta;
end
toc(start2)

figure(1)
plotyy(Mu_Vec,P1,Mu_Vec,P2); grid on