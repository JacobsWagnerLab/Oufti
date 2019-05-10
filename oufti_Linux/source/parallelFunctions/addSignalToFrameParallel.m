function addSignalToFrameParallel(range,addsig,addas,cellListToRun,rsz,apr,shiftfluo)
%-------------------------------------------------------------------------------------
%-------------------------------------------------------------------------------------
%function addSignalToFrameParallel(range,addsig,addas,cellListToRun,rsz,apr,shiftfluo)
%oufti.v0.0.1
%@author:  Ahmad J Paintdakhi
%@date:    July 06 2012
%@copyright 2012-2013 Yale University
%=============================================================================
%**********output********:
%No output, however, global variable CellList is updated here with
%additional information.
%**********Input*********:
%range:         range of frame selected e.g; [1 10]
%addsig:        Number of signals to add such as Phase, signal1 or signal2
%addas:         How to save added signal e.g; phase --> 0, signal1 --> 1 etc. 
%cellListToRun: Number of cells to run; selected from the GUI
%rsz:           resize image or not 
%apr:           search for getOneSignalC function converted to mex file.
%shiftfluo:     shift fluorescence image by amount of pixels.
%==============================================================================

%-------------------------------------------------------------------------------------

global cellList rawPhaseData rawS1Data rawS2Data
numFrames = (range(2)-range(1))+1;
tempCellList = cellList.meshData(range(1):range(2));
tempCellId    = cellList.cellId(range(1):range(2));
if cellfun(@isempty,tempCellList), disp('no mesh data for requested frames');return;end
matlabVersion = version;
if str2double(matlabVersion(1)) < 8
    sched = findResource('scheduler','type','local');
    numTasks = sched.ClusterSize;
else
    sched = parcluster(); 
    numTasks = sched.NumWorkers;
