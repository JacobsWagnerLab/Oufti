function cellStructure = oufti_oufti_getCellStructureFast(cellId, frame, CL)
%----------------------------------------------------------------------
%----------------------------------------------------------------------
%function cellStructure = oufti_getCellStructureFast(cellId, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%======================================================================
%**********output********:
%cell:  cell structure containing cell information
%**********Input********:
%CL:      A structure containing two fields meshData and cellId
%cellId:  id of a cell to be accessed.  The id is located in CL.cellId
%frame:   frame number
%======================================================================
%return a cell structure from CL, given a cellId and frame #, if cellId
%not present in the CL array given the frame, the function returns 
%empty value
%---------------------------------------------------------------------- 
%----------------------------------------------------------------------   
cellId = CL.cellId{frame}==cellId;
if sum(cellId)
    cellStructure = CL.meshData{frame}{cellId};
else
    cellStructure = [];
end

end