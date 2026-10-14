function SMat = kSMatrix(k,alpha,eta,m,UP,UPv)
% Compute the S matrix
% Christopher Dodd - 2014 - Chris.S.Dodd@Gmail.com
% INPUTS -  k:      Scalr giving the k conbination, e.g. 1,2,3,...,n.
%                   There is an S-matrix for each k value.
%           alpha:  Scalar computed from Equation 3.50 
%           eta:    Total number of rework states including inital process
%           m:      Scalar computed from Equation 3.46 
%           UP:     The Upsilon set, Equation 3.48
%           UPv     A k subset from the Upsilon set.
%
% OUTPUTS - SMat:   The S-Matrix
Ctemp = UP{k};
for i = 1:eta - alpha + 1
    z = alpha - 2 + i;
    for j = 1:m
        mem = ismember(Ctemp(j,:),UPv{z}); % check is C vals are part of 
                                           % UPSILON set
        gamma = all(mem == 1);          % make sure all member of C are 
                                        % part of UPSILON set
        SMat(i,j) = gamma;              % populate S-matrix.  Recall there
    end                                 % is an S-matrix for every k-value.
end


