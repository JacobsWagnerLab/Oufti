function [cellStructures cellIdNums] = oufti_getAllCellStructureInFrame(cellIds, frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [cellStructures cellIdNums] = oufti_getAllCellStructureInFrame(cellIds, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    February 13, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%cellStructures:  contains a list of cell structures.
%cellIdNums    :  A vector containing cell Ids corresponding to cell
%                 structures.
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%cellIds:    A vector containing cell ids.
%frame:     frame number
%==========================================================================
%returns cell structures and their corresponding Ids.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------  
if isempty(CL.cellId{frame})
   CL.cellId{frame} = 1:length(CL.meshData{1,frame});
end
cellIdNums = []; cellStructures = [];
newCells = {};    
if ~oufti_isFrameNonEmpty(frame, CL)
   return;
end  
for ii = cellIds
    cell = oufti_getCellStructureFast(ii, frame, CL);
    if ~isempty(cell)
       newCells = [newCells {cell}]; %#ok<AGROW>
       cellIdNums   = [cellIdNums ii];       %#ok<AGROW>  
    end
end
cellStructures = newCells;
end %function [cellStructures cellIdNums] = oufti_getAllCellStructureInFrame(cellIds, frame, CL)