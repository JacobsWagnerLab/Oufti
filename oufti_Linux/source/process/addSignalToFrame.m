function addSignalToFrame(frame,inchannel,outchannel,proccells,rsz,apr,shiftfluo)
    global cellList rawPhaseData rawS1Data rawS2Data
    if length(cellList.meshData)<frame || isequal(outchannel,'-'), return; end
    if frame<1, frame=1; end
    if exist('aip','file')==0, apr=true; end
    sf = [0 0];
    switch inchannel
     case 1
         if ~isempty(who('rawPhaseData'))
             if ~isempty(rawPhaseData)
                 if frame<=size(rawPhaseData,3)
                    img = im2double(rawPhaseData(:,:,frame));
                    img = max(max(img))-img;
                 end
             end
         end
    %  case 2
    %      if ~isempty(who('rawFMData'))
    %          if ~isempty(rawFMData)
    %              if frame<=size(rawFMData,3)
    %                  img = im2double(rawFMData(:,:,frame));
    %              end
    %          end
    %      end
     case 3
         if ~isempty(who('rawS1Data'))
             if ~isempty(rawS1Data)
                 if frame<=size(rawS1Data,3)
                    if ~isempty(shiftfluo), sf = shiftfluo(1,:); end
                    img = im2double(rawS1Data(:,:,frame));
                 end
             end
         end
     case 4
         if ~isempty(who('rawS2Data'))
             if ~isempty(rawS2Data)
                 if frame<=size(rawS2Data,3)
                    if ~isempty(shiftfluo), sf = shiftfluo(2,:); end
                    img = im2double(rawS2Data(:,:,frame));
                 end
             end
         end
     otherwise
        return
    end
if isempty(who('img')), return; end
if isempty(proccells)
   [~,proccells] = oufti_getFrame(frame,cellList);
end

for cell = proccells
    if oufti_doesCellStructureHaveMesh(cell,frame,cellList) && apr
       mesh = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.mesh);
       mesh(:,[1 3])= mesh(:,[1 3])+sf(1); mesh(:,[2 4])= mesh(:,[2 4])+sf(2);
       boxArea = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.box);
       S = getOneSignalM(mesh,boxArea,img,rsz);
    elseif oufti_doesCellStructureHaveMesh(cell,frame,cellList) && ~apr
       mesh = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.mesh);
       mesh(:,[1 3])=mesh(:,[1 3])+sf(1); mesh(:,[2 4])=mesh(:,[2 4])+sf(2);
       boxArea = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.box);
       S = getOneSignalC(mesh,boxArea,img,rsz);
    elseif  oufti_doesCellHaveContour(cell,frame,cellList) && apr
       contour = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.model);
       contour(:,1)=contour(:,1)+sf(1); contour(:,2)=contour(:,2)+sf(2);
       boxArea = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.box);
       S = getOneSignalContourM(contour,boxArea,img,rsz);
    elseif oufti_doesCellHaveContour(cell,frame,cellList) && ~apr
       contour = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.model);
       contour(:,1)=contour(:,1)+sf(1); contour(:,2)=contour(:,2)+sf(2);
       boxArea = double(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.box);
       S = getOneSignalContourC(contour,boxArea,img,rsz);
    else
       S = [];
    end
 if isnumeric(outchannel)
    eval(['cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.signal' num2str(outchannel) '=S;']);
 else
    eval(['cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)}.' outchannel '=S;']);
 end
end
end


