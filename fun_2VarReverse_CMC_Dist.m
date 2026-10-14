function [df] = fun_2VarReverse_CMC_Dist(x,y,SIGMA,CUT1,CUT2,A,B)
check = 0;
% cuts = [7 5 7 5];
% CUT1 = [cuts(1) cuts(2)];
% CUT2 = [cuts(3) cuts(4)];
% sigma11 = 1
% sigma22 = 1
% SIGMA = [sigma11^2 0.0; 0.0 sigma22^2];
% A = [3 3];
% B = [7 8];
% x = [1]
% y = [1]



cut1R = A+(B-CUT1);  % convert cut1 from near to USL to near LSL
cut2R = A+(B-CUT2);  % convert cut2 from near to USL to near LSL


% now take CDFs to work out reworked dimensions
Fa1a2 = mvncdf([A(1) A(2)],cut1R,SIGMA);
Fa1b2 = mvncdf([A(1) B(2)],cut1R,SIGMA);
Fb1a2 = mvncdf([B(1) A(2)],cut1R,SIGMA);
Fb1b2 = mvncdf([B(1) B(2)],cut1R,SIGMA);


% Conformance
ConformPrt = Fb1b2 - Fa1b2 - Fb1a2 + Fa1a2;
% Scrap
ScrapPrt = 1 - Fb1b2;
% Rework 
RworkPrt = Fb1b2 - ConformPrt;

% %% for loop implimentation 
% for i = 1:length(x)
%     if x(i)>=A(1) && y>=A(2) 
%         df(i) = mvnpdf([x(i),y],cut1R,SIGMA) + RworkPrt*mvnpdf([x(i),y],cut2R,SIGMA); 
%     elseif x(i)<A(1) && y>=B(2) % top left corner
%         df(i) = mvnpdf([x(i),y],cut1R,SIGMA) + RworkPrt*mvnpdf([x(i),y],cut2R,SIGMA); 
%     elseif x(i)>=B(1) && y<A(2) % bottom right side corner
%         df(i) = mvnpdf([x(i),y],cut1R,SIGMA) + RworkPrt*mvnpdf([x(i),y],cut2R,SIGMA);
%     elseif x(i)<B(1) && y<B(2)                % this does green region, the conformance
%         df(i) = RworkPrt*mvnpdf([x(i),y],cut2R,SIGMA);%  box is not accounted for due to the first 
%     end                                              % if-statement which is evaluated before, thus 
% end                                                  % any points in this box are automatically taken out 


