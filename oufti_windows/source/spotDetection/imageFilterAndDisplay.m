function w = imageFilterAndDisplay(frameRange,cellRange1,cellRange2,adjustMode,outfile,...
                                outscreen,outfield,params,totalFrames,images)
%-----------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------
%function w = imageFilterAndDisplay(frameRange,cellRange1,cellRange2,adjustMode,outfile,...
%                                outscreen,outfield,params,L1,images)
%oufti.v0.2.6
%@author:  Ahmad J Paintdakhi
%@date:    December 3, 2012
%@copyright 2012-2013 Yale University
%=================================================================================
%**********output********:
%w:  window of a progress bar.
%**********Input********:
%frameRange:   Frame range to be processed.
%cellRangle1:  Value for first input of a cellRange vector.
%cellRange2:   Value for second input of a cellRange vector.
%images:	   All the signal images.
%adjustMode:  Either 1 or 0, if 1 spots are shown on a current GUI window
%             if 0 spots are not shown but rather processed using parallel 
%             computation.
%outfile:     1 or 0 if indicated.
%outscreen:   1 or 0 if indicated.
%outfield:    usuall "spots".
%params:      parameter array.
%totalFrames: total number of frames available for processing.          
%==================================================================================
%------------------------------------------------------------------------------------
% Filtering and integrating images
global spotlist lst handles handles1 cellList imageHandle
%pragma function needed to include files for deployment
%#function [matlabWorkerSpotCells  processIndividualSpots imcrop cat poly2mask conv2 size]
%#function [single  max mean find bwtraceboundary frdescp ifdescp filterIM im2bw regionprops]
%#function [sum  bandPassFilter logical uint16 sort repmat meshgrid setdiff ones rem]
%#function [length  double ceil fitoptions fittype fit reshape projectToMesh inpolygon bwlabel]
%#function [centerOfMass  getextradata fft2 zeros ifft2 GaussWin min mod real varargout graythresh]
%#function [strcmpi  floor varargin]
isho = @(x) imshow(x,[min(x(:)) max(x(:))],'InitialMagnification',400);
w = [];
matlabVersion = version;
 fileDependicies = {    'imageFilterAndDisplay'
                        'oufti_getCellStructure'
                        'oufti_getFrame'
                        'oufti_doesCellStructureHaveMesh'
                        'GaussWin'
                        'bandPassFilter'
                        'centerOfMass'
                        'filterIM'
                        'frdescp'
                        'getParameters'
                        'getextradata'
                        'ifdescp'
                        'matlabWorkerSpotCells'
                        'positionEstimate'
                        'processIndividualSpots'
                        'projectToMesh'
                        'repmat_'
                        'repmat'
                        'waitbarN'};
