function [gf,Gc]=grdnt(param,X,y,freq,traceout)
%computes gradient (used in 'constr')of dev=-2*logL
%for centred parameters 
app=msn_dev_grad(param,X,y,freq,traceout);
gf=app;
Gc=zeros(length(param),1); %derivata del vincolo -1<0


