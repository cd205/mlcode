% This routine computes the element mass matrix for 
% a 2-D beam Element
%
%  With kind permission from P.B. Nair
% 


 function [Me] = massmat(ne, NOD, X, Y, me);

% Inputs
% ne    - element number
% NOD   - connectivity matrix
% X     - X-coords of nodes
% Y     - Y-coords of nodes
% me    - vector of mass/length

% Convert to local module variables
  X1 = X(NOD(ne,1)) ;
  Y1 = Y(NOD(ne,1));
  X2 = X(NOD(ne,2)) ;
  Y2 = Y(NOD(ne,2));
  ELL = sqrt((X2-X1)^2 + (Y2-Y1)^2);

  RHO = me(ne);

      C=(X2-X1)/ELL;
      S=(Y2-Y1)/ELL;


% Consistent Mass matrix

      MM(1,1)=140.*C*C+156.*S*S;
      MM(1,2)=-16.*C*S;
      MM(1,3)=-22.*ELL*S;
      MM(1,4)=70.*C*C+54.*S*S;
      MM(1,5)=-MM(1,2);
      MM(1,6)=13.*ELL*S;

      MM(2,1)=MM(1,2);
      MM(2,2)=156.*C*C+140.*S*S;
      MM(2,3)=22.*ELL*C;
      MM(2,4)=-MM(1,2);
      MM(2,5)=54.*C*C+70.*S*S;
      MM(2,6)=-13.*ELL*C;

      
      MM(3,1)=MM(1,3);
      MM(3,2)=MM(2,3);
      MM(3,3)=4.*ELL*ELL;
      MM(3,4)=-MM(1,6);
      MM(3,5)=-MM(2,6);
      MM(3,6)=-3.*ELL*ELL;


      MM(4,1)=MM(1,4);
      MM(4,2)=MM(2,4);
      MM(4,3)=MM(3,4);
      MM(4,4)=MM(1,1);
      MM(4,5)=MM(1,2);
      MM(4,6)=-MM(1,3);

      
      MM(5,1)=MM(1,5);
      MM(5,2)=MM(2,5);
      MM(5,3)=MM(3,5);
      MM(5,4)=MM(4,5);
      MM(5,5)=MM(2,2);
      MM(5,6)=-MM(2,3);

      MM(6,1)=MM(1,6);
      MM(6,2)=MM(2,6);
      MM(6,3)=MM(3,6);
      MM(6,4)=MM(4,6);
      MM(6,5)=MM(5,6);
      MM(6,6)=MM(3,3);
      FAC=RHO*ELL/420.;

      MM = FAC*MM ;

      Me = MM;
      
 %     Me = [MM(1:2,1:2),MM(1:2,4:5); MM(4:5,1:2),MM(4:5,4:5)];

%      Me = [MM(2:3,2:3),MM(2:3,5:6); MM(5:6,2:3),MM(5:6,5:6)];

% Lumped Mass Matrix

%    MM = (RHO*ELL/96)*diag([48, 48, ELL^2, 48, 48, ELL^2]);