%% Vector implimentaion 
% First determine the lengths of the inputs and ensure that the x and y
% vectors ar ethe same length.  i.e. if x is a vector and y is a scalar
% rewrite y as a vector (of y's) the same length as x. eg if length(x) = 5 
% and y = 4 goes to y = [4 4 4 4 4].
while length(x)==1 && length(y)==1 % for only scalar x and y inputs do the following 
     if x>=A(1) && y>=A(2) 
        df = mvnpdf([x,y],cut1R,SIGMA) + RworkPrt*mvnpdf([x,y],cut2R,SIGMA); 
        return
    elseif x<A(1) && y>=B(2) % top left corner
        df = mvnpdf([x,y],cut1R,SIGMA) + RworkPrt*mvnpdf([x,y],cut2R,SIGMA); 
        return
    elseif x>=B(1) && y<A(2) % bottom right side corner
        df = mvnpdf([x,y],cut1R,SIGMA) + RworkPrt*mvnpdf([x,y],cut2R,SIGMA);
        return
    elseif x<B(1) && y<B(2)                % this does green region, the conformance
        df = RworkPrt*mvnpdf([x,y],cut2R,SIGMA);%  box is not accounted for due to the first 
        return
     end 
end
sx = size(x);
sy = size(y);

if sx(1) > 1 && sx(2) > 1 && sy(1) > 1 && sy(2) > 1 % if inputs are matrixes
    check = 1;
    x = x(:);
    y = y(:);
elseif length(x) == length(y) && length(x)>1
    x = reshape(x,length(x),1);  % ensure x is a column
    y = reshape(y,length(y),1);  % ensure y is a column
elseif length(y) == 1
    x = reshape(x,length(x),1); % ensure x is a column
    y = y.*ones(length(x),1);   % ensure y is a column
elseif length(x)== 1
    x = x.*ones(length(y),1);   % ensure x is a column
    y = reshape(y,length(y),1); % ensure y is a column
else 
    error('x & y are not scalars or the same length')
end

cut1R = A+(B-CUT1);  % convert cut1 from near to USL to near LSL
cut2R = A+(B-CUT2);  % convert cut2 from near to USL to near LSL
df = zeros(length(x),1);

%% 1. When x>=A(1) & y>=A(2)
xGA1 = not(abs(sign(sign(A(1)-x) + sign(1000-x)))); % all x's greater than A1
yGA2 = not(abs(sign(sign(A(2)-y) + sign(1000-y)))); % a;; y's grater than A2
Pos1 = find(xGA1.*yGA2==1);  % this is the positions where BOTH x>=A(1) and y>=A(2)
R = zeros(length(x),1);
R(Pos1) = Pos1;   % record the elements that have been evaluated
df(Pos1) = mvnpdf([x(Pos1),y(Pos1)],cut1R,SIGMA) + RworkPrt*mvnpdf([x(Pos1),y(Pos1)],cut2R,SIGMA);
if check==1
    df = reshape(df,sx(1),sx(2));
end
    
%% 2. When x<A(1) & y>=B(2) % top left corner
xLA1 = not(abs(sign(sign(-1000-x) + sign(A(1)-x)))); % alls x's less than A1
yGB2 = not(abs(sign(sign(B(2)-y) + sign(1000-y))));  % all y's greater than B2
Pos2 = find(xLA1.*yGB2==1);  % this is the positions where BOTH x<A(1) and y>=B(2)
R2 = zeros(length(x),1);
R2(Pos2) = Pos2;    % Record the elements evaluated in this step
R2_R = R2 - R;      % check if any elements were already evaluated
R2_R(R2_R<=0) = []; % Removed any elements are already evaluated they will be 0 or -ve
R(R2_R) = R2_R;     % Fill in R with the newley evaluated elements
df(R2_R) = mvnpdf([x(R2_R),y(R2_R)],cut1R,SIGMA) + RworkPrt*mvnpdf([x(R2_R),y(R2_R)],cut2R,SIGMA);
if check==1
    df = reshape(df,sx(1),sx(2));
end

%% 3. When x>=B(1) amd y<A(2)  bottom right side corner
xGB1 = not(abs(sign(sign(B(1)-x) + sign(1000-x)))); % all x's greater than B1
yLA1 = not(abs(sign(sign(-1000-y) + sign(A(1)-y)))); % alls y's less than A2
Pos3 = find(xGB1.*yLA1==1);  % this is the positions where BOTH x>=B(1) and y<A(2)
R3 = zeros(length(x),1);
R3(Pos3) = Pos3;    % Record the elements evaluated in this step
R3_R = R3 - R;      % check if any elements were already evaluated
R3_R(R3_R<=0) = []; % Removed any elements are already evaluated they will be 0 or -ve
R(R3_R) = R3_R;     % Fill in R with the newley evaluated elements
df(R3_R) = mvnpdf([x(R3_R),y(R3_R)],cut1R,SIGMA) + RworkPrt*mvnpdf([x(R3_R),y(R3_R)],cut2R,SIGMA);
if check==1
    df = reshape(df,sx(1),sx(2));
end

%% 4. When x<B(1) amd y<B(2)  green, purple and baige regions (rework in reverse model)
xLB1 = not(abs(sign(sign(-1000-x) + sign(B(1)-x)))); % alls x's less than B1
yLB1 = not(abs(sign(sign(-1000-y) + sign(B(2)-y)))); % alls y's less than A2
Pos4 = find(xLB1.*yLB1==1);  % this is the positions where BOTH x<B(1) and y<B(2)
R4 = zeros(length(x),1);
R4(Pos4) = Pos4;    % Record the elements evaluated in this step
R4_R = R4 - R;      % check if any elements were already evaluated
R4_R(R4_R<=0) = [];  % Removed any elements are already evaluated they will be 0 or -ve
R(R4_R) = R4_R;     % Fill in R with the newley evaluated elements
df(R4_R) =  RworkPrt*mvnpdf([x(R4_R),y(R4_R)],cut2R,SIGMA);
if check==1
    df = reshape(df,sx(1),sx(2));
end