function isNonEmptyFrame = oufti_isFrameNonEmpty(frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function isNonEmptyFrame = oufti_isFrameNonEmpty(frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%isNonEmptyFrame:  1 for true and 0 for false
%**********input********:
%CL:        A structure containing two fields meshData and cellId
%frame:     frame number
%==========================================================================
%The function finds if the frame is empty or not.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
isNonEmptyFrame = oufti_doesFrameExist(frame, CL) && ~oufti_isFrameEmpty(frame, CL);
end