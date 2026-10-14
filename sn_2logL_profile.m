function prof=sn_2logL_profile(X,y,param_range,use_cp,npts,plotit)
%sn_2logL_profile
%Profile twice loglikelihood for skew-normal models
% 
%DESCRIPTION
% 
%Computation and plot of 1-dimensional and 2-dimensional profile
%2*loglikelihood for skew-normal regression models.
% 
%USAGE
% 
%sn_2logL_profile(X, y, param_range, use_cp, npts, plotit)
% 
%REQUIRED ARGUMENTS
% 
%y	a numeric vector. Missing values (NaN) are not allowed.
% 
%OPTIONAL ARGUMENTS
% 
%X	a matrix of explantory variables; must have size(X,2) equal to
% 	length(y). Missing values (NaN) are not allowed. If X is missing, a
% 	one-column matrix of 1's is created.
% 
%param_range	a numeric vector of length either 2 or 4. If the length
% 		is 2, the dimensional paramter d is set to 1, and a 1-dimensional
% 		profile is computed and plotted, for the shape or skewness parameter
% 		(depending on the parametrization adopted; see below); in this case the
% 		two value represent the minimum and maximum value for the range of the
% 		parameter. If the length of param.range is 4, the first two values
% 		determine the range of the scale parameter, the last two give the range
% 		of the shape (or skewness) parameter; in this case, d=2.
%		Default is [sqrt(var(y)) .* [0.67, 1.5], -0.95, 0.95]. 
%
%use_cp	logical value which selects the parametrization adopted. If
% 	use.cp=1 (default value), the centred parametrization is used, otherwise
% 	the direct parametrization is adopted.
% 
%npts	number of points (in the scalar case) or grid size (in the 2-dimensional case).
%	Default is 31/d. 
%
%plotit	logical value which determines is plotting takes place; default
% 	is 1.
% 
%VALUE
% 
%a list containing the following components
% 
%param1, param2	vectors of the paramters values where the function has
% 		been evaluated. If d=2, the second vector contains NaN.
% 
%param_names	a character vector of two elements with the names of the
% 		param1 and param2
% 
%2logL	a vector or a matrix which represents twice the profile
% 	loglikelihood; this is in the "relative" version, i.e. setting the
% 	maximum value to be 0.
% 
%maximum	a numeric value with the maximum which has been subtracted to
% 	obtain the "relative" version of 2logL.
% 
%SIDE EFFECTS
% 
%If plotit=1, a plot of the profile twice relative loglikeliood is
%produced on a graphical device.
% 
%DETAILS
% 
%Likelihood maximization is performed by sn_em.
% 
%See the reference below for explanation of the two possible
%parametrizations.
% 
%REFERENCES
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%sn_em, sn_mle
% 
%EXAMPLES
% 
%a = sn_2logL_profile(NaN,otis)
%a = sn_2logL_profile(NaN,otis,NaN,0)
%a = sn_2logL_profile([ones(length(lbm),1),lbm],bmi,[0,0.9],NaN,50)
%a = sn_2logL_profile(NaN,frontier, [0.8,1.6,10,30],0,11)

%da vedere per 'varargin'
%plot 1D or 2D profile deviance (=-2logL) using either parameters
if nargin<2 error('Required arguments are missing');
end;
if nargin<3 param_range=[sqrt(var(y)).*[0.67,1.5],-0.95,0.95];
end;
if isnan(param_range) 
   param_range=[sqrt(var(y)).*[0.67,1.5],-0.95,0.95];
end;
n=length(y);
y=reshape(y,n,1); %si assicura che y sia un vettore colonna
d=round(length(param_range)/2);
if (d~=1 & d~=2) error('length(param_range) must be either 2 or 4');
end;
if nargin<4 use_cp=1;
end;
if nargin<5 npts=fix(31/d);
end;
if nargin<6 plotit=1;
end;
if isnan(X) X=ones(n,1);
end;
if isnan(param_range) 
   param_range=[sqrt(var(y)).*[0.67,1.5],-0.95,0.95];
end;
if isnan(use_cp) use_cp=1;
end;
if isnan(npts) npts=fix(31/d);
end;
if isnan(plotit) plotit=1;
end;
%fine inizializzazione variabili
if d==1
   param1=linspace(param_range(1),param_range(2),npts);
%   param1=[param_range(1),param_range(1)+...
%         (1:(npts-1))*(param_range(2)-param_range(1))/(npts-1)];
   llik=repmat(NaN,1,npts);
   param2=llik;
else
   param1=linspace(param_range(1),param_range(2),npts);
   param2=linspace(param_range(3),param_range(4),npts);
%   param1=[param_range(1),param_range(1)+...
%         (1:(npts-1))*(param_range(2)-param_range(1))/(npts-1)];
%   param2=[param_range(3),param_range(3)+...
%         (1:(npts-1))*(param_range(4)-param_range(3))/(npts-1)];
   llik=repmat(NaN,npts,npts);
end;
if use_cp
   if d==1
      gamma1=param1;
      sigma=param2;
      xlab='\gamma_1';
      ylab='';
   else
      sigma=param1;
      gamma1=param2;
      xlab='\sigma';
      ylab='\gamma_1';
   end;
   if max(abs(gamma1))>0.9952719 error('abs(gamma1)>0.9952719');
   end;
   lambda=gamma1_to_lambda(gamma1);
   sc=sqrt(1-(2/pi)*lambda.^2./(1+lambda.^2));
else %use dp
   if d==1
      lambda=param1;
      omega=param2;
      xlab='\lambda';
      ylab='';
   else
      omega=param1;
      sc=ones(1,npts);
      lambda=param2;
      xlab='\omega';
      ylab='\lambda';
   end;
end;
disp(['Running until',num2str(npts),':']);
for i=1:npts
   disp(i);
   if d==1
      a=sn_em(X,y,[NaN,NaN,lambda(i)]); %da vedere 'varargin'
      llik(i)=getfield(a,'logL');
   else
      for j=1:npts,
         a=sn_em(X,y,[NaN,param1(i)/sc(j),lambda(j)]); %da vedere 'varargin'
         llik(i,j)=getfield(a,'logL');
      end;
   end;
end;
sprintf('\n');%va a capo
maximum=max(max(llik));
f=2*(llik-maximum);
if plotit
   if d==1
      plot(param1,f,'k -');
      xlabel(xlab);
      ylabel('profile relative 2(logL)');
   else
      cs=contour(param1',param2',f',-[0.57,1.37,2.77,4.6,5.99,9.2],'k-');
      xlabel(xlab);
      ylabel(ylab);
      clabel(cs);
      grid off;
   end;
   title('Profile relative 2(logLikekihood)');
end;
prof=struct('param1',param1,'param2',param2,'param_names',[xlab,ylab],...
   'two_logL',f,'maximum',2*maximum);

            
            
            



   
   
     
