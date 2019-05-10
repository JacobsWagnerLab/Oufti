function pcc = model2box(pcc,box,alg)
    % converts model ("pcc") from global to local (determind by "box")
    % coordinates, algorithm ("alg")-specific
   if length(pcc)<=1, return; end
   if alg==2 || alg == 1
       pcc(2:3) = pcc(2:3) - box(1:2) + 1;
   elseif alg==3
       pcc(1:2) = pcc(1:2) - box(1:2) + 1;
   elseif alg==4
       pcc(:,1) = pcc(:,1) - (box(1) +1);
       pcc(:,2) = pcc(:,2) - (box(2) +1);
   end
end