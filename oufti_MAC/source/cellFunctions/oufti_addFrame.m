function CL = oufti_addFrame(frame, cellsToAdd, cellIds, CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function CL = oufti_addFrame(frame, cellsToAdd, cellIds, CL)
%microbeTracker v0.2.8
%@author:  Ahmad J Paintdakhi
%@date:    March 21, 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%CL:      A structure with added frame containing two 
%         fields -- meshData and cellId
%**********Input********:
%CL:        A structure containing two fields meshData and cellId
%cellIds:   cell Indexes for the frame to be added.
%frame:     frame number
%cellsToAdd: cell structure containing all the cells to be added.
%==========================================================================
%Adds a frame to the cellList.  If the length of the frame is less than the
%length of cellsToAdd, the entire frame is replaced.  Use with Caution!!!!!
%-------------------------------------------------------------------------- 
%--------------------------------------------------------------------------     
CL.meshData{frame}   = cellsToAdd;
CL.cellId{frame}     = cellIds;
end