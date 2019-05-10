function lengthFrame = oufti_oufti_getFrameLength(frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function lengthFrame = oufti_getFrameLength(frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    February 11, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%lengthFrame:  length of a frame
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%frame:     frame number
%==========================================================================
%returns the length of a frame given by the input frame number
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------  
lengthFrame = 0;
if ~oufti_isFrameEmpty(frame, CL)
   lengthFrame = length(CL.meshData{frame});
end
end %function lengthFrame = oufti_getFrameLength(frame, CL)
