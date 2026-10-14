function DMat = kDMatrix(m,PIs,alpha,delta,eta)
% Compute the S matrix
% Christopher Dodd - 2014 - Chris.S.Dodd@Gmail.com
% INPUTS -  m:      Scalar computed from Equation 3.46 
%           PIs:    Vector of transistion probabilities, e.g for 2 
%                   features PIs = [pI2,pI3,pI4,pIC,pIS].  Computed from
%                   the Probs_nVars_MultiM.m function
%           alpha:  Scalar computed from Equation 3.50 
%           delta:  Scalar given from beta + m, where beta is given from
%                   Equation 3.47.
%           eta:    Total number of rework states including inital process
%
% OUTPUTS - SMat:   The D-Matrix

DMat = ones(eta-(alpha-1),m);

DMat(1:m,1:m) = bsxfun(@times,eye(m),PIs(alpha-1:delta));
w = delta+1;              % counter for accessing relevent elemts from PIs
for i = m+1:eta-(alpha-1) % i goes from 4:7, 4:4 and 2:1 (i.e. 0) for N=3.
    v = alpha-1;          % counter for accessing relevent elemts from PIs
    for j = 1:m
        DMat(i,j) = PIs(w)*PIs(v)/(1-PIs(w)); % probabiliy fraction
        v = v+1; 
    end
    w = w + 1;
end

