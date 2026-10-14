function fit=msn_fit(X,y,freq,plotit,traceout,iter_max,x_tol,start)
%msn_fit    Fitting multivariate skew-normal distributions
% 
%DESCRIPTION
% 
%Fits a multivariate skew-normal (MSN) distribution to data, or fits a
%linear regression model with multivariate skew-normal errors, using
%maximum likelihood estimation. The outcome is then displayed in
%graphical form.
% 
%USAGE
% 
%msn_fit(X, y, freq, plotit, traceout, iter_max, x_tol )
% 
%REQUIRED ARGUMENTS
% 
%y	a matrix or a vector.  In y is a matrix, its rows refer to
% 	observations, and its columns to components of the multivariate
% 	distribution. In y is a vector, it is converted to a one-column matrix,
% 	and a scalar skew-normal distribution is fitted.
% 
%OPTIONAL ARGUMENTS
% 
%X	a matrix of covariate values. If missing, a one-column matrix of
% 	1's is created; otherwise, it must have the same number of rows of y.
% 
%freq	a vector of weights. If missing, a one-column matrix of
% 	1's is created; otherwise it must have the same number of rows of y.
% 
%plotit	logical value which controls the graphical output (default=1); see below for
% 	description.
% 
%traceout logical value which controls printing of the algorithm
%  	convergence. If traceout=1, details are printed. Default value is 0.
% 
%iter_max maximum number of iterations in the maximisation routine
%	(default is 150).
%
%x_tol	tolerance (default is 1e-8).
%
%start  starting values for the maximisation routine (see msn_mle).
%
%VALUE
% 
%a list containing the following components:
% 
%dp	a list containing the direct parameters beta, Omega, alpha.
% 	Here, beta is a matrix of regression coefficients with
% 	size(beta)=[size(X,1),size(y,2)], Omega is a covariance matrix of order
% 	size(y,2), alpha is a vector of shape parameters of length size(y,2).
% 
%logL	log-likelihood evaluated at dp.
% 
%se	a list containing the components beta, alpha, info. Here, beta
% 	and alpha are the standard errors for the corresponding point estimates;
% 	info is the observed information matrix for the working parameter, as
% 	explained below.
% 
%options the list returned by the optimizer routine; see the documentation
% 	of 'foptions' for explanation of its components. 
%test_normality	a list of with elements test and p_value, which are the value of the
% 	likelihood ratio test statistic for normality (i.e. test that all
% 	components of the shape parameter are 0), and the corresponging p-value.
% 
%SIDE EFFECTS
% 
%Graphical output is produced if (missing(freq))=1. Three plots are 
%produced, and the programs
%pauses between each two of them, waiting for any key to be
%pressed.
% 
%The first plot uses the variable y if X is missing, otherwise it uses
%the residuals from the regression. The form of this plot
%depends on the value of k=size(y,2); if k=1, an histogram is plotted with
%the fitted distribution suerimposed. If k>1, a matrix of scatterplots is
%produced, with superimposed the corresponging bivariate densities of the
%fitted distribution.
% 
%The second plot has two panels, each representing a QQ-plot of
%Mahalanobis distances. The first of these refers to the fitting of a
%multivariate normal distribution, a standard statistical procedure; the
%second panel gives the corresponding QQ-plot of suitable Mahalanobis
%distances for the multivariate skew-normal fit.
% 
%The third plot is similar to the previous one, except that PP-plots are
%produced.
% 
%DETAILS
% 
%For computing the maximum likelihood estimates, msn_fit invokes msn_mle
%which does the actual computational work; then, msn_fit displays the
%results in graphical form. The documentation of msn_mle gives details of
%the numerical procedure for maximum likelihood estimation.
% 
%Although the function accepts a vector y as input, the use of sn_mle is
%recommended in the scalar case.
% 
%BACKGROUND
% 
%The multivariate skew-normal distribution is discussed by Azzalini and
%Dalla Valle (1996); the (Omega,alpha) parametrization adopted here is
%the one of Azzalini and Capitanio (1998).
% 
%REFERENCES
% 
%Azzalini, A. and Dalla Valle, A. (1996). The multivariate skew-normal
%distribution. Biometrika 83, 715-726.
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%SEE ALSO
% 
%msn_mle, sn_mle
% 
%EXAMPLES
% 
%# a simple case
%msn_fit(NaN,[lbm,bmi,ssf])  #no matrix X
%#
%# a regression case
%a = msn_fit([ones(length(lbm),1),lbm], bmi, NaN, NaN, NaN, NaN, 1e-6)
%# uses x_tol=1e-6 and default values for the other input parameters
%# refine the previous outcome
%a1 = msn_fit([ones(length(lbm),1),lbm], bmi,  NaN, NaN, NaN, NaN, 1e-9,a_dp)

missfreq=0;
missX=0;
if nargin<8 start=NaN;
end;
if nargin<7 x_tol=1e-8;
end;
if nargin<6 iter_max=150;
end;
if nargin<5 traceout=0;
end;
if nargin<4 plotit=NaN;
end;
if nargin<3 freq=NaN;
end;
if nargin<2 error('Required arguments are missing');
end;
if isnan(iter_max) iter_max=150;
end;
if isnan(traceout) traceout=0;
end;
if isnan(plotit) plotit=1;
end;
if isnan(X) 
   X=ones(size(y,1),1);
   missX=1;
