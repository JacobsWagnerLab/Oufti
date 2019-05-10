function signalCellsStruct = matlabWorkerAddSignalToFrame(imageData,cellData,idData,cellListToRun,...
                                                          rsz,apr,isRawPhase)

%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function signalCellsStruct = matlabWorkerAddSignalToFrame(imageData,cellData,rsz,apr,isRawPhase)
%oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    May 11 2012
%@copyright 2012-2013 Yale University

%==========================================================================
%**********output********:
%signalCellsStruct:  A structure containing cells data for a given # of
%frames
%**********Input********:
%imageData:  Image data for frame data
%cellData :  CellList containing cell data for a particular frame range
%rsz      :  Resize matrix
%apr      :  Boolean variable indicating apr file presence.  1 = true, 0 =
%false
%isRawPhase: Boolean variable checking if RawPhase is true or false

%===========================================================================
% NO GLOBAL VARIABLES ARE ALLOWED HERE!
%---------------------------------------------------------------------------

numFrames = length(cellData);
for jj = 1:numFrames
    if ~isempty(cellListToRun)
        cellStructures = oufti_getAllCellStructureInFrameForSignalExtraction(cellListToRun, cellData{jj},idData{jj});
        if isempty(cellStructures), signalCellsStruct{jj} = []; continue; end %#ok<AGROW>
        signalCellsStruct{jj} = signalToFrameParallel(cellStructures,imageData(:,:,jj),...
                                                   rsz,apr,isRawPhase);%#ok<AGROW>
    else
    proccells = 1:length(cellData{jj});
    if isempty(cellData{jj}), signalCellsStruct{jj} = []; continue; end %#ok<AGROW>
    signalCellsStruct{jj} = signalToFrameParallel(cellData{jj}(proccells),imageData(:,:,jj),...
                                                   rsz,apr,isRawPhase);%#ok<AGROW>
    end
end

end  %end of function ---> matlabWorkerAddSignalToFrame

