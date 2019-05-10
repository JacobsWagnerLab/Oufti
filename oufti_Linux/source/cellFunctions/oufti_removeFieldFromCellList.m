function CL = oufti_removeFieldFromCellList(cellId, frame, key, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_removeFieldFromCellList(cellId, frame, key, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:    A structure containing two fields meshData and cellId    
%**********Input********:
%CL:    A structure containing two fields meshData and cellId
%frame:  frame to be added to the cellList.
%cellId:  cell id to be removed from the cellList
%key:  field identification key.
%==========================================================================
%The function removes a field from a given frame and cellId
%indicated by a key.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
if oufti_doesCellExist(cellId, frame, CL)
   cellIdPosition = CL.cellId{frame}==cellId;
   CL.meshData{frame}{cellIdPosition} = rmfield(CL.meshData{frame}{cellIdPosition}, key);
end
end