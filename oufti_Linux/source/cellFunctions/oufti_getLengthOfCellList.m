function lengthCellList = oufti_getLengthOfCellList(CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function lengthCellList = oufti_getLengthOfCellList(CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%lengthCellList:  length of a frame
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%==========================================================================
%returns the length the field meshData in structure CL.  meshData contains
%all the frames in the CL structure.
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------  
lengthCellList = length(CL.meshData);
end