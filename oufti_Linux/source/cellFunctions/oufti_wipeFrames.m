function CL = oufti_wipeFrames(frameRange, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = CL_oufti_wipeFrames(frameRange, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 27, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:    updated cellList after deletion of frames given by frame range.   
%**********Input********:
%CL:    A structure containing two fields meshData and cellId
%frameRange:  frame range to be used for deletion such as [1 10], which
%means data from frame 1-10 is desired.
%==========================================================================
%The function returns an updated cellList after deletion of frames 
%given by frame range.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
numFrames = min(frameRange(2), oufti_getLengthOfCellList(CL));
CL.meshData{frameRange(1):numFrames} = [];
CL.cellId{frameRange(1):numFrames} = [];
end