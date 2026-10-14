function optplot(x)

X = [0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10,11];
Y = [0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0.5];


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

frfo=zeros(189,500);
for i=1:500,
    %freq= i*2.5;
    freq= i;
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
    A0(n)=((J(freqJ(n))+J(freqJ(n)+1))/2)*(2.5);
end
Area0=sum(A0);

%__________________________________________________________________________
%__________________________________NEW TRUSS_______________________________

X=x(1:23);
Y=x(24:46);

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

Xbest=Xinc;
Ybest=Yinc;

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
%_________________________NEW TRUSS RESPONSE_______________________________
                             
%This calculates the magnitude of the x, y and rotational displacement over
%the frequency range 1-500Hz in steps of 2.5Hz and saves them as the vector J

frfo=zeros(189,500);
%freqband=40:80;
freqband=100:200;
    for i=1:length(freqband),
        %freq= (i+39)*2.5;
        freq= (i+99);
        wf = 2*pi*freq;
        clear j;
        DSM = K - wf*wf*M + j*wf*C;  
        frfo(:,i) = DSM\F;
        step1(i) = freq;
        Z(i)=sqrt((abs(frfo(61,i)))^2 + (abs(frfo(62,i)))^2 + (1.414*(abs(frfo(63,i)))^2));
    end

%Calculates the area under the curve between 100Hz and 200Hz for the
%original structure

freqZ=40:79;

for n=1:length(freqZ),
    A1(n)=((Z(n)+Z(n+1))/2)*(2.5);
end
Areabest=sum(A1);

Improvement=-20*log10(Areabest/6.4131e-005)

%__________________________________________________________________________
%______________________________PLOTTING FIGURES____________________________


%Creates a matrix that can be used to plot the structure after optimisation
for n=1:length(NOD),
    X1(n)=Xinc(NOD(n,1));
    Y1(n)=Yinc(NOD(n,1));
end
X1(length(NOD)+1)=X(NOD(length(NOD),2));
Y1(length(NOD)+1)=Y(NOD(length(NOD),2));


%Creates the plots of the best truss shape and its frequency response
%against that of the original truss.

figure
semilogy(step,J,'k');
axis([100 200 1E-8 1E-5]);
xlabel('frequency (Hz)','FontSize',12)
ylabel('displacement at tip node (m)','FontSize',12)

% plot frequency response of total displacement at node 23,
hold on
semilogy(step1,Z,'k--');

l=legend('regular truss','optimized truss');
set(l,'FontSize',12)
set(gca,'FontSize',12)
print -djpeg FreqResponse.eps



