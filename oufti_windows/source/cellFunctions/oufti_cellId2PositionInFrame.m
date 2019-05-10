function positionInFrame = oufti_cellId2PositionInFrame(cellId, frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function positionInFrame = oufti_cellId2PositionInFrame(cellId, frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%positionInFrame:   position of given cellId in a given frame.
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%frame:     frame number
%cellId:    cell id in a given frame.
%==========================================================================
%The function returns the position of cellId in a given frame.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
positionInFrame = [];
if oufti_isFrameNonEmpty(frame, CL)
   positionInFrame = find(CL.cellId{frame}==cellId);
end
end