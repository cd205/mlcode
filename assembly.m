% Assembly of Global Stiffness and Mass matrix for Vibration Analysis of 
% Two-Dimensional Beam Networks
%
% PBN
%

  function [K, M] = assembly(nconstr, NOD, X, Y, EA, EI, me);

% nconstr : Number of constrained nodes
% NOD     : Connectivity matrix
% X       : Vector of X coordinates
% Y       : Vector of Y coordinates
% EA      : Vector of axial rigidities 
% EI      : Vector of flexural rigidities
% me      : Vector of mass/length

% netot = Total no. of elements
% npe = Number of nodes per element 

  [netot,npe] = size(NOD);
 
% ndf = dof per node 
  ndf = 3; 
% tdof = Total number of dof
  tdof = ndf*max(max(NOD));

 KG=zeros(tdof,tdof);
 MG=zeros(tdof,tdof);

%Assembly of Global System Matrices

 for ne = 1:netot,  % loop over elements
     for i = 1:npe,
         [KL] = stiffmat(ne, NOD, X, Y, EA, EI);
         [ML] = massmat(ne, NOD, X, Y, me);
         alp1 = (NOD(ne,i) -1)*ndf;
         for ii = 1:ndf,
             alp1 = alp1 + 1;
             l = (i-1)*ndf + ii;
             for j = 1:npe,
                 bet1 = (NOD(ne,j)-1)*ndf;
                 for jj = 1:ndf,
                     m = (j-1)*ndf + jj;
                     bet1 = bet1 + 1;
                     KG(alp1,bet1) = KG(alp1,bet1) + KL(l,m);
                     MG(alp1,bet1) = MG(alp1,bet1) + ML(l,m);
                  end;
             end;
         end;
     end;
 end;


% Incorporation of Boundary Conditions
%
% Assume clamped transverse dof for nodes from 1: nconstr
%
% 

  nc = ndf*nconstr+1;

  K =  KG(nc:tdof,nc:tdof);
  M =  MG(nc:tdof,nc:tdof);