end
% % % if isdir('d:\')
% % %    if ~isdir('d:\Users\tmp'), mkdir('d:\Users\TMP'); end 
% % %    sched.DataLocation = 'd:\Users\TMP';
% % % elseif isdir('e:\')
% % %    if ~isdir('e:\Users\tmp'), mkdir('e:\Users\TMP'); end 
% % %    sched.DataLocation = 'e:\Users\TMP';
% % % else
% % %     if ~isdir('c:\tmp'), mkdir('c:\TMP'); end
% % %     
% % %     sched.DataLocation = 'c:\TMP';
% % % end

for ii = 1:length(find(addsig))
    newJob{ii} = createJob(sched);%#ok<AGROW>  
end
if isempty(addas)
    addas = {'0','-','1','2'};
end
outChannel = {[],[],[],[]};
for i=1:length(addsig)
    if addsig(i)
       outChannel{i} = addas{i};
    end
end
outChannel = outChannel(~cellfun(@isempty,outChannel));
numTasks = min(numTasks, 12);
numTasks = min(numTasks, numFrames);
tempData = [];
isRawPhase = [];
%-------------------------------------------------------------------------------------
%*******
%Routine that checks for number of signals to be added to each cellList
%array.  It also takes advantage of range vector--- i.e. it only selects
%the requested frames by the user instead of all available frames thus
%saving memory in some cases.
%*******
if length(find(addsig)) == 3
    if (~isempty(rawPhaseData) && ~isempty(rawS1Data) && ~isempty(rawS2Data))
        tempData = {rawPhaseData(:,:,range(1):range(2)),rawS1Data(:,:,range(1):range(2)),...
                    rawS2Data(:,:,range(1):range(2))};
    end
elseif length(find(addsig)) == 2
    if (~isempty(rawPhaseData) && ~isempty(rawS1Data))
        if find(addsig) == [1,3] 
            tempData = {rawPhaseData(:,:,range(1):range(2)),rawS1Data(:,:,range(1):range(2))};
        elseif find(addsig) == [1,4] && ~isempty(rawPhaseData) && ~isempty(rawS2Data)
            tempData = {rawPhaseData(:,:,range(1):range(2)),rawS2Data(:,:,range(1):range(2))};
        elseif find(addsig) == [3,4] && ~isempty(rawS1Data) && ~isempty(rawS2Data)
            tempData = {rawS1Data(:,:,range(1):range(2)),rawS2Data(:,:,range(1):range(2))};
        end
    end
else
    if ~isempty(rawPhaseData)
        if find(addsig) == 1
           tempData = rawPhaseData(:,:,range(1):range(2));
        elseif find(addsig) == 3 && ~isempty(rawS1Data)
            tempData = rawS1Data(:,:,range(1):range(2));
        elseif find(addsig) == 4 && ~isempty(rawS2Data)
            tempData = rawS2Data(:,:,range(1):range(2));
        end     
    end
end
%-------------------------------------------------------------------------------------

if isempty(tempData)
    disp('rawPhase, signal1, or signal2 data is missing')
    return
end

newRange = [];
for ii = range(1):range(2)
    newRange(end+1) = ii;%#ok<AGROW>
end

wFrames = 1;
processIncrement = ceil(numFrames/numTasks);
lastIncrement = numFrames - ((numTasks-1)*processIncrement);
if lastIncrement <= 0, numTasks = numTasks -1;end

for i = 2:numTasks
    wFrames(i) = wFrames(i-1)+processIncrement;%#ok<AGROW>
    if wFrames(i) >= numFrames, numTasks = i; break; end
end
if lastIncrement <=0, wFrames(end) = numFrames;end
if exist('aip','file')==0, apr=false; end

%-------------------------------------------------------------------------------------
%********
%For debugging purposes force numTasks to equal 1, otherwise automation
%routines are utilized to either select parallel processing or code in
%serial (not parallel) mode.
%********
%numTasks = 1;
for j = 1:length(newJob)
    isRawPhase = false;
    for i = 1:numTasks
        if i<numTasks
        wFinalFrame = wFrames(i+1)-1;
        else
        wFinalFrame = numFrames;
        end
        disp(['Adding signal ' num2str(outChannel{j}) ' for ' ...
              ' cells: in frame ' num2str(newRange(wFrames(i))) ':' num2str(newRange(wFinalFrame))]);
        if addsig(1) == 1 && j == 1 && ~isempty(who('rawPhaseData')),isRawPhase = true; end
        if i <= numFrames
            if numTasks == 1
                if length(newJob) == 1
                    tempImageData = tempData(:,:,wFrames(i):wFinalFrame);
                    tempCellData  = tempCellList(wFrames(i):wFinalFrame);
                    tempIdData    = tempCellId(wFrames(i):wFinalFrame);
                else
                    tempImageData = tempData{j}(:,:,wFrames(i):wFinalFrame);
                    tempCellData  = tempCellList(wFrames(i):wFinalFrame);
                    tempIdData    = tempCellId(wFrames(i):wFinalFrame);

                end
            % For debugging:  If numTasks = 1, this function will be used.
                signalTempParts{j}={matlabWorkerAddSignalToFrame(tempImageData,tempCellData,...
                            tempIdData,cellListToRun,rsz,apr,isRawPhase)};%#ok<AGROW>         
            else
                if length(newJob) == 1
                    tempImageData = tempData(:,:,wFrames(i):wFinalFrame);
                    tempCellData  = tempCellList(wFrames(i):wFinalFrame);
                    tempIdData    = tempCellId(wFrames(i):wFinalFrame);

                else
                    tempImageData = tempData{j}(:,:,wFrames(i):wFinalFrame);
                    tempCellData  = tempCellList(wFrames(i):wFinalFrame);
                    tempIdData    = tempCellId(wFrames(i):wFinalFrame);

                end
                % This function is used for parallel routine.
                t = createTask(newJob{j}, @matlabWorkerAddSignalToFrame, 1,{...
                     tempImageData,tempCellData,tempIdData,cellListToRun,rsz,apr,isRawPhase});
            end
        end
    end
end

%-------------------------------------------------------------------------------------

%%
if numTasks > 1 
    jobContainer = {'rawPhase','Signal 1', 'Signal 2'};
    for ii = 1:length(newJob)
        disp(['Submitting job for ' jobContainer(ii)])
        alltasks{ii} = get(newJob{ii}, 'Tasks');%#ok<AGROW>
        if str2double(matlabVersion(1)) < 8
            set(alltasks{ii}, 'CaptureCommandWindowOutput', true);
            submit(newJob{ii});
        else
            set(alltasks{ii}, 'CaptureDiary', true);
            submit(newJob{ii});
        end
    end
    disp('Awaiting results')
    for ii = 1:length(newJob)
        if str2double(matlabVersion(1)) < 8
            waitForState(newJob{ii}, 'finished');
            if ~isempty(t.Error),errorMessage = get(t,'ErrorMessage');...
               disp(['Error:  ' errorMessage]),end     
            signalTempParts{ii} = getAllOutputArguments(newJob{ii});%#ok<AGROW>
            destroy(newJob{ii});
        else
            wait(newJob{ii});
            if ~isempty(t.Error),errorMessage = get(t,'ErrorMessage');...
               disp(['Error:  ' errorMessage]),end     
            signalTempParts{ii} = newJob{ii}.fetchOutputs;%#ok<AGROW>
            delete(newJob{ii});
        end
    end
end

frameTemp = {};
for i=1:size(signalTempParts,2)
    for j = 1:size(signalTempParts{i},1)
        if j<numTasks
           wFinalFrame = wFrames(j+1)-1;
        else
           wFinalFrame = numFrames;
        end
        if isempty(signalTempParts{i}{j})
           frameTemp{i}(wFrames(j):wFinalFrame) = {[]};%#ok<AGROW>
        else
        frameTemp{i}(wFrames(j):wFinalFrame) = signalTempParts{i}{j};%#ok<AGROW>
        end
    end
end

%%
%-------------------------------------------------------------------------------------
%*********
%This routine collects data from variable frameTemp and processes the
%available information to properly add appropriate signals to each cell
%structure in given frame numbers.
%*********
for numSignal = 1:length(frameTemp)
    fieldName = sprintf('signal%s', num2str(outChannel{numSignal}));
    for numFrame = 1:size(frameTemp{numSignal},2)
        if ~isempty(cellListToRun)   
            proccells = cellListToRun;
            for numCell = 1:size(frameTemp{numSignal}{numFrame},2)    
                if isempty(frameTemp{numSignal}{numFrame}{numCell})
                    cellList = oufti_addFieldToCellList(proccells(numCell), numFrame, fieldName, [], cellList);
                else
                    cellList = oufti_addFieldToCellList(proccells(numCell), numFrame, fieldName, frameTemp{numSignal}{numFrame}{numCell}, cellList);
                end
            end
        else
            proccells = 1:length(cellList.cellId{newRange(numFrame)});
            for numCell = 1:size(frameTemp{numSignal}{numFrame},2)    
                if isempty(frameTemp{numSignal}{numFrame}{numCell})
                    cellList.meshData{newRange(numFrame)}{proccells(numCell)}.(fieldName) = [];
                else
                    cellList.meshData{newRange(numFrame)}{proccells(numCell)}.(fieldName) = ...
                                                    frameTemp{numSignal}{numFrame}{numCell};
                end
            end
        end
            
    end
end
%-------------------------------------------------------------------------------------
disp('---------------------------');
disp('Signals addition Successful');
disp('---------------------------');
return



