function isContourAvailable = oufti_doesCellHaveContour(cellId, frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function isContourAvailable = oufti_doesCellHaveContour(cellId, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%isContourAvailable:  1 for true and 0 for false
%**********input********:
%CL:        A structure containing two fields meshData and cellId
%cellId:    id of a cell to be accessed.  The id is located in CL.cellId
%frame:     frame number
%==========================================================================
%The function first checks if a cell is available, if that is the case then
%it checks for the availability of a contour.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
cellStructure =  oufti_getCellStructure(cellId, frame, CL);    
isContourAvailable = ~isempty(cellStructure) && (isfield(cellStructure,'model') && length(cellStructure.model)>1);
end