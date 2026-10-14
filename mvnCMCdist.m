function [mvd,x,y,z,CUT1_RWork] = mvnCMCdist(CUT1,CUT2,sigma1_D,sigma2_D,A,B,range,flag)
% Create a 3D multivariate PDF from cut-measure cut distributions

% Christopher Dodd   -   14/03/2013   -   cd205@soton.ac.uk

% INPTUS:  CUT1      - a 3 element vector of 1st cuts (CUT1 = [7 7 6])
%          CUT2      - a 3 element vector of 2nd cuts (CUT2 = [5 5 5])
%          sigma1_D  - Sigma values of this 1st cut (from diagonal of a 
%                      covariance matrix)
%          sigma1_D  - Sigma values of this 2nd cut (from diagonal of a 
%                      covariance matrix)
%          A         - 3 element vector of LSLs (A = [3 3 3])
%          B         - 3 element vector of USLs (B = [7 7 7])
%          range     - 2 elements vector for the distribution range. eg
%                      plot the CMC distribution from 0 to 10
%          flag      - if flag == 1 then plot marginal PDFs and CDFs

% OUTPUTS: mvd       - 3D matrix of the multivariate cut-measure-cut
%                      distribution
num = 100;

u=linspace(range(1),range(2),num); % 1000 equidistant numbers
[x,y,z]=meshgrid(u);
[a a_RW] = Fun_Cut_Measure_Cut_Dist(x,CUT1(1),CUT2(1),sigma1_D(1),sigma2_D(1),A(1),B(1)); % compute standard normal pdf values for x
[b b_RW] = Fun_Cut_Measure_Cut_Dist(y,CUT1(2),CUT2(2),sigma1_D(2),sigma2_D(2),A(2),B(2));
[c c_RW] = Fun_Cut_Measure_Cut_Dist(z,CUT1(3),CUT2(3),sigma1_D(3),sigma2_D(3),A(3),B(3));
% a_RW, b_RW and c_RW are the rework rates from the first cut
CUT1_RWork = [a_RW,b_RW,c_RW];
for i = 1:length(z)
    zp(i) = z(1,1,i);  % Take 1D elements of 3D array.  z(1,1,:) is not 1D
    cp(i) = c(1,1,i);  % Take 1D elements of 3D array for c
end
if flag == 1
    figure(1)
    subplot(1,2,1)
    plot(x(1,:,1),a(1,:,1));hold on
    plot(y(:,1,1),b(:,1,1),'r'); hold on
    plot(zp,cp,'m');grid on
    xlabel('x_{1,2,3}')
    ylabel('Probability Density')
end
%u = normcdf(x,5,1); % compute standard normal cdf values for x
for i = 1:length(u)
    for j = 1:length(u)
        u(j,:,i) = cumtrapz(x(j,:,i),a(j,:,i));
    end
end
%v = normcdf(y,3,0.7); % compute t3 cdf values for y
for i = 1:length(u)
    for j = 1:length(u)
        v(:,j,i) = cumtrapz(y(:,j,i),b(:,j,i));
    end
end
w = ones(length(u),length(u),length(u)); % 3D matric of ones
for j = 1:length(u)
    wp = cumtrapz(zp,cp)';
    w(:,:,j) = wp(j).*w(:,:,j);
end
if flag == 1
    figure(1)
    subplot(1,2,2)
    plot(x(1,:,1),u(1,:,1));hold on
    plot(y(:,1,1),v(:,1,1),'r'); hold on
    plot(zp,wp,'m');grid on
    xlabel('x_{1,2,3}')
    ylabel('Cumulative Density')
end


p = [1 0 0; 0 1 0; 0 0 1]; % correlation matrix for the guassian Copula
f = copulapdf('Gaussian',[u(:),v(:),w(:)],p); %compute the pdf of gaussian copula
mvd = reshape(f,num,num,num).*a.*b.*c; % create multivariate density from the product
% of the copula pdf and the marginal pdfs
% reshape f to avoid matrix
% dimension conflicts