%%

    % proccells = proccells2;
    % for cell = proccells
        % if isfield(cellList{frame}{cell},'mesh') && size(cellList{frame}{cell}.mesh,1)>1 && apr
            % mesh = cellList{frame}{cell}.mesh;
            % mesh(:,[1 3])=mesh(:,[1 3])+sf(1); mesh(:,[2 4])=mesh(:,[2 4])+sf(2);
            % S = getOneSignalM(mesh,cellList{frame}{cell}.box,img,rsz);
        % elseif isfield(cellList{frame}{cell},'mesh') && size(cellList{frame}{cell}.mesh,1)>1 && ~apr
            % mesh = cellList{frame}{cell}.mesh;
            % mesh(:,[1 3])=mesh(:,[1 3])+sf(1); mesh(:,[2 4])=mesh(:,[2 4])+sf(2);
            % S = getOneSignalC(mesh,cellList{frame}{cell}.box,img,rsz);
        % elseif isfield(cellList{frame}{cell},'contour') && apr
            % contour = cellList{frame}{cell}.contour;
            % contour(:,1)=contour(:,1)+sf(1); contour(:,2)=contour(:,2)+sf(2);
            % S = getOneSignalContourM(contour,cellList{frame}{cell}.box,img,rsz);
        % elseif isfield(cellList{frame}{cell},'contour') && ~apr
            % contour = cellList{frame}{cell}.contour;
            % contour(:,1)=contour(:,1)+sf(1); contour(:,2)=contour(:,2)+sf(2);
            % S = getOneSignalContourC(contour,cellList{frame}{cell}.box,img,rsz);
        % else
            % S = [];
        % end
        % if isnumeric(outchannel)
            % eval(['cellList{frame}{cell}.signal' num2str(outchannel) '=S;']);
        % else
            % eval(['cellList{frame}{cell}.' outchannel '=S;']);
        % end
    % end
% numCells = length(proccells);
% tic;
% newJob = createJob();
% r = findResource();
% numTasks = r.ClusterSize;
% maxWorkers = p.maxWorkers;
% numTasks = min(numTasks, maxWorkers);
% numTasks = min(numTasks, numCells);
%         
% % Divide the compact frame list and send them to the workers.
% wCells = 1;
% remaining = numCells - ceil(numCells/numTasks);
%         
% for i = 2:numTasks
%     chunk = ceil(remaining / (numTasks-i+1));
%     wCells(i) = wCells(i-1)+chunk; %#ok<AGROW>
%     remaining = remaining - chunk;
% end
%         
% % One job with a suitable number of tasks is faster than many jobs and
% % easier to manage.
% %numTasks = 1;
% for i = 1:numTasks
%     if i<numTasks
%        wFinalCell = wCells(i+1)-1;
%     else
%        wFinalCell = numCells;
%     end
% 
% disp(['Adding signal ' num2str(outchannel) ' for ' ...
%        num2str(wFinalCell-wCells(i)+1)...
%       ' cells: ' num2str(proccells(wCells(i))) '-' ...
%       num2str(proccells(wFinalCell)) ' in frame ' num2str(frame)]);
%   if i <= numCells
%      if numTasks == 1
%      % For debugging
%      signalTempParts={matlabWorkerAddSignalToFrame(cells(wCells(i):...
%                                                wFinalCell),img,rsz,apr)};
%      else
%      t = createTask(newJob, @matlabWorkerAddSignalToFrame, 1,{...
%                     cells(wCells(i):wFinalCell) img rsz apr});
%      end
%   end
% end
% 
% %%
% if numTasks > 1 
%    disp('Submitting job')
%    alltasks = get(newJob, 'Tasks');
%    set(alltasks, 'CaptureCommandWindowOutput', true);
%    submit(newJob);
%       %jobs = [jobs newjob];
%    disp('Awaiting results')
%    waitForState(newJob, 'finished');
%    outputMessages = get(alltasks, 'CommandWindowOutput');
%    for jj = 1:length(outputMessages)
%    disp(outputMessages{jj})
%    end
%    if ~isempty(t.Error),errorMessage = get(t,'ErrorMessage');...
%       disp(['Error:  ' errorMessage]),end     
% signalTempParts = getAllOutputArguments(newJob);
% end
% 
% t2 = toc;
% cellTemp = {};
% for i=1:length(signalTempParts)
%     if i<numTasks
%        wFinalCell = wCells(i+1)-1;
%     else
%        wFinalCell = numCells;
%     end
%             
% cellTemp(wCells(i):wFinalCell) = signalTempParts{i};
% end
% 
% destroy(newJob);
% %%
% for ii = 1:numCells
%     if isnumeric(outchannel)
%        fieldName = sprintf('signal%d', outchannel);
%        cellList.meshData{frame}{ii}.(fieldName) = cellTemp{ii};
%        %setfield(cellList.meshData{frame}{ii},sprintf('signal%d', outchannel),cellTemp{ii});
%        %oufti_addFieldToCellList(ii, frame, sprintf('signal%d', outchannel), cellTemp{ii}, cellList);
%     else
%        %cellList.meshData{frame}{ii}.(fieldName) = cellTemp{ii};
%        oufti_addFieldToCellList(celln, frame, outchannel, S, cellList);
%     end
% end
% end








