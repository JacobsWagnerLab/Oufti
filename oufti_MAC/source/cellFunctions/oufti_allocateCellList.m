function CL = oufti_allocateCellList(CL,frameList)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_allocateCellList(CL,frameList)
%oufti.v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    January 22, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:  A structure containing two fields 1. meshData and 2. cellId.
%**********Input********:
%CL:  A structure containing two fields meshData and cellId
%frameList:  list of frames.
%==========================================================================
%creates new empty cellList not deleting previous cells if present in the
%input CL.  This is simply a sparse cell matrix for fields meshData and
%cellId
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------
if cellfun(@isempty,CL.meshData)
    CL.meshData    = cell(1,frameList(end));
    CL.cellId = cell(1,frameList(end));
else
    CL.meshData = [CL.meshData cell(1,frameList(end) - length(CL.meshData))];
    CL.cellId   = [CL.cellId cell(1,frameList(end) - length(CL.cellId))];
end

end
