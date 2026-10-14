% This routine computes the element stiffness matrix for 
% a 2-D beam Element
%
% With kind permission from P.B. Nair
% 

 function [Ke] = stiffmat(ne, NOD, X, Y, EA, EI);

% Inputs
% ne    - element number
% NOD   - connectivity matrix
% X     - X-coords of nodes
% Y     - Y-coords of nodes
% EA,EI - vectors of elastic rigidities

% Convert to local module variables
  X1 = X(NOD(ne,1)) ; Y1 = Y(NOD(ne,1));
  X2 = X(NOD(ne,2)) ; Y2 = Y(NOD(ne,2));
  L = sqrt((X2-X1)^2 + (Y2-Y1)^2);

  EAl = EA(ne);
  EIl = EI(ne);

      C=(X2-X1)/L;
      S=(Y2-Y1)/L;
      E1=EAl/L;
      E2=12.*EIl/(L*L*L);
      E3=EIl/L;
      E4=6.*EIl/(L*L);

% Define elements of K matrix
      KM(1,1)=C*C*E1+S*S*E2;
      KM(4,4)=KM(1,1);
      KM(1,2)=S*C*(E1-E2);
      KM(2,1)=KM(1,2);
      KM(4,5)=KM(1,2);
      KM(5,4)=KM(4,5);
      KM(1,3)=-S*E4;
      KM(3,1)=KM(1,3);
      KM(1,6)=KM(1,3);
      KM(6,1)=KM(1,6);
      KM(3,4)=S*E4;
      KM(4,3)=KM(3,4);
      KM(4,6)=KM(3,4);
      KM(6,4)=KM(4,6);
      KM(1,4)=-KM(1,1);
      KM(4,1)=KM(1,4);
      KM(1,5)=S*C*(-E1+E2);
      KM(5,1)=KM(1,5);
      KM(2,4)=KM(1,5);
      KM(4,2)=KM(2,4);
      KM(2,2)=S*S*E1+C*C*E2;
      KM(5,5)=KM(2,2);
      KM(2,5)=-KM(2,2);
      KM(5,2)=KM(2,5);
      KM(2,3)=C*E4;
      KM(3,2)=KM(2,3);
      KM(2,6)=KM(2,3);
      KM(6,2)=KM(2,6);
      KM(3,3)=4.*E3;
      KM(6,6)=KM(3,3);
      KM(3,5)=-C*E4;
      KM(5,3)=KM(3,5);
      KM(5,6)=KM(3,5);
      KM(6,5)=KM(5,6);
      KM(3,6)=2.*E3;
      KM(6,3)=KM(3,6);

      
      Ke = KM;
%     Ke = [KM(2:3,2:3),KM(2:3,5:6); KM(5:6,2:3),KM(5:6,5:6)];

