function [gf,Gc]=gradient(cp,X,y,traceout)
%computes gradient (used in 'constr')of dev=-2*logL
%for centred parameters 
app=sn_dev_gh(cp,X,y,traceout);
gf=getfield(app,'gradient');
Gc=zeros(length(cp),1); %derivata del vincolo -1<0


