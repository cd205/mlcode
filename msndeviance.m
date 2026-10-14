function [F,G]=msndeviance(param,X,y,freq,traceout)
F=msn_dev(param,X,y,freq,traceout);
G=-1; %vincolo fittizio -1<0
