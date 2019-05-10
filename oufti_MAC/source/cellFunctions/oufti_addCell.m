function CL = oufti_addCell(cellId, frame, cellToAdd, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_addCell(cellId, frame, cellToAdd, CL)
%microbeTracker v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    February 13, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:      A structure with added cell structure containing two 
%         fields -- meshData and cellId
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%cellId:    id of a cell to be accessed.  The id is located in CL.cellId
%frame:     frame number
%cellToAdd: cell structure to be added to CL structure
%==========================================================================
%Adds a cell structure to the CL input (also a cell structure containing
%two fields -- meshData and CellId.  The function also checks if a cell
%structure noted by cellId is already present in the meshData cell array,
%if not present, it adds a new cell structure otherwise it overwrites the existing
%one.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------  

if length(CL.meshData) < frame
    CL.meshData{frame} = [];
    CL.cellId{frame}   = [];
end

if isempty(oufti_getCellStructure(cellId, frame, CL))
   % add new cell.
   CL.meshData{frame}    = [CL.meshData{frame} {cellToAdd}];
   CL.cellId{frame} = [CL.cellId{frame} cellId];
else
    % overwrite existing cell.
    cellId = CL.cellId{frame}==cellId;
    CL.meshData{frame}{cellId} = cellToAdd;
end
    
end %function CL = oufti_addCell(cellId, frame, cellToAdd, CL)


