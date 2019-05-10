function pcc = box2model(pcc,box,alg)
    % converts model ("pcc") from local to global (determind by "box")
    % coordinates, algorithm ("alg")-specific
   if isempty(pcc), return; end
   if alg==2
       pcc(2:3) = pcc(2:3) + box(1:2) - 1;
   elseif alg==3
       pcc(1:2) = pcc(1:2) + box(1:2) - 1;
   elseif alg==4 || alg == 1
       pcc(:,1) = pcc(:,1) + box(1) - 1;
       pcc(:,2) = pcc(:,2) + box(2) - 1;
   end
   
end