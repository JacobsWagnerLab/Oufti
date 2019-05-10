function CL = oufti_initializeCellList()
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_initializeCellList()
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:        A structure containing two fields meshData and cellId
%==========================================================================
%The function initializes a structure called CL and returns it with two
%fields -- meshData and cellId both as empty cell arrays.
%-------------------------------------------------------------------------- 
%-------------------------------------------------------------------------- 
CL.meshData    = {[]};
CL.cellId      = {[]};
end
