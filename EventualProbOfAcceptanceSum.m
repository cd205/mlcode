
Pa = 0.25
Pr = 0.2

for i = 1:100
    PA(i) = Pa*Pr^(i-1);
end

Prob_acceptance = sum(PA)

% which is the same as 
Prob_acceptance_anylitical = Pa/(1-Pr)