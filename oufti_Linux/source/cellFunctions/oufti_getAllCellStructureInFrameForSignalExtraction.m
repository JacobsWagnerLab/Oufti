function cellStructures = oufti_getAllCellStructureInFrameForSignalExtraction(cellIds, cellData,idData)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cellStructures = oufti_getAllCellStructureInFrameForSignalExtraction(cellIds, cellData,idData)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    February 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%cellStructures:  contains a list of cell structures.
%**********Input********:
%cellData:  A cell array containing cell structures
%idData  :  A cell array containing id vectors
%cellIds :  A vector containing cell ids.
%==========================================================================
%returns a cell array containing cell structures corresponding only to
%cellIds
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------  
cellStructures = []; 
for ii = cellIds
    cell = oufti_getCellStructureForSignalExtraction(ii, cellData,idData);
    if ~isempty(cell)
       cellStructures = [cellStructures cell]; %#ok<AGROW>
    end
end
end %function [cellStructures cellIdNums] = oufti_getAllCellStructureInFrame(cellIds, frame, CL)

%subFunction called by the main function.  The reason why this function is
%used here is that no other functions in the library calls this function.
function cell = oufti_getCellStructureForSignalExtraction(id,cellData,idData)

    cellId = idData==id;
    if sum(cellId)
        cell = cellData(cellId);
    else
        cell = [];
    end
end