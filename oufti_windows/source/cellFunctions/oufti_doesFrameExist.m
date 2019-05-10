function isFrame = oufti_doesFrameExist(frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function isFrame = oufti_doesFrameExist(frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%isFrame:  1 for true and 0 for false
%**********input********:
%CL:        A structure containing two fields meshData and cellId
%frame:     frame number
%==========================================================================
%The function checks for availability of a frame
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
isFrame = frame > 0 && frame <= oufti_getLengthOfCellList(CL);
end