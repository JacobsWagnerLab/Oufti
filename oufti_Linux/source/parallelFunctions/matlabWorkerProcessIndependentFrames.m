function individualFrameStruct = matlabWorkerProcessIndependentFrames(frameData, frameList, l_p, l_args,...
                                                                       processRegion, cellStructure, imageForce_)
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function individualFrameStruct = matlabWorkerProcessIndependentFrames(frameData, frameList, l_p, l_args,...
%                                                                       processRegion, cellStructure)
%oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    May 11 2012
%@copyright 2012-2013 Yale University
%=================================================================================
%**********output********:
%individualFrameStruct: array of cell Structure processed during call to
%processIndividualIndependentFrames.
%**********Input********:
%frameData: image file.
%frameList: list of frames that need to be processed.
%l_p:       parameter structure.
%l_args:    arguements structure.
%processRegion: recangular window of a region that need to be processed
%within an image.
%cellStructure: cellList containing meshData and cellId fields.
%==================================================================================
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
	
individualFrameStruct.meshData = [];
individualFrameStruct.cellId   = [];
numFrames = length(frameList);

for frame = 1:numFrames
    if l_p.algorithm == 1
        [tempIndividualFrameStruct,imageForce_] = processIndividualIndependentFramesPixel(frameData(:,:,frame),...
                                    frameList(frame), l_p, l_args,processRegion,cellStructure,imageForce_(frame));
    else
        [tempIndividualFrameStruct,imageForce_] = processIndividualIndependentFrames(frameData(:,:,frame),...
                                    frameList(frame), l_p, l_args,processRegion,cellStructure,imageForce_(frame));
    end
%         empties = cellfun(@isempty,frameParts); % identify the empty cells
%         frameParts(empties) = [];
%         frameStruct{frame} = frameParts;
%         individualFramesStruct{frame} = frameParts;%#ok<AGROW>
%         clear frameParts
    individualFrameStruct.meshData{frame} = tempIndividualFrameStruct.meshData;
    individualFrameStruct.cellId{frame}   = tempIndividualFrameStruct.cellId;

    individualFrameStruct.imageForce(frame) = imageForce_;
   
end

end