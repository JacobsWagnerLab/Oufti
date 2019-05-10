function [meshData cellId] = oufti_getFrame(frame, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [meshData cellId] = oufti_getFrame(frame, CL)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    February 11, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%meshData:  A cell containing cell Structures.
%cellId  :  A vector containing cell Ids corresponding to cell structures.
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%frame:     frame number
%==========================================================================
%returns cell structures and their corresponding Ids in cell formats
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------  
meshData = {};
cellId = [];
if frame > length(CL.meshData)
   return;
end
meshData = CL.meshData{frame};
cellId   = CL.cellId{frame};
if isempty(CL.cellId{frame}) || isempty(CL.meshData{frame}), ...
   cellId = 0; 
end
end