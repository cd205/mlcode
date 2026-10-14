function [F,G]=deviance(cp,X,y,traceout)
F=sn_dev(cp,X,y,traceout);
G=-1; %vincolo fittizio -1<0
