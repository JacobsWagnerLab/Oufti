function oufti_isFrameEmpty = oufti_isFrameEmpty(frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function oufti_isFrameEmpty = oufti_isFrameEmpty(frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%oufti_isFrameEmpty:  1 for true and 0 for false
%**********input********:
%CL:        A structure containing two fields meshData and cellId
%frame:     frame number
%==========================================================================
%The function checks if a frame is empty or not.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
oufti_isFrameEmpty = 0;
if oufti_doesFrameExist(frame, CL)
    oufti_isFrameEmpty = isempty(CL.meshData{frame});
end

end