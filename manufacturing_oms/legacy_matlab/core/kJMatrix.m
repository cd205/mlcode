function JMat = kJMatrix(m,PIs,alpha,delta,eta)
% computes only the D matrix, 
% 

JMat = ones(eta-(alpha-1),m);

for i = 1:eta-(alpha-1)     
    for j = 1:m
        JMat(i,j) = 99; % probabiliy fraction
    end
end

