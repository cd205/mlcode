function pdf = Fun_TruncatedNormalDist_pdf(x,mu,sigma,a,b,ulim,ScrapFlag)
% truncated normal distribution
% see http://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/tnrcdf.pdf
% for more info on these distributions

% This switch modles the scrap probability in case1 and it is removed in #
% case 2, once the scrap components are identified and removed from the
% production process
Scrap_switch = ScrapFlag;
switch Scrap_switch
    case 1 % scrap on, model the scrap parts (before items are removed)
        I1 = (x<=b);
        %I1 = not(abs(sign(sign(a-x) + sign(ulim-x)))) % I is a vector of 1's and 0's.
        % A 1 where a<x<ulim and 0 where x is outside this range
        
        I2 = (x>=ulim); % ones where x>=ulim
        pdf = I1.*(normpdf(x,mu,sigma)./(normcdf(b ,mu,sigma) - normcdf(a,mu,sigma)));
    case 0 % scrap off
        I1 = (x>=a & x<=b);
        %I1 = not(abs(sign(sign(a-x) + sign(b-x)))); % I is a vector of 1's and 0's.
        % A 1 where a<x<ulim and 0 where x is outside this range   
        %I2 = (x>=b); % ones where x>=ulim
        pdf = I1.*(normpdf(x,mu,sigma)./(normcdf(b,mu,sigma) - normcdf(a,mu,sigma)));
end

% function pdf = Fun_TruncatedNormalDist_pdf(x,mu,sigma,a,b,ulim,ScrapFlag)
% % truncated normal distribution
% % see http://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/tnrcdf.pdf
% % for more info on these distributions
% 
% % This switch modles the scrap probability in case1 and it is removed in #
% % case 2, once the scrap components are identified and removed from the
% % production process
% Scrap_switch = ScrapFlag;
% switch Scrap_switch
%     case 1
%         I1 = not(abs(sign(sign(a-x) + sign(ulim-x)))); % I is a vector of 1's and 0's.
%         % A 1 where a<x<ulim and 0 where x is outside this range
%         
%         I2 = (x>=ulim); % ones where x>=ulim
%         pdf = I1.*(normpdf(x,mu,sigma)./(normcdf(ulim ,mu,sigma) - normcdf(a,mu,sigma)));
%     case 0
%         I1 = not(abs(sign(sign(a-x) + sign(b-x)))); % I is a vector of 1's and 0's.
%         % A 1 where a<x<ulim and 0 where x is outside this range   
%         I2 = (x>=b); % ones where x>=ulim
%         pdf = I1.*(normpdf(x,mu,sigma)./(normcdf(ulim,mu,sigma) - normcdf(a,mu,sigma)));
% end





