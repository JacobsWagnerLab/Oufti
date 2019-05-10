function refineAllParallel(frameRange,proccells)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function refineAll()
%oufti v0.3.1
%@author:  Ahmad J Paintdakhi
%@date:    July 18 2013
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********
%
%**********Input********
%
%**********Purpose******
%Purpose:  This function refines all cells in a given cellList with current
%paramters.  The refinement makes sure there is no bias present in
%different frames especially if a study is a time-lapse.
%==========================================================================
    
global cellList cellListN p rawPhaseData se maskdx maskdy imageForce %declearing global variables.

%check if specified paramters are present in p structure, otherwise,
%display a message and return.
if checkparam(p,'invertimage','algorithm','erodeNum','meshStep','meshTolerance','meshWidth')
    disp('Refining cells failed: one or more required parameters not provided.');
    return;
end
%makes sure a return call is made when algorithm 1 is run.
if ~ismember(p.algorithm,[2 3 4]), disp('There is no refinement routine for algorithm 1'); return; end
fileDependicies = {   'interp2_'
                      'getRigidityForces_'
                      'getRigidityForcesL_'
                      'B.m'
                      'Bf.m'
                      'nanmean.m'
                      'M.m'
                      'align4.m'
                      'box2model.m'
                      'circShiftNew.m'
                      'frdescp.m'
                      'getnormals.m'
                      'getrigidityforces.m'
                      'getrigidityforcesL.m'
                      'ifdescp.m'
                      'interp2a.m'
                      'intersections.m'
                      'intxy2.m'
                      'intxy2C'
                      'intxyMulti.m'
                      'intxyMultiC'
                      'intxySelfC'
                      'isContourClockwise.m'
                      'isDivided.m'
                      'makeccw.m'
                      'model2box.m'
                      'model2geom.m'
                      'model2mesh.m'
                      'setdispfiguretitle.m'
                      'spsmooth.m'
                      'createdispfigure.m'
                      'projectCurve.m'
                      'alignParallel.m'
                      'matlabWorkerProcessCells.m'
                      'phaseBackground.m'
                      'processIndividualCells.m'};
