function shiftmeshes(frame,directionToShift,list)  
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function shiftmeshes(frame,directionToShift) 
%oufti.v0.3.0
%@author:  Oleksii Sliusarenko
%modified: Ahmad Paintdakhi
%@date:    December 3, 2012
%@date:    April 30, 2013
%@copyright 2012-2013 Yale University
%=================================================================================
%**********output********:
%**********Input********:
%frame: frame in which meshes need to be shifted
%directionToShift:  Either 1 or -1, indicating direction for shift.
%==================================================================================
% shifts the position of every cell on the indicated frame in "cellList"
% structure according to the amount indicated in the "shiftframes" array
% (obtained from image alignment) in the indicated direction "dir" (1 -
% direct, -1 - backward). This function is used to prepare cell
% positions from the previous frame to be used as the initial guess in
% an active coutour routine.
%------------------------------------------------------------------------------------
%------------------------------------------------------------------------------------
global p shiftframes imsizes cellList

if isempty(p), p.algorithm = 4;end
if isempty(who('shiftframes')) || isempty(shiftframes) || length(shiftframes.x)~=imsizes(1,3) || ~ismember(directionToShift,[-1 1]) , return; end
if isempty(list) || length(list) > 2
    for c=1:length(cellList.meshData{frame-1})
         if ~isempty(cellList.meshData{frame-1}{c}) && isfield(cellList.meshData{frame-1}{c},'model') && ismember(p.algorithm,2)
                cellList.meshData{frame-1}{c}.model(2) = cellList.meshData{frame-1}{c}.model(2)+directionToShift*shiftframes.x(frame-1)-directionToShift*shiftframes.x(frame);
                cellList.meshData{frame-1}{c}.model(3) = cellList.meshData{frame-1}{c}.model(3)+directionToShift*shiftframes.y(frame-1)-directionToShift*shiftframes.y(frame);
         elseif ~isempty(cellList.meshData{frame-1}{c}) && isfield(cellList.meshData{frame-1}{c},'model') && ismember(p.algorithm,3)
                cellList.meshData{frame-1}{c}.model(1) = cellList.meshData{frame-1}{c}.model(1)+directionToShift*shiftframes.x(frame-1)-directionToShift*shiftframes.x(frame);
                cellList.meshData{frame-1}{c}.model(2) = cellList.meshData{frame-1}{c}.model(2)+directionToShift*shiftframes.y(frame-1)-directionToShift*shiftframes.y(frame);
         elseif ~isempty(cellList.meshData{frame-1}{c}) && length(cellList.meshData{frame-1}{c}.mesh) > 4 && isfield(cellList.meshData{frame-1}{c},'model') && ~isempty(cellList.meshData{frame-1}{c}.model) && ismember(p.algorithm,4)
                %---------------------------------------------------------------------------------------------------------------
                %update sept. 24. 2012 -- alignment of cells due to high shift
                %in between frames.  Also the shift is taken relative to the
                %previous frame rather than the very first frame as was done in
                %the alignFrames() process.  This is the reason why we are only
                %adding the shift to the model of the previous frame.
    % % %             if isfield(cellList.meshData{frame-1}{c},'boxModel')
    % % %                 cellList.meshData{frame-1}{c}.boxModel(:,1) = cellList.meshData{frame-1}{c}.boxModel(:,1)+dir*shiftframes.y(frame);
    % % %                 cellList.meshData{frame-1}{c}.boxModel(:,2) = cellList.meshData{frame-1}{c}.boxModel(:,2)+dir*shiftframes.x(frame);
    % % %             end

                cellList.meshData{frame-1}{c}.mesh(:,[1 3]) = cellList.meshData{frame-1}{c}.mesh(:,[1 3])+directionToShift*shiftframes.x(frame);
                cellList.meshData{frame-1}{c}.mesh(:,[2 4]) = cellList.meshData{frame-1}{c}.mesh(:,[2 4])+directionToShift*shiftframes.y(frame);
                cellList.meshData{frame-1}{c}.model(:,1) = cellList.meshData{frame-1}{c}.model(:,1)+directionToShift*shiftframes.x(frame);
                cellList.meshData{frame-1}{c}.model(:,2) = cellList.meshData{frame-1}{c}.model(:,2)+directionToShift*shiftframes.y(frame);
                %---------------------------------------------------------------------------------------------------------------
         elseif ~isempty(cellList.meshData{frame-1}{c}) && p.algorithm==1 && isfield(cellList.meshData{frame-1}{c},'mesh') && length(cellList.meshData{frame-1}{c}.mesh)>=4
                cellList.meshData{frame-1}{c}.mesh(:,[1 3]) = cellList.meshData{frame-1}{c}.mesh(:,[1 3])+directionToShift*shiftframes.x(frame-1)-directionToShift*shiftframes.x(frame);
                cellList.meshData{frame-1}{c}.mesh(:,[2 4]) = cellList.meshData{frame-1}{c}.mesh(:,[2 4])+directionToShift*shiftframes.y(frame-1)-directionToShift*shiftframes.y(frame);
         elseif ~isempty(cellList.meshData{frame-1}{c}) && p.algorithm==1 && isfield(cellList.meshData{frame-1}{c},'model')
                cellList.meshData{frame-1}{c}.model(:,1) = cellList.meshData{frame-1}{c}.model(:,1)+directionToShift*shiftframes.x(frame-1)-directionToShift*shiftframes.x(frame);
                cellList.meshData{frame-1}{c}.model(:,2) = cellList.meshData{frame-1}{c}.model(:,2)+directionToShift*shiftframes.y(frame-1)-directionToShift*shiftframes.y(frame);
         end
    end
else
    for cells = 1:length(list)
        if ~isempty(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}) && ...
                isfield(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)},'model') &&...
                ~isempty(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.model) && ...
                ismember(p.algorithm,4)
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.mesh(:,[1 3]) = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.mesh(:,[1 3])+directionToShift*shiftframes.x(frame);
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.mesh(:,[2 4]) = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.mesh(:,[2 4])+directionToShift*shiftframes.y(frame);
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.model(:,1) = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.model(:,1)+directionToShift*shiftframes.x(frame);
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.model(:,2) = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(list(cells),frame-1,cellList)}.model(:,2)+directionToShift*shiftframes.y(frame);
        end
    end

end
end