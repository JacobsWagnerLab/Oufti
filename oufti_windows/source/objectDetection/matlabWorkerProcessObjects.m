function individualFrameStruct = matlabWorkerProcessObjects(meshData, frameList, image,params,objectDetectionManualValue)

%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%individualFrameStruct = matlabWorkerProcessObjects(frameData, frameList, image,param)
%Oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    August 21 2014
%@copyright 2012-2015 Yale University

%=================================================================================
%**********output********:


%**********Input********:

%==================================================================================

% NO GLOBAL VARIABLES ARE ALLOWED HERE!

    % I now change the meaning of the argument clength. It used to be the
    % full cell length matrix, but to reduce memory usage (and to avoid an
    % error in createJob) it will henceforth contain only the cell length
    % of the cells to process and only <= 20 frames back from the current frame.

    % celln below is local cell numbering, not global.
    % Similarly, proccells is an array of cell ids corresponding to the
    % contents of the array cells.
    
    % cells is now a struct array, not a cell array of structs
%-----------------------------------------------------------------------------------------
	
%     frameStruct = cell(size(frameList));

numFrames = length(frameList);
individualFrameStruct = {[]};
for frame = 1:numFrames
    for cellNum = 1:length(meshData{frame})
        %If the cell is bad, continue
        if isempty(meshData{frame}{cellNum}) || ...
           ~isfield(meshData{frame}{cellNum},'model') || size(meshData{frame}{cellNum}.model,1) < 4
           individualFrameStruct{frame}{cellNum} = [];
           continue;
        end
        cellStructure = meshData{frame}{cellNum};
        try
        objectData = objectDetectionMain(image, cellStructure,params,objectDetectionManualValue);
        catch
            objectData = [];
        end
        individualFrameStruct{frame}{cellNum} = objectData;
    end

end

end