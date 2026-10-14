%% Test sparse Quadrature integration %%

f = @(x,y,z) x.*y.*z;
options = spset('GridType','Chebyshev','Vectorized','on');
z = spvals(f,3,[0 3; 0 2; 0 1],options);  % limits are x - [0 3]
                                          %            y - [0 2]
                                          %            Z - [0 1]
F_quad = spquad(z)