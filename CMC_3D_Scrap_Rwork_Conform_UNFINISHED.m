% 3D Cut-measure-cut rework, coformance and scrap probability
% this codew integrates the trivariate CDF to infinity to determine 
% conformance and rework explicity  rather than from -infinity to calculate 
% scrap and conformance explicity.

% The main change to this code form 
tic
clear all
close all
clc
flag = 1;
CUT1 = [7 6 5.5];
CUT2 = [5 5 5];
sigma1_D = [2 2 2];
sigma2_D = [2 2 2];
A = [3 3 3];
B = [7 7 7];
range = [0 10] 
num = length(A);
Upper = 9; % lower bound to integrate from
% if Reverse == 1
%     Ar = B;
%     Br = A;
%     A = Ar
%     B = Br
% end


options = spset('GridType','Gauss-Patterson','Vectorized','on','RelTol',1e-5,'AbsTol',1e-9,'MaxPoints',100000,'DimensionAdaptive','on','DimadaptDegree',1);
% Create the input vector for fnorm [x1,x2,...,xn].  The method used here 
% is not very elegent but surfices
[mvd,x,y,z] = mvnCMCdist(CUT1,CUT2,sigma1_D,sigma2_D,A,B,range,flag);
funCMC3d = @(x1,x2,x3) interp3(x,y,z,mvd,x1,x2,x3);

% specifiy limits for spec limits to +Infinity (similar to
% 'Amir_SparseQuad_CMC_DA' (lines 51-85) but to +ve large number

% NOTE THAT As and Bs are reversed here compared to 'Amir_SparseQuad_CMC_DA'
% line 61-85
% for i = 1:length(A)       % define h.b 
%     temp1 = [A(i),Upper];
%     limits(i,:) = [temp1];
%     clear temp1
% end
% z = spvals(funCMC3d,num,limits,options);  
% F_A = spquad(z)

Fconform = spvals(funCMC3d,num,[3 7;3 7;3 7],options)
Conform = spquad(Fconform)

%% Determine the CDF evaluation limits
% 
% for i = 1:length(B)
%     cc = 0;
%     % first limit
%     for j1 = 1:i-1
%         fb1(j1) = A(j1);
%     end
%     fa = [B(i)];
%     for j2 = i+1:length(A)
%         cc = cc + 1;
%         fb2(cc) = A(j2);
%     end
%     % Check if variable have been created and the collate the CDFs to
%     % evaluate
%     if exist('fb1') == 0
%         CDF_Lims(i,:) = [fa,fb2];
%     elseif exist('fb2') == 0
%         CDF_Lims(i,:) = [fb1,fa];
%     else
%         CDF_Lims(i,:) = [fb1,fa,fb2];
%     end
%     clear fb1
%     clear fa
%     clear fb2
%     clear cc
% end
% 
% 
% clear Fs
% for i = 1:length(CDF_Lims(:,1))
%     clear Limits
%     limits(:,1) = Upper.*ones(length(CDF_Lims(:,1)),1);
%     limits(:,1) = CDF_Lims(i,:)';
%     z = spvals(funCMC3d,num,limits,options);
%     Fs(i) = spquad(z);
% end
% toc
% LB = max(F_A - sum(Fs),0)
% UB = F_A - max(Fs)
% 
% Fa1a2a3 = F_A
% Fb1a2a3 = Fs(1)
% Fa1b2a3 = Fs(2)
% Fa1a2b3 = Fs(3)