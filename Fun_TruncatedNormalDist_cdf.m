function cdf = Fun_TruncatedNormalDist_cdf(x,mu,sigma,a,b,ulim,ScrapFlag)
% truncated normal distribution
% see http://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/tnrcdf.pdf
% for more info on these distributions

Scrap_switch = ScrapFlag;
switch Scrap_switch
    case 1 % scrap on, model the scrap parts (before items are removed)
        a = a-10*sigma; % set the lower bound 10 sigma from the lower limit
        % so it is not truncated at lower limit
        I1 = not(abs(sign(sign(a-x) + sign(ulim-x)))); % I is a vector of 1's and 0's.
        % A 1 where a<x<ulim and 0 where x is outside this range 
        I2 = (x>=ulim); % ones where x>=ulim   
        cdf = I1.*((normcdf(x,mu,sigma) - normcdf(a,mu,sigma))./...
            (normcdf(b,mu,sigma) - normcdf(a,mu,sigma)));
        if sum(I2)>0
            cdf(end-sum(I2)+1:end) = 1;
        end
    case 0 % scrap off
        I1 = not(abs(sign(sign(a-x) + sign(b-x)))); % I is a vector of 1's and 0's.
        % A 1 where a<x<ulim and 0 where x is outside this range 
        I2 = (x>=b); % ones where x>=ulim   
        cdf = I1.*((normcdf(x,mu,sigma) - normcdf(a,mu,sigma))./...
            (normcdf(b,mu,sigma) - normcdf(a,mu,sigma)));
        if sum(I2)>0
            %cdf(length(cdf)-sum(I2)+1:end) = cdf(length(x)-sum(x>=b)+1);
            cdf(length(cdf)-sum(I2)+1:end) = ((normcdf(b,mu,sigma) - normcdf(a,mu,sigma))./...
            (normcdf(ulim,mu,sigma) - normcdf(a,mu,sigma)));
        end        
end

% function cdf = Fun_TruncatedNormalDist_cdf(x,mu,sigma,a,b,ulim,ScrapFlag)
% % truncated normal distribution
% % see http://www.itl.nist.gov/div898/software/dataplot/refman2/auxillar/tnrcdf.pdf
% % for more info on these distributions
% 
% Scrap_switch = ScrapFlag;
% switch Scrap_switch
%     case 1 % scrap on, model the scrap parts (before items are removed)
%         I1 = not(abs(sign(sign(a-x) + sign(ulim-x)))); % I is a vector of 1's and 0's.
%         % A 1 where a<x<ulim and 0 where x is outside this range 
%         I2 = (x>=ulim); % ones where x>=ulim   
%         cdf = I1.*((normcdf(x,mu,sigma) - normcdf(a,mu,sigma))./...
%             (normcdf(ulim,mu,sigma) - normcdf(a,mu,sigma)));
%         if sum(I2)>0
%             cdf(end-sum(I2)+1:end) = 1;
%         end
%     case 0 % scrap off
%         I1 = not(abs(sign(sign(a-x) + sign(b-x)))); % I is a vector of 1's and 0's.
%         % A 1 where a<x<ulim and 0 where x is outside this range 
%         I2 = (x>=b); % ones where x>=ulim   
%         cdf = I1.*((normcdf(x,mu,sigma) - normcdf(a,mu,sigma))./...
%             (normcdf(ulim,mu,sigma) - normcdf(a,mu,sigma)));
%         if sum(I2)>0
%             %cdf(length(cdf)-sum(I2)+1:end) = cdf(length(x)-sum(x>=b)+1);
%             cdf(length(cdf)-sum(I2)+1:end) = ((normcdf(b,mu,sigma) - normcdf(a,mu,sigma))./...
%             (normcdf(ulim,mu,sigma) - normcdf(a,mu,sigma)))
%         end        
% end