function cellStructure = oufti_getCellStructure(cellId, frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cell = oufti_getCellStructure(cellId, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    January 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%cell:  cell structure containing cell information
%**********Input********:
%CL:      A structure containing two fields meshData and cellId
%cellId:  id of a cell to be accessed.  The id is located in CL.cellId
%frame:   frame number
%==========================================================================
%return a cell structure from CL, given a cellId and frame #
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------    
cellStructure = [];   
if length(CL.meshData)<frame % || length(CL.meshData{frame})<id
   return;
end
    cellId = CL.cellId{frame}==cellId; 
if sum(cellId) ~= 1
   return;
else
   cellStructure = CL.meshData{frame}{cellId};
end

end %function cell = oufti_getCellStructure(cellId, frame, CL)