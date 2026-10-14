function p=pairs(A)
ncol=size(A,2);
for i=1:ncol
   for j=1:ncol
      subplot(ncol,ncol,(i-1)*ncol+j);
      if isequal(i,j)
         plot(0,0);
         text(-0.2,0,char(['Var',48+i]));
      else 
         plot(A(:,i),A(:,j),'k.');
      end;
   end;
end;
