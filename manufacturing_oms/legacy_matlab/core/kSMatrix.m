function SMat = kSMatrix(k,alpha,eta,m,UP,UPv)

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