end;
if isnan(freq) 
   freq=ones(1,size(y,1));
   missfreq=1;
end;
k=size(y,2);
n=sum(freq);
m=size(X,2);
[Q,R]=qr(X);
mle=msn_mle(X,y,freq,start,traceout,iter_max,x_tol);
beta=mle.dp.beta;
Omega=mle.dp.Omega;
alpha=mle.dp.alpha;
omega=sqrt(diag(Omega))';
xi=X*beta;
if (plotit & missfreq)
   if missX
      y0=y;
      xi0=mean(xi);
   else
      y0=y-xi;
      xi0=zeros(1,k);
   end;
   if (k>1)
      for i=1:k
         for j=1:k
            subplot(k,k,(i-1)*k+j);
            if isequal(i,j)
               plot(0,0);
               text(-0.2,0,char(['Var',48+i]));
            else 
               plot(y0(:,j),y0(:,i),'k.');
               hold on;
               marg=msn_marginal(xi0,Omega,alpha,[j,i]);
               xi_marg=marg.xi;
               Omega_marg=marg.Omega;
               alpha_marg=marg.alpha;
               x1=linspace(min(y0(:,i)),max(y0(:,i)),30);
               x2=linspace(min(y0(:,j)),max(y0(:,j)),30);
               plot_dsn2(x1,x2,xi_marg,Omega_marg,alpha_marg);
               hold off;
            end;
         end;
      end;
   else %caso k=1
      y0=reshape(y0,1,length(y0));
      x=linspace(min(y0),max(y0),100);
      if missX
         dp0=[xi0,omega,alpha];
         xlab=inputname(2);
      else
         dp0=[0,omega,alpha];
         xlab='residuals';
      end;
      [a,b]=hist(y0,n^(1/3)+sqrt(n)+1);
      a=a/sum(a)/abs(b(1)-b(2)); %prob=T
      bar(b,a,1); 
      xlabel(xlab);
      ylabel('density');
      hold on;
      plot(x,dsn(x,dp0(1),dp0(2),dp0(3)),'r -');
      if n<101
         plot(y0,zeros(n,1),'ko ');
      end;
      title(inputname(2));
      hold off;
   end;
   disp('press any key to continue...');
   pause;
   subplot(1,2,1);
   pp=chi2inv([1:n]./(n+1),k);
   coeff=R\(R'\(X'*y));
   Xb=X*coeff;
   res=y-X*coeff;
   if k==1
      rad_n=((y-Xb).*((y-Xb)*inv(cov(res))))';
      rad_sn=((y-xi).*((y-xi)*inv(Omega)))';
   else
      rad_n=sum(((y-Xb).*((y-Xb)*inv(cov(res))))');
      rad_sn=sum(((y-xi).*((y-xi)*inv(Omega)))');
   end;
   axis([min(pp),max(pp),0,max(max(rad_n),max(rad_sn))]);
   hold on;
   plot(pp,sort(rad_n),' ok','Markersize',3);
   xlabel('Percentiles of chi-square distribution');
   ylabel('Mahalanobis distance');
   line(pp,pp,'Linestyle','-.','Color','k');
   title(['QQ-plot for normal distribution; ',inputname(2)]);
   hold off;
   subplot(1,2,2);
   axis([min(pp),max(pp),0,max(max(rad_n),max(rad_sn))]);
   hold on;
   plot(pp,sort(rad_sn),' ok','Markersize',3);
   xlabel('Percentiles of chi-square distribution');
   ylabel('Mahalanobis distance');
   line(pp,pp,'Linestyle','-.','Color','k');
   title(['QQ-plot for skew-normal distribution; ',inputname(2)]);
   disp('press any key to continue...');
   hold off;
   pause;
   subplot(1,2,1);
   plot([1:n]./(n+1),sort(chi2cdf(rad_n,k)),' k.');
   %xlabel('');
   %ylabel('');
   line([1:n]./(n+1),[1:n]./(n+1),'Linestyle','-.','Color','k');
   title(['PP-plot for normal distribution; ',inputname(2)]);
   subplot(1,2,2);
   plot([1:n]./(n+1),sort(chi2cdf(rad_sn,k)),' k.');
   %xlabel('');
   %ylabel('');
   line([1:n]./(n+1),[1:n]./(n+1),'Linestyle','-.','Color','k');
   title(['PP-plot for skew-normal distribution; ',inputname(2)]);
   hold off;
end;
dev_norm=msn_dev([reshape(coeff,1,size(coeff,1)*size(coeff,2)),...
      zeros(1,k)],X,y,freq);
test=dev_norm+2*mle.logL;
p_value=1-chi2cdf(test,k);
if traceout
   disp('LRT for normality (test-function, p-value): ');
   disp([test,p_value]);
end;
mle.test_normality=struct('LRT',test,'p_value',p_value);
fit=mle;


