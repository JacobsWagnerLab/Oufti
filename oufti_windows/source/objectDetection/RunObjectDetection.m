function RunObjectDetection(hObject, eventdata)

screenSize = get(0,'ScreenSize');
global cellList rawS1Data rawS2Data handles handles1

if ~isfield(cellList,'meshData'), warndlg('CellList is not of the correct form');return;end
if isempty(cellList.meshData{1})
    warndlg('Load the cellList by clicking on the Load analysis button ');
    return;
end

if isempty(rawS1Data)
    warndlg('Load the signal by clicking on the Load signal 1 button ');
    return;
end
objectData = cell(1,length(cellList.meshData));
try
    try
        % R2010a and newer
        iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
        iconsSizeEnums = javaMethod('values',iconsClassName);
        SIZE_32x32 = iconsSizeEnums(2);  % (1) = 16x16,  (2) = 32x32
        jObj = com.mathworks.widgets.BusyAffordance(SIZE_32x32, 'Processing...');  % icon, label
    catch
        % R2009b and earlier
        redColor   = java.awt.Color(1,0,0);
        blackColor = java.awt.Color(0,0,0);
        jObj = com.mathworks.widgets.BusyAffordance(redColor, blackColor);
    end
    jObj.setPaintsWhenStopped(true);  % default = false
    jObj.useWhiteDots(false);         % default = false (true is good for dark backgrounds)
    hh =  figure('pos',[(screenSize(3)/2)-100 (screenSize(4)/2)-100 100 100],'Toolbar','none',...
                 'Menubar','none','NumberTitle','off','DockControls','off');
    pause(0.05);drawnow;
    pos = hh.Position;
    javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
    pause(0.01);drawnow;
    jObj.start;
        % do some long operation...
    disp('--------   Running object detection analysis   --------');
    handles1.objectParams = getObjectDetectionParameters(handles1);
    handles1.objectParams.manual = handles1.objectDetection.manual.Value;
    currentFrame = get(handles.currentframe,'string');
    indexFind = strfind(currentFrame,'of');
    currentFrame = str2double(currentFrame(1:indexFind-1));
    if isnan(currentFrame), currentFrame = 1;end
    if get(handles1.objectDetection.objectRunThisFrame,'value') == 1
       image = rawS1Data(:,:,currentFrame);
       [meshData,cellId] = oufti_getFrame(currentFrame, cellList);
       for cellNum = cellId
           %If the cell is bad, exit politely
            cellIndex = oufti_cellId2PositionInFrame(cellNum,currentFrame,cellList);
            if cellIndex > length(meshData) || isempty(meshData{cellIndex}) || ...
                ~isfield(meshData{cellIndex},'mesh') || size(meshData{cellIndex}.mesh,1) < 4
                disp(['No cell was found for cell ',num2str(cellNum)]);
                cellList.meshData{currentFrame}{cellIndex}.objects = [];
                continue;
            end
            cellStructure = meshData{cellIndex};
            if ~isfield(cellStructure,'model')
                cellStructure.model = [cellStructure.mesh(:,1:2);flipud(cellStructure.mesh(2:end-1,3:4))];
            end
            objectData{currentFrame}{cellIndex} = objectDetectionMain(image, cellStructure,handles1.objectParams,handles1.objectDetection.manual.Value);
            cellList.meshData{currentFrame}{cellIndex}.objects = objectData{currentFrame}{cellIndex};
       end
       %save objectData structure to cellList
           displayObjects(currentFrame);

    elseif get(handles1.objectDetection.objectRunAllFrames,'value') == 1
            objectData = computeObjectsMultiThread(rawS1Data,cellList,handles1.objectParams,handles1.objectDetection.manual.Value);
            for ii = 1:numel(objectData)
                for jj = 1:numel(objectData{ii})
                    cellList.meshData{ii}{jj}.objects = objectData{ii}{jj};
                end
            end
            displayObjects(currentFrame);

    else
        return;
    end
catch err
    displayMessage = err.message;
    warndlg(displayMessage);
    return;
end
 disp('.........  Analysis finished   ......... ');
jObj.stop;
delete(hh)
end