function signalArray=signalToFrameParallel(frameData,image,rsz,apr,isRawPhase)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function signalArray=signalToFrameParallel(frameData,image,rsz,apr,isRawPhase)
%oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    June 11 2012
%@copyright 2012-2013 Yale University

%==========================================================================
%**********output********:
%signalArray:  Structure containing cell profile data for a the amount of
%frames in frameData
%**********Input*********:
%frameData:  cell data for the amount of cells in current frame
%image    :  current raw image
%rsz      :  Resize matrix
%apr      :  Boolean variable indicating apr file presence.  1 = true, 0 =
%false
%isRawPhase: Boolean variable checking if RawPhase is true or false

%==========================================================================
% NO GLOBAL VARIABLES ARE ALLOWED HERE!
%--------------------------------------------------------------------------
image = im2double(image);
if isRawPhase, image = max(max(image))-image;end
signalArray= cell(zeros(size(frameData)));
for i=1:length(frameData)
    cellStruct  = frameData{i};
    if isfield(cellStruct,'mesh') && size(cellStruct.mesh,1)>1
       if ~apr
       signalArray{i} = getOneSignalM(double(cellStruct.mesh),double(cellStruct.box),image,rsz);
       else
       signalArray{i} = getOneSignalC(double(cellStruct.mesh),double(cellStruct.box),image,rsz);
       end
    elseif isfield(cellStruct,'model')
       if apr
          signalArray{i} = getOneSignalContourM(double(cellStruct.model),...
                                                double(cellStruct.box),image,rsz);
       else
          signalArray{i} = getOneSignalContourM(double(cellStruct.model),...
                                                double(cellStruct.box),image,rsz);
       end
    else
          signalArray{i} = [];
    end
end
signalArray = cellfun(@single,signalArray,'UniformOutput',0);
return

