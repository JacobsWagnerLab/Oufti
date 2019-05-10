function individualFrameStruct=matlabWorkerJoinCellsParallel(frameData,...
                                frameList,lst, l_p, l_args,imageForce_)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cells = matlabWorkerJoinCellsParallel(frameData,frameList,lst,...
%                                               l_p, l_args)
%oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    May 23 2012
%@copyright 2012-2013 Yale University

%==========================================================================
%**********output********:
%individualFramesStruct:  structure containing each frame's cell data.

%**********Input********:
%frameData:  Image matrix for the number of frames to be processed.
%frameList:  An array containing number of frames to be processed.
%lst:        list of all the frames to be processed
%l_p:        p-parameter converted to non-global variables.
%l_args:     all variable that are global are inside this structure to keep
%            in line with the requirements of parallel computation, i.e.
%            not declaring any variables to be global or changing those
%            that were global to local variables.

%=========================================================================
% NO GLOBAL VARIABLES ARE ALLOWED HERE!

%%-------------------------------------------------------------------------
numFrames = length(frameList);
individualFrameStruct.meshData = {[]};
individualFrameStruct.cellId   = {[]};
tempIndividualFrameStruct.meshData = lst.meshData;
tempIndividualFrameStruct.cellId   = lst.cellId;
for frame = 1:numFrames
    
    if frame>size(frameData,3),disp('Joining cells failed: unacceptable frame number')
       return;
    end
    if l_p.invertimage
       img = max(max(max(frameData)))-frameData(:,:,frame);
    else
       img = frameData(:,:,frame);
    end
    tempIndividualFrameStruct = joincellsParallel(img, frameList(frame), tempIndividualFrameStruct, l_p, l_args,imageForce_(frame));
    individualFrameStruct.meshData{frameList(frame)} = tempIndividualFrameStruct.meshData{frameList(frame)};
    individualFrameStruct.cellId{frameList(frame)}   = tempIndividualFrameStruct.cellId{frameList(frame)};
end

end