if ~adjustMode
   if ~outfile, warndlg('***** Click on "Meshes" box and select "File" to save output data *****');return;end
   w = waitbarN(0, 'Filtering / integrating images');
   for frame = frameRange
       disp(['----- Processing frame  ' num2str(frame) ' ----'])
       if isempty(cellRange1), cellRange1Temp = 1; else cellRange1Temp = cellRange1;end
       if isempty(cellRange2), cellRange2Temp = length(cellList.meshData{frame}); else cellRange2Temp=cellRange2;end
       numCells = (cellRange2Temp - cellRange1Temp)+1;
       cellRange = cellRange1Temp:cellRange2Temp;
       if str2double(matlabVersion(1)) < 8
            sched = findResource('scheduler','type','local');
            newJob = createJob(sched);
            numTasks = sched.ClusterSize;
       else
            sched = parcluster(); 
            newJob = createJob(sched);
            set(newJob,'AutoAttachFiles', false);
            set(newJob,'AttachedFiles',fileDependicies);
            numTasks = sched.NumWorkers;
       end
       numTasks = min(numTasks, numCells);
       % Divide the compact cell lists and send them to the workers.
       wCells = 1;
       processIncrement = ceil(numCells/numTasks);
       lastIncrement = numCells - ((numTasks-1)*processIncrement);
       if lastIncrement <= 0, numTasks = numTasks -1;end
       for i = 2:numTasks
            wCells(i) = wCells(i-1)+processIncrement;%#ok<AGROW>
            if wCells(i) >= numCells, numTasks = i; break; end
       end
       if lastIncrement <=0, wCells(end) = numCells;end
        %--------------------------------------------------------------------------
        %for debugging purposes make number of numTasks = 1, otherwise if nTasks
        %greater than 1 prallel computation is done.  In this stage one can not
        %perform debugging as computation is done in the background utilizing
        %different number of threads/tasks.
        %numTasks = 1;
        if numCells <= 9, numTasks = 1;end
        for i = 1:numTasks
            if i<numTasks
                wFinalCell = wCells(i+1)-1;
            else
                wFinalCell = numCells;
            end
            disp(['Making tasks for ' num2str(wFinalCell-wCells(i)+1) ' cells given the range: ' ...
                num2str(cellRange(wCells(i))) '-' num2str(cellRange(wFinalCell))]);
            if i <= numCells
            cellData = cellList.meshData{frame}(wCells(i):wFinalCell);
            %cellData = oufti_getAllCellStructureInFrameForSignalExtraction((cellRange(wCells(i)):cellRange(wFinalCell)),cellList.meshData{frame},cellList.cellId{frame});
            if numTasks == 1
            % For debugging
                cellTempParts = {matlabWorkerSpotCells(cellData,cellRange(wCells(i):wFinalCell),...
                                 params,images(:,:,frame),adjustMode)};
            else
                t = createTask(newJob,@matlabWorkerSpotCells,1,{cellData ...
                               cellRange(wCells(i):wFinalCell) params images(:,:,frame) ...
                               adjustMode});
            end
            end
        end
        %------------------------------------------------------------------
        %if the number of tasks or threads chosen above is greater than 1, the
        %number of tasks are submitted to each thread for processing.  Variable
        %newJob is the vector containing number of tasks.
        if numTasks > 1 
        disp('Submitting job')
        if str2double(matlabVersion(1)) < 8
            submit(newJob);
            disp('Awaiting results')
            waitForState(newJob, 'finished');
        else
            submit(newJob);
            disp('Awaiting results');
            wait(newJob);
        end
        if ~isempty(t.Error),errorMessage = get(t,'ErrorMessage');...
            disp(['Error:  ' errorMessage]),end   
        %all the outputs from different tasks are created and stored inside
        %variable frameTempParts.
        if str2double(matlabVersion(1)) < 8
            cellTempParts = newJob.getAllOutputArguments;
        else
            cellTempParts = newJob.fetchOutputs;
        end
        
        end
        %--------------------------------------------------------------------------

        %--------------------------------------------------------------------------
        % Stitch together the output
        cellTemp = {};
        for i=1:length(cellTempParts)
            if i<numTasks
                wFinalCell = wCells(i+1)-1;
            else
                wFinalCell = numCells;
            end
            if iscell(cellTempParts{i})
                try
                    if cellfun(@isempty,cellTempParts{i})
                    cellTemp(wCells(i):wFinalCell) = cellTempParts{i};
                    else
                    cellTemp(wCells(i):wFinalCell) = cellTempParts{i};
                    end
                catch err
                    if strcmpi(err.identifier,'MATLAB:subsassigndimmismatch')
                        cellTemp(wCells(i):sum(cellfun(@length,cellTempParts))) = cellTempParts{i};
                    end
                end
            else
                %------------------------------------------------------------------
                %check if gathered cell parts from a thread or empty or not.  If
                %they are empty then allocate empty spaces for all the empty cells.
                %This change makes certain that due to empty cellTempParts cells
                %matrix allocation or deletion error is not encountered.  Ahmad.P
                %November 26, 2012.
                if isempty(cellTempParts{i})
                    cellTempParts{i} = {[]};
                    cellTemp(wCells(i):wFinalCell) = cellTempParts{i};
                else
                    cellTemp(wCells(i):wFinalCell) = cellTempParts{i};
                end
                %------------------------------------------------------------------
            end
        end
        
        %destroy newJob, a variable that stores all the data from the different
        %tasks/threads.  This is almost equivalent to delete function in c++ as the
        %memory is de-allocated back to the system.
        destroy(newJob);
        %--------------------------------------------------------------------------
        for ii = 1:length(cellTemp)
            try
                if ~isempty(cellList.meshData{frame}{cellRange(ii)})
                eval(['cellList.meshData{frame}{cellRange(ii)}.' outfield ' = cellTemp{ii};']);
                end
            catch err
                continue;
            end
        end
        waitbar(frame/(totalFrames),w);
   end
end
        
