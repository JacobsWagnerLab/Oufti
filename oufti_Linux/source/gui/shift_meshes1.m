function new_cellList=shift_meshes1(cellList,shiftframes,frames)

% shift meshes in cellList according data in shiftframes (in MicrobeTracker format)

new_cellList=cellList;
%switch sign(length(shiftframes.x)-length(cellList))
%    case -1
%        disp('cellList has more frames then shiftframes');
%        return;
%    case 1
%        disp('cellList has less frames then shiftframes');
%        return;
%    case 0
        
        
    k=0;    
        for frame=frames %2:length(cellList)
          k=k+1;  
            
          for cell=1:length (cellList{frame})
            if  ~isempty(cellList{frame}{cell})&& length(cellList{frame}{cell}.mesh)>1
              new_cellList{frame}{cell}.mesh(:,1)=cellList{frame}{cell}.mesh(:,1)+shiftframes.y(k);
              new_cellList{frame}{cell}.mesh(:,2)=cellList{frame}{cell}.mesh(:,2)+shiftframes.x(k);
              new_cellList{frame}{cell}.mesh(:,3)=cellList{frame}{cell}.mesh(:,3)+shiftframes.y(k);
              new_cellList{frame}{cell}.mesh(:,4)=cellList{frame}{cell}.mesh(:,4)+shiftframes.x(k);
            end
          end
         end
    
%end


end % function end