p.stopButton = 0;
for frame = frameRange
    %cellId information is gathered for a given frame from cellList
    if isempty(proccells) 
        [currentFrameData,currentFrameCells] = oufti_getFrame(frame,cellList);
    else
        [currentFrameData,currentFrameCells] = oufti_getAllCellStructureInFrame(proccells,frame,cellList);
    end
    if isempty(currentFrameData) || isempty(currentFrameCells) || currentFrameCells(1) == 0,continue;end
    
    if p.invertimage        
        currentImage = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);%image inverted
    else
        currentImage = rawPhaseData(:,:,frame);
    end
    eroddedImage = img2imge(currentImage,p.erodeNum,se);%image erodded.
    eroddedImage16 = img2imge16(currentImage,p.erodeNum,se);%erodded image converted to 16bit format
    if gpuDeviceCount == 1
        try
            thres = graythreshreg(gpuArray(eroddedImage),p.threshminlevel);
        catch
            thres = graythreshreg(eroddedImage,p.threshminlevel);
        end
    else
        thres = graythreshreg(eroddedImage,p.threshminlevel);
    end
     if gpuDeviceCount == 1
        try
           [externalForceDx,externalForceDy,imageForce(frame)] = getExtForces(gpuArray(eroddedImage),gpuArray(eroddedImage16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(frame));
           externalForceDx = gather(externalForceDx);
           externalForceDy = gather(externalForceDy);
           imageForce(frame).forceX = gather(imageForce(frame).forceX);
           imageForce(frame).forceY = gather(imageForce(frame).forceY);
        catch
            [externalForceDx,externalForceDy,imageForce(frame)] = getExtForces(eroddedImage,eroddedImage16,maskdx,maskdy,p,imageForce(frame));
        end
     else
        [externalForceDx,externalForceDy,imageForce(frame)] = getExtForces(eroddedImage,eroddedImage16,maskdx,maskdy,p,imageForce(frame));
     end
    %display a message if one of the external forces is returned with an
    %empty value
    if isempty(externalForceDx), disp('Refining cells failed: unable to get energy'); return; end

    %------------------------------------------------------------------------------
    %global variables such as cellList is  converted to local varialbe tempCellList
    %for multi-threading approach
    %tempCellList = cellList;
    tempP = p;
    tempSe = se;
    tempMaskdx = maskdx;
    tempMaskdy = maskdy;
    tempCellListN = cellListN;
    %------------------------------------------------------------------------------
   
    nr_cells = length(currentFrameCells);
      
    %--------------------------------------------------------------------------
    % newJob is a variable that will contain tasks/threads for parallel
    % computation.
    %----------------------------------------------------------------------
    %finds matlab version and assigns multi-threading variables
    %accordingly.  Matlab programming language has changed initialization
    %routines of parallel computation from version 7 onwards.... Weird!!!!
    matlabVersion = version;
    if str2double(matlabVersion(1)) < 8
        sched = parcluster('scheduler','type','local');
        newJob = createJob(sched);
        nTasks = sched.ClusterSize;
    else
        sched = parcluster(parallel.defaultClusterProfile); 
        newJob = createJob(sched);
        set(newJob,'AutoAttachFiles', false);
        set(newJob,'AttachedFiles',fileDependicies);
        nTasks = sched.NumWorkers;
    end

    maxWorkers = p.maxWorkers;
    nTasks = min(nTasks, maxWorkers);
    nTasks = min(nTasks, ceil(nr_cells/8));
    %--------------------------------------------------------------------------

    %--------------------------------------------------------------------------
    % Divide the compact cell lists and send them to the workers.
    wCells = 1;
    processIncrement = ceil(nr_cells/nTasks);
    lastIncrement = nr_cells - ((nTasks-1)*processIncrement);
    if lastIncrement <= 0, nTasks = nTasks -1;end
    for i = 2:nTasks
        wCells(i) = wCells(i-1)+processIncrement;%#ok<AGROW>
        if wCells(i) >= nr_cells, nTasks = i; break; end
    end
    if lastIncrement <=0, wCells(end) = nr_cells;end
    %--------------------------------------------------------------------------------

    %--------------------------------------------------------------------------------
    %for debugging purposes make number of nTasks = 1, otherwise if nTasks
    %greater than 1 prallel computation is done.  In this stage one can not
    %perform debugging as computation is done in the background utilizing
    %different number of threads/tasks.
    %nTasks = 1;
    if nr_cells <= 10, nTasks = 1;end

        for i = 1:nTasks
            if i<nTasks
                wFinalCell = wCells(i+1)-1;
            else
                wFinalCell = nr_cells;
            end
            disp(['Making tasks for ' num2str(wFinalCell-wCells(i)+1) ' cells given the range: ' ...
                   num2str(currentFrameCells(wCells(i))) '-' num2str(currentFrameCells(wFinalCell))]);
            if i <= nr_cells
               if nTasks == 1

               % For debugging
                cellTempParts = {matlabWorkerRefineCells(currentFrameData(wCells(i):wFinalCell), ...
                                currentFrameCells(wCells(i):wFinalCell),tempP,...
                                eroddedImage,externalForceDx, externalForceDy, frame, tempSe,...
                                tempMaskdx,tempMaskdy,tempCellListN,thres)};
               else
                  if tempP.fitDisplay == 1, warndlg('set "fitDisplay" parameter value to 0');return;end
                  tempCellData = currentFrameData(wCells(i):wFinalCell);
                  t = createTask(newJob,@matlabWorkerRefineCells,1,{tempCellData...
                                 currentFrameCells(wCells(i):wFinalCell) tempP ...
                                 eroddedImage externalForceDx externalForceDy frame ...
                                 tempSe tempMaskdx tempMaskdy tempCellListN thres});
               end
            end
        end 
        %--------------------------------------------------------------------------------

        %--------------------------------------------------------------------------------
        %if the number of tasks or threads chosen above is greater than 1, the
        %number of tasks are submitted to each thread for processing.  Variable
        %newJob is the vector containing number of tasks.
        if nTasks > 1 
            disp('Submitting job')
            alltasks = get(newJob, 'Tasks');
            if str2double(matlabVersion(1)) < 8
                set(alltasks, 'CaptureCommandWindowOutput', true);
                submit(newJob);
                disp('Awaiting results')
                waitForState(newJob, 'finished');
                %outputMessages = get(alltasks, 'CommandWindowOutput');
            else
                set(alltasks, 'CaptureDiary', true);
                submit(newJob);
                disp('Awaiting results');
                wait(newJob);
                %outputMessages = get(alltasks, 'Diary');
            end
            if str2double(matlabVersion(1)) < 8
                cellTempParts = newJob.getAllOutputArguments;
            else
                cellTempParts = newJob.fetchOutputs;
            end
        end
      


%--------------------------------------------------------------------------
% Stitch together the output
cellTemp = {};
for i=1:length(cellTempParts)
    if i<nTasks
        wFinalCell = wCells(i+1)-1;
    else
        wFinalCell = nr_cells;
    end
    if iscell(cellTempParts{i})
        if cellfun(@isempty,cellTempParts{i})
           cellTemp(wCells(i):wFinalCell) = cellTempParts{i};
        else
           cellTemp(wCells(i):wFinalCell) = cellTempParts{i};
        end
    else
        %------------------------------------------------------------------
        %check if gathered cell parts from a thread or empty or not.  If
        %they are empty then allocate empty spaces for all the empty cells.
        %This change makes certain that due to empty cellTempParts cells
        %matrix allocation or deletion error is not encountered.  Ahmad.P
        %October 3, 2012.
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
if str2double(matlabVersion(1)) < 8
    destroy(newJob);
else
    delete(newJob);
end
    %--------------------------------------------------------------------------
    disp(['Frame ' num2str(frame) ': Refinement of ' num2str(numel(cellTemp)) ' cells succeeded']);
    %----------------------------------------------------------------------
    %process the two containers collected earlier and save new refined
    %cellst to a cellList.
    for ii = 1:numel(cellTemp)
        if ~isempty(cellTemp{ii}) 
            if ~isempty(proccells)
                cellList = oufti_addCell(proccells(ii),frame,cellTemp{ii},cellList);
            else
                cellList.meshData{frame}{ii}.mesh = cellTemp{ii}.mesh;
            end
        end
    end
    %----------------------------------------------------------------------

    if p.stopButton == 1
            error('all tasks aborted and data being saved')
      
    end
end
    
end