if adjustMode
   lst = []; spotlist = [];
   %h=createfigure;
   imageHandle.fig = handles.impanel;
   handles1.spotList = {};
   if isempty(cellRange1)
        cellRange=1: 1:max(cellfun(@max,cellList.cellId(~cellfun(@isempty,cellList.cellId(1:end)))));
   else
        cellRange = cellRange1:cellRange2;
   end
   frind=1;
   frame=frameRange(frind);
   cellNum= 0;
   goup = true;
   while true
         while true
               if goup
                  cellNum=cellNum+1;
                  if cellNum<=length(cellRange),cell = cellRange(cellNum);end
                  if cell==max(cellList.cellId{frame}) || cellNum>length(cellRange)
                    frind=mod(frind,length(frameRange))+1;
                    frame=frameRange(frind);
                    cellNum=1;
                    if isempty(cellRange1),[~,cellRange] = oufti_getFrame(frame,cellList);end
                    cell = cellRange(cellNum);
                  end
               else
                   cellNum=cellNum-1;
                   if cellNum>0,cell=cellRange(cellNum);end
                   if cell<=0 || cellNum<=0
                      frind=mod(frind-2,length(frameRange))+1;
                      frame=frameRange(frind);
                      if isempty(cellRange1),[~,cellRange] = oufti_getFrame(frame,cellList);end
                      cellNum = length(cellRange);
                      cell = cellRange(cellNum);
                    end
                    handles1.cell = cell;
                end
                if oufti_doesCellStructureHaveMesh(cell,frame,cellList), break; end
         end
%----------------------------------------------------------------------------------------------
%update December 4-5 2012
%Ahmad Paintdakhi
          if oufti_doesCellStructureHaveMesh(cell,frame,cellList)
             % Get the data for all methods
             cellData = oufti_getCellStructure(cell,frame,cellList);
             Cell = cell;
             image = images(:,:,frame);
             if ~isfield(cellData,'box')
                  roiBox(1:2) = round(max(min(cellData.model(:,1:2))-25,1));
                  roiBox(3:4) = min(round(max(cellData.model(:,1:2))+25),...
                     [size(image,2) size(image,1)])-roiBox(1:2);
                 cellData.box = roiBox;
             end
             rawImage = double(imcrop(image,cellData.box))/65535;
             [r,c] = size(rawImage);  %# Get the image dimensions
             nPad = abs(c-r)/2;         %# The padding size
             if c > r                   %# Pad rows
              newImage = padarray(rawImage,[floor(nPad) 0],mean(mean(rawImage)),'pre');  %# Pad to'pre');
              rawImage = padarray(newImage,[ceil(nPad) 0],mean(mean(rawImage)),'post');   %# Pad bott'post');
            elseif r > c               %# Pad columns
              newImage = padarray(rawImage,[0 floor(nPad)],...  %# Pad left
                                            mean(mean(rawImage)),'pre');
              rawImage = padarray(newImage,[0 ceil(nPad)],...   %# Pad right
                                  mean(mean(rawImage)),'post');
            end
             plgx = [cellData.mesh(1:end-1,1);flipud(cellData.mesh(:,3))]-cellData.box(1)+1;
             plgy = [cellData.mesh(1:end-1,2);flipud(cellData.mesh(:,4))]-cellData.box(2)+1;
             
             [spotStructure,filtImage,dispStructure] = processIndividualSpots(cellData,Cell,params,image,adjustMode);
             disp(['Frame ' num2str(frame) ' cell ' num2str(cell) ', ' num2str(length(spotStructure.l)) ' spots identified']);
             screenSize = get(0,'ScreenSize');
             pos = get(handles.maingui,'position');
             pos = [max(pos(1),1) max(1,min(pos(2),...
             screenSize(4)-20-max(pos(4),600))) max(pos(3:4),[1000 600])];
             set(imageHandle.fig,'pos',[17 170 pos(3)-1000+700 pos(4)-800+600]) 
             g = get(imageHandle.fig,'children');
             delete(g); 
             imageHandle.ax = axes('parent',imageHandle.fig);
             imageHandle.himage = imshow(rawImage,[min(rawImage(:)) max(rawImage(:))],'parent',imageHandle.ax);
             xValue = size(rawImage,1);
             yValue = size(rawImage,2);
             set(imageHandle.ax,'pos',[0 0 1 1],'NextPlot','add');
             plot(imageHandle.ax,plgx+(size(rawImage,2)-c)/2,plgy+(size(rawImage,1)-r)/2,'Color',[0 0.7 0])
