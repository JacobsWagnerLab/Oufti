function CL = oufti_addFieldToCellList(cellId, frame, key, value, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_addFieldToCellList(cellId, frame, key, value, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 27, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:    A structure containing two fields meshData and cellId    
%**********Input********:
%CL:    A structure containing two fields meshData and cellId
%frame:  frame to be added to the cellList.
%cellId:  cell id to be removed from the cellList
%key:  field identification key.
%value:  value to be given to key being added to cell structure.
%==========================================================================
%The function sets a value in field identified by key in a frame and cellId
%indicated by cellId and frame #.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
if oufti_doesCellExist(cellId, frame, CL)
   CL.meshData{frame}{CL.cellId{frame}==cellId}.(key) = value;
end

end