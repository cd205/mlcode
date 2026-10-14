function cdf = Quad_SN_pdf5(L,A,Loc,scale_D,ALPHA,MaxPPos)


fun1 = @(X) dsn(X,Loc,scale_D(MaxPPos),ALPHA(MaxPPos));

cdf = quadl(fun1,L,A(MaxPPos));