% % %              if get(handles1.GAU,'value') == 1
                 if ~isempty(dispStructure.w) 
                     line([xValue*.021,yValue*.05],[xValue*.05,xValue*0.05],'LineStyle','-','LineWidth',4,'Color',[0 0.5 0]);
                     text(xValue*.07,xValue*0.05,'adj. Rsquared','Color',[0 0.5 0],'FontSize',12);
                     line([xValue*.021,yValue*.05],[xValue*.08,xValue*0.08],'LineStyle','-','LineWidth',4,'Color',[0.7 0 0]);
                     text(xValue*.07,xValue*.08,'Width','Color',[0.7 0 0],'FontSize',12);
                     line([xValue*.021,yValue*.05],[xValue*.11,xValue*0.11],'LineStyle','-','LineWidth',4,'Color',[1 0.5 0.5]);
                     text(xValue*.07,xValue*.11,'Height','Color',[1 0.5 0.5],'FontSize',12);
                     xBoxValue = reshape(spotStructure.x - cellData.box(1)+1,1,[]);
                     xBoxValue = xBoxValue + (size(rawImage,2)-c)/2;
                     yBoxValue = reshape(spotStructure.y - cellData.box(2)+1,1,[]);
                     yBoxValue = yBoxValue + (size(rawImage,1)-r)/2;
                     plot(xBoxValue,yBoxValue,'o','LineWidth',1.5)

                     for k = 1:length(dispStructure.adj_Rsquared)
                        text(xValue*0.4,k*3,[num2str(k),':  '],'Color',[0,1,1],'FontSize',10);
                        text(double(xBoxValue(k))+1,double(yBoxValue(k)),num2str(k),'Color',[0,1,1],'FontSize',14);
                        text(xValue*0.45,k*3,num2str(dispStructure.adj_Rsquared(k)),'Color',[0 0.5 0],'FontSize',10);
                        text(xValue*0.55,k*3,num2str(dispStructure.w(k)),'Color',[0.7 0 0],'FontSize',10); 
                        text(xValue*0.65,k*3,num2str(dispStructure.h(k)),'Color',[1 0.5 0.5],'FontSize',10);
                     end
                        set(imageHandle.ax,'pos',[0 0 1 1],'NextPlot','replace');
                        set(imageHandle.fig,'pos',[17 170 pos(3)-1000+700 pos(4)-800+600]);
                 end
                  if params.filtWin == 1,h = figure('Name','Filter Result','NumberTitle','off','position',[500 500 500 500]);imshow(filtImage,'InitialMagnification',600);end
% % %              else
% % %                     xBoxValue = reshape(spotStructure.x - cellData.box(1)+1,1,[]);
% % %                     xBoxValue = xBoxValue + (size(rawImage,2)-c)/2;
% % %                     yBoxValue = reshape(spotStructure.y - cellData.box(2)+1,1,[]);
% % %                     yBoxValue = yBoxValue + (size(rawImage,1)-r)/2;
% % %                     plot(xBoxValue,yBoxValue,'xr','LineWidth',4)
% % %                     for k = 1:length(spotStructure.l)
% % %                         text(double(xBoxValue(k))+1,double(yBoxValue(k)),num2str(k),'Color',[0,1,1],'FontSize',14);
% % %                     end
% % %                     set(imageHandle.ax,'pos',[0 0 1 1],'NextPlot','replace');
% % %                     set(imageHandle.fig,'pos',[17 170 pos(3)-1000+700 pos(4)-800+600]);
% % %               end
          end
%----------------------------------------------------------------------------------------------
             %-------------------------------------------------------------
             %Ahmad. P Nov. 9 2012 image of the current frame is saved to
             %handle imageHandle as hImageHistory variable to be used for
             %contrastSlider function.
             imageHandle.hImageHistory = get(imageHandle.himage,'CData');
             %find minimum intensity of an image
             minImageIntensity = min(min(imageHandle.hImageHistory));
             %find maximum intensity of an image
             maxImageIntensity = max(max(imageHandle.hImageHistory));
             %changes the constrastslider min and max values as per the
             %values found in the above two statements.
             try
                 set(handles1.contrastSlider,'min',0,'max',maxImageIntensity,...
                     'SliderStep',[0.0001/(maxImageIntensity) 0.0001/minImageIntensity]);
             catch err
                 
                 continue;
             end
             %-------------------------------------------------------------
             handles1.cell = cell;
             handles1.frame = frame;
             while true
                   set(handles1.spotFinderPanel,'UserData',[]);
                   try
                        waitfor(handles1.spotFinderPanel,'UserData');
                   catch ME
                         disp(ME)   
                   end
                   if ~ishandle(handles1.spotFinderPanel), return; end
                 
                   params = getParameters(handles1,params);
                   handles1.spotParams = params;
                   u = get(handles1.spotFinderPanel,'UserData');
                   set(handles1.spotFinderPanel,'UserData',[]);
                   if u==0
                      return
                   elseif u==1
                          goup = true;
                          break
                   elseif u==-1
                          goup = false;
                          break
                   end
             end
          handles1.frame = frame;
   end% frame
   stoprun();
end
   
end