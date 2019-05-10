function isGoodCell = oufti_isCellStructureGood(cellId, frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function isGoodCell = oufti_isCellStructureGood(cellId, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%isGoodCell:  1 for true and 0 for false
%**********input********:
%CL:        A structure containing two fields meshData and cellId
%cellId:    id of a cell to be accessed.  The id is located in CL.cellId
%frame:     frame number
%==========================================================================
%The function checks if fields mesh and contour are available in a cell 
%structure and if there lengths are greater than 1.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
cellStructure =  oufti_getCellStructure(cellId, frame, CL);    
isGoodCell = ~isempty(cellStructure) && ...
            (isfield(cellStructure,'mesh') && length(cellStructure.mesh)>1) || ...
            (isfield(cellStructure,'contour') && length(cellStructure.contour)>1);
end