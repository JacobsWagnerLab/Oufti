function isCellTrue = oufti_doesCellExist(cellId, frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function isCellTrue = oufti_doesCellExist(cellId, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%isCellTrue:    1 for true and 0 for false
%**********input********:
%CL:        A structure containing two fields meshData and cellId
%cellId:    id of a cell to be accessed.  The id is located in CL.cellId
%frame:     frame number
%==========================================================================
%The function checks if cell identified by cellId is available in a given
%frame in the given CL structure.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
try
    isCellTrue = oufti_doesFrameExist(frame, CL) && (sum(CL.cellId{frame}==cellId));
catch
    isCellTrue = 0;
end
end