% This code assembles a 2D truss structure using Finite Element Method and
% then measures its response to a range of forcing frequencies. M-files
% massmat, stiffmat and assembly are called to build the global mass and
% stiffness matrices. The truss uses a mesh density of 2.

%   2     4     6     8     10    12    14    16    18    20    22
% |>o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o
%    \    |\    |\    |\    |\    |\    |\    |\    |\    |\    | o 
%      o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o  o 23
%        \|    \|    \|    \|    \|    \|    \|    \|    \|    \| o
% |>o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o--o
%   1     3     5     7     9     11    13    15    17    19    21
%

function [Imp] = confun1(x)

X=x(1:23);
Y=x(24:46);

nelem = 84; %number of beams
nnodes = 65; %number of nodes (constrained and free)


md=2;           %Mesh density
d=4*md-4;       %Difference between same placed node in each bay
L=23 + 10.5*d;  %Total number of nodes in the structure

Xinc=X;         %Assigns the first 23 slots of Xinc to original X coords



%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% X AND Y COORDINATES FOR THE INTERMEDIATE NODES WHICH DEPEND SOLELY ON THE
% LOCATIONS OF THE OUTER NODES

% Bottom horizontal members
for a=1:2:19
    b=24:2:L;
    c=b(a);
    Xinc(c)=(X(a+2) - X(a))/2 + X(a);
end
pause(5);

% Diagonal members
for a=2:2:20
    b=23:2:L;
    c=b(a);
    Xinc(c)=(X(a+1) - X(a))/2 + X(a);
end

% Top horizontal members
for a=2:2:20
    b=24:2:L;
    c=b(a);
    Xinc(c)=(X(a+2) - X(a))/2 + X(a);
end

% Vertical members
for a=4:2:22
    b=21:2:L;
    c=b(a);
    Xinc(c)=(X(a-1) - X(a))/2 + X(a);
end


% End cone

Xinc(64)= (X(23)-X(21))/2 +X(21);
Xinc(65)= (X(23)-X(22))/2 +X(22);


%                       -----------------------------
Yinc=Y;

% Bottom horizontal members
for a=1:2:19
    b=24:2:L;
    c=b(a);
    Yinc(c)=(Y(a+2) - Y(a))/2 + Y(a);
end

% Diagonal members
for a=2:2:20
    b=23:2:L;
    c=b(a);
    Yinc(c)=(Y(a+1) - Y(a))/2 + Y(a);
end

% Top horizontal members
for a=2:2:20
    b=24:2:L;
    c=b(a);
    Yinc(c)=(Y(a+2) - Y(a))/2 + Y(a);
end

% Vertical members
for a=4:2:22
    b=21:2:L;
    c=b(a);
    Yinc(c)=(Y(a-1) - Y(a))/2 + Y(a);
end

% End cone
Yinc(64)= (Y(23)-Y(21))/2 +Y(21);
Yinc(65)= (Y(22)-Y(23))/2 +Y(23);


%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% The following is the connectivity matrix. It is constructed by going
% anti-clockwise around each bay.


N2=[1:23];
N3=[24:65];

for a=1:2:20;
    Nf=N2(a:a+3);
    b=1:2:96;
    c=b(a);
    Ng=N3(c:c+3);
    d=1:4:80;
    e=d(a);
    NOD([e:e+7],:)= [Nf(1),Ng(1)
        Ng(1), Nf(3)
        Nf(3), Ng(4)
        Ng(4), Nf(4)
        Nf(4), Ng(3)
        Ng(3), Nf(2)
        Nf(2), Ng(2)
        Ng(2), Nf(3)];
end 

NOD(81,:)=[N2(21), N3(41)];
NOD(82,:)=[N3(41), N2(23)];
NOD(83,:)=[N2(23), N3(42)];
NOD(84,:)=[N3(42), N2(22)];

%--------------------------------------------------------------------------
%--------------------------------------------------------------------------


% The geometry (X and Y coordinates) of each of the nodes. Xinc and Yinc
% are now renamed X and Y as this is needed for the mass and stiffness
% matrix assembly.

X=Xinc;
Y=Yinc;
NOD=NOD;

b = ones(84,1); %Creates a vector of ones which can be used to alter the 
                %the geometry of the truss later on by a scale factor 'b'.

% Material constants of the truss.
EA0 = 69.87*10^6; me0 =2.74; EI0 = 12.86*10^3;  
EA = EA0*b;
EI = EI0*b;
me = me0*b;

% Define no. of constrained nodes. The node numbers 1 to "nconstr" are 
%assumed to be the constrained nodes. Further, these are considered to be 
%fixed (cantilevered) nodes.

nconstr = 2;

% Assemble global stiffness and mass matrices.
[K, M] = assembly(nconstr, NOD, X, Y, EA, EI, me);

% % compute eigenvalues
% eigenvals = eig(K,M);
%   
% % Compute natural frequencies in Hz
% natfreq2 = sqrt(eigenvals)/(2*pi);

  
C = 20*M;  % Assume proportional damping of the form C = alpha*K + beta*M

F = zeros((nnodes-2)*3,1); 
F(2) = 1;         % Unit loading in transverse direction at node 1, i.e, 
F=sparse(F);      % dof 2 after boundary conditions have been imposed and 
                  % zero everywhere else

%__________________________________________________________________________
%_____________________________TRUSS RESPONSE_______________________________
                             
%This calculates the magnitude of the x, y and rotational displacement over
%the frequency range 1-500Hz in steps of 2.5Hz and saves them as the vector J

frfo=zeros(189,200);
for i=1:200,
    freq= i*2.5;
    wf = 2*pi*freq;
    clear j;
    DSM = K - wf*wf*M + j*wf*C;  % DSM = Dynamic stiffness matrix
    DSM=sparse(DSM);
    frfo(:,i) = DSM\F;
    step(i) = freq;
    J(i)=sqrt((abs(frfo(61,i)))^2 + (abs(frfo(62,i)))^2 + (1.414*(abs(frfo(63,i)))^2));
end 

%Calculates the area under the curve between 100Hz and 200Hz for the
%original structure

freqJ=40:79;
for n=1:length(freqJ),
    A1(n)=((J(freqJ(n))+J(freqJ(n)+1))/2)*(2.5);
end
Area=sum(A1);

Improvement=20*log10(Area/6.4131e-005);

Imp=Improvement;

