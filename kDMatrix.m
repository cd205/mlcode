function DMat = kDMatrix(m,PIs,alpha,delta,eta)
% computes only the D matrix, 
% 

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

