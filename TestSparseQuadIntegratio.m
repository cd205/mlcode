%% Test sparse Quadrature integration %%
f = @(x,y) x.*y;
options = spset('GridType','Chebyshev','Vectorized','on');
z = spvals(f,2,[0 3;0 2],options);
F_quad = spquad(z)