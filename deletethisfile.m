%tester
clear all
close all
clc

   Mu_Vec = linspace(2.5,3.5,10);
        for i = 1:length(Mu_Vec)
            P(i) = (1-normcdf(3,Mu_Vec(i),1))/40;
        end
   A_vec = linspace(2.5,3.5,10)
          for i = 1:length(Mu_Vec)
            Q(i) = (normcdf(A_vec(i),3,1))/40;
        end
       plot(Mu_Vec,P,'.-'); hold on
       plot(A_vec,Q,'r.-'); grid on