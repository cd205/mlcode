%SN    The library sn: summary information
% 
%DESCRIPTION
% 
%This library provides functions related to the skew-normal probability
%distribution, both for the univariate and the the multivariate case.
% 
%FUNCTIONS
% 
%The functions of the scalar case section are: dsn, psn, qsn, rsn,
%T_Owen, cp_to_dp, dp_to_cp, zeta, gamma1_to_lambda, sn_cumulants, sn_em,
%sn_2logL_profile, sn_mle, sn_dev, sn_dev_gh.
% 
%The functions of the multivariate section are: dmsn, rmsn, plot_dsn2,
%msn_quantities, msn_conditional, msn_cond_cum, msn_marginal,
%plot_msn_cond, msn_fit, msn_mle, msn_dev, msn_dev_grad, msn_moment_fit,
%num_deriv.
% 
%REQUIREMENTS
% 
%The statistical toolbox 'stats' and the optimisation toolbox 'optim' are required
% 
%VERSION
% 
%You are using a translation of S-plus version 0.21 (1 April 1999). The most recent version of
%the library can be obtained from the WWW page:
%http://www.stat.unipd.it/dip/homes/azzalini/SN
% 
%MANUAL
% 
%There is no manual for this version (and possibly there will never be
%one). All documentation is on-line, apart for the papers listed below,
%which provide background information. Some functions are not documented.
%
%AUTHOR
% 
%Adelchi Azzalini, Dept Statistical Sciences, University of Padua, Italy.
%Please send comments, error reports, etc. to the author via the
%abovementioned WWW page. This Matlab version has been translated 
%by Nicola Sartori.
% 
%ACKNOWLEDGEMENTS
% 
%Many thanks to Antonella Capitanio, for testing the procedures, and to
%Brian Ripley, who has kindly provided the programs to generate the
%MS-windows version from the Unix version. The function num_deriv is
%based on a similar function written by Monica Chiogna. This software and
%part of the associated theoretical work has been developed while the
%author was at the Nuffield College, Oxford, under the Jemolo Fellowship
%scheme; the generous support of the  college is gratefully acknowledged.
%Additional support for the development of the theoretical research work
%has been  provided by the "Consiglio Nazionale delle Ricerche" of Italy,
%grant no.97.01331.CT10.
% 
%REFERENCES
% 
%Azzalini, A. (1985). A class of distributions which includes the normal
%ones. Scand. J. Statist. 12, 171-178.
% 
%Azzalini, A. (1986). Further results on a class of distributions which
%includes the normal ones. Statistica 46,199-208.
% 
%Azzalini, A. and Dalla Valle, A. (1996). The multivariate skew-normal
%distribution. Biometrika 83, 715-726.
% 
%Azzalini, A. and Capitanio, A. (1999). Statistical applications of the
%multivariate skew-normal distribution. J.Roy.Statist.Soc. B 61, part 3.
% 
%LICENCE
% 
%This library and its documentation are usable under the terms of  the
%"GNU General Public License", a copy of which is distributed with the
%package.
