function f=Normfun_nD2(x1,x2,x3,x4)
global Variability
%x=x';   % mvnpdf need takes columns as variables and rows as number of 
        % samples but mcint work the oposite way around hence the transpose
        % is taken (x=x') then it is transposed back (f=f', line 8)
MU = Variability.Mu;       % mcint function does not allow passing of extra 
SIGMA = Variability.Sigma; % parameters so used global variables instead
f = mvnpdf([x1,x2,x3,x4],MU,SIGMA);
%f = f';
%f = exp( -sqrt( (x(1,:).^2+x(2,:).^2) ) );