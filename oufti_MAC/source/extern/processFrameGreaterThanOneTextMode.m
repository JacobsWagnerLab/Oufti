function proccells  = processFrameGreaterThanOneTextMode(frame, proccells,~)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function proccells  = processFrameGreaterThanOneTextMode(frame, proccells,~)
%oufti.v0.3.1
%@author:  Ahmad J Paintdakhi
%@date:    May 23 2012
%@modified: June 11 2013
%@copyright 2012-2013 Yale University
%==========================================================================
% This function is for processing all frames except the first one
% 
% It is only looking for the cells that existed before and splits them if
% necessary.
%**********output********:
%proccells -- cell array that are processed using parallel or serial
%computation.
%**********Input********:
%frame -- frame # that is to be processed.
%proccells -- array of cells that need to be processed.
%saveFile -- name of the file where data is saved.  This input variable is
%needed for naming the command window output message's file.
%==========================================================================

global maskdx maskdy imsizes cellList cellListN rawPhaseData se p shiftframes
global wCell mC1 mC2 wthres w_err w0_err 
global toggle_err coefPCA mCell
global wcc mlp slp mln sln coefS N weights dMax
global maxWorkers imageForce
%global CS_V CS_Kch CS_m
%-------------------------------------------------------------------------
%pragma function needed to include files for deployment
%#function [interp2_ B Bf M align4 truncateFile.pl box2model circShiftNew]
%#function [frdescp getnormals getrigidityforces getrigidityforcesL ifdescp interp2a]
%#function [intersections intxy2 intxy2C intxyMulti intxyMultiC intxySelfC]
%#function [isContourClockwise isDivided makeccw model2box model2geom model2mesh]
%#function [setdispfiguretitle spsmooth createdispfigure projectCurve alignParallel matlabWorkerProcessCells]
%#function [phaseBackground processIndividualCells]
%-------------------------------------------------------------------------
isShiftFrame = 0;
fileDependicies = {   'interp2_.mexw64'
                      'B.m'
                      'Bf.m'
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
                      'intxy2C.mexw64'
                      'intxyMulti.m'
                      'intxyMultiC.mexw64'
                      'intxySelfC.mexw64'
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
disp(['Processing frame ' num2str(frame)])
cellListN = cellfun(@length,cellList.meshData);
l_maskdx = maskdx;
l_maskdy = maskdy;
l_imsizes = imsizes;
l_cellListN = cellListN;
l_se = se;
l_p = p;
l_wCell = wCell;
l_mC1 = mC1;
l_mC2 = mC2;
l_wthres = wthres;
l_wcc = wcc;
l_mlp = mlp;
l_slp = slp;
l_mln = mln;
l_sln = sln;

% For the new processCell()
l_args.wcc = l_wcc;
l_args.mlp = l_mlp;
l_args.slp = l_slp;
l_args.mln = l_mln;
l_args.sln = l_sln;
l_args.se  = l_se;
l_args.maskdx = l_maskdx;
l_args.maskdy = l_maskdy;
l_args.l_mC1 = l_mC1;
l_args.l_mC2 = l_mC2;
l_args.l_wCell = l_wCell;
l_args.coefPCA = coefPCA;
l_args.mCell   = mCell;
l_args.coefS   = coefS;
l_args.N       = N;
l_args.weights = weights;
l_args.dMax    = dMax;
l_args.l_wthres = l_wthres;
l_args.w_err=w_err;
l_args.w0_err=w0_err;
l_args.toggle_err=toggle_err;
l_cellListN(frame) = l_cellListN(frame-1);
l_shiftframes = shiftframes;

isShiftFrame = 0;
cellMesh = 0;
if ~isempty(shiftframes), isShiftFrame = 1; end

if frame>size(rawPhaseData,3), return; end
img = rawPhaseData(:,:,frame);

imge = img2imge(img,p.erodeNum,se);
imge16 = img2imge16(img,p.erodeNum,se);
%bgr = phasebgr(imge,thres,se,p.bgrErodeNum);
allMap = zeros(size(img));

if gpuDeviceCount == 1
    try
       thres = graythreshreg(gpuArray(imge),p.threshminlevel);
       [extDx,extDy,imageForce(frame)] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(frame));
       extDx = gather(extDx);
       extDy = gather(extDy);
       imageForce(frame).forceX = gather(imageForce(frame).forceX);
       imageForce(frame).forceY = gather(imageForce(frame).forceY);
    catch
        thres = graythreshreg(imge,p.threshminlevel);
        [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
    end
else
    thres = graythreshreg(imge,p.threshminlevel);
    [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
end
if isempty(extDx), disp('Processing timelapse frame failed: unable to get energy'); return; end
[~, cellIdPrevious] = oufti_getFrame(frame-1, cellList);
for cell = cellIdPrevious
    if oufti_doesCellStructureHaveMesh(cell,frame-1,cellList)
        cellMesh = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(cell,frame-1,cellList)}.mesh;
    end
    if size(cellMesh,2)==4
        allMap = allMap +... 
        imerode(roipoly(allMap,[cellMesh(:,1);flipud(cellMesh(:,3))],[cellMesh(:,2);flipud(cellMesh(:,4))]),se);
    end
end
allMap = min(allMap,1);
if isempty(proccells), proccells = cellIdPrevious; end
[cellListPrevious,~] = oufti_getAllCellStructureInFrame(proccells, frame-1, cellList);

nr_cells = length(proccells);
if isempty(length(proccells)),dip('No cells to process'); return; end
%--------------------------------------------------------------------------
% newJob is a variable that will contain tasks/threads for parallel
% computation.
%----------------------------------------------------------------------
%finds matlab version and assigns multi-threading variables
%accordingly.  Matlab programming language has changed initialization
%routines of parallel computation from version 7 onwards.... Weird!!!!
matlabVersion = version;
if str2double(matlabVersion(1)) < 8
    sched = findResource('scheduler','type','local');
    newJob = createJob();
    nTasks = sched.ClusterSize;
else
    sched = parcluster(); 
    newJob = createJob(sched);
    set(newJob,'AutoAttachFiles', false);
    set(newJob,'AttachedFiles',fileDependicies);
    nTasks = sched.NumWorkers;
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
maxWorkers = p.maxWorkers;
nTasks = min(nTasks, maxWorkers);
nTasks = min(nTasks, ceil(nr_cells/8));
%--------------------------------------------------------------------------------

%--------------------------------------------------------------------------------
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
try
        for i = 1:nTasks
        if i<nTasks
        wFinalCell = wCells(i+1)-1;
        else
        wFinalCell = nr_cells;
        end
        disp(['Making tasks for ' num2str(wFinalCell-wCells(i)+1) ' cells given the range: ' ...
        num2str(proccells(wCells(i))) '-' num2str(proccells(wFinalCell))]);
        if i <= nr_cells
        if nTasks == 1

        % For debugging
        cellTempParts = {matlabWorkerProcessCells(cellListPrevious(wCells(i):wFinalCell), ...
                    proccells(wCells(i):wFinalCell),l_p,...
                    l_args,img, imge,extDx, extDy, allMap, thres, frame,isShiftFrame,l_shiftframes)};
        else
        t = createTask(newJob,@matlabWorkerProcessCells,1,{cellListPrevious(wCells(i):wFinalCell)...
               proccells(wCells(i):wFinalCell) ...
               l_p l_args img imge extDx extDy allMap thres frame isShiftFrame l_shiftframes});
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

        cellTempParts = getAllOutputArguments(newJob);

        end
%catches an error sometimes caused due to matlab's issue with scheduling a
%task correctly and throws a false positive error called 
%"identifier: 'distcomp:localscheduler:InvalidState'" .
catch ME1
    idSegLast = regexp(ME1.identifier, '(?<=:)\w+$', 'match');
    if strcmp(idSegLast,'InvalidState') 
        disp(['Trying frame ' num2str(frame) ' one more time'])
        for i = 1:nTasks
            if i<nTasks
            wFinalCell = wCells(i+1)-1;
            else
            wFinalCell = nr_cells;
            end
            disp(['Making tasks for ' num2str(wFinalCell-wCells(i)+1) ' cells given the range: ' ...
            num2str(proccells(wCells(i))) '-' num2str(proccells(wFinalCell))]);
            if i <= nr_cells
            if nTasks == 1

            % For debugging
            cellTempParts = {matlabWorkerProcessCells(cellListPrevious(wCells(i):wFinalCell), ...
                        proccells(wCells(i):wFinalCell),l_p,...
                        l_args,img, imge,extDx, extDy, allMap, thres, frame,isShiftFrame,l_shiftframes)};
            else
            t = createTask(newJob,@matlabWorkerProcessCells,1,{cellListPrevious(wCells(i):wFinalCell)...
                   proccells(wCells(i):wFinalCell) ...
                   l_p l_args img imge extDx extDy allMap thres frame isShiftFrame l_shiftframes});
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

            cellTempParts = getAllOutputArguments(newJob);

        end
    else
        rethrow(ME1) %if processing of current frame fails again rethrow error
    end
end
%--------------------------------------------------------------------------


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
destroy(newJob);
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
% Update globals.
maskdx = l_maskdx;
maskdy = l_maskdy;
imsizes = l_imsizes;
cellListN(frame) = l_cellListN(frame);
se = l_se;
wCell = l_wCell;
mC1 = l_mC1;
mC2 = l_mC2;
wthres = l_wthres;
disp('----- Check individual cell meshes and store if conditions are passed -----')

if ~oufti_doesFrameExist(frame, cellList)
    cellList = oufti_makeNewFrameInCellList(frame, cellList);
end

for i = 1:length(proccells)
    try
    if isempty(cellTemp{i})
        celln = proccells(i);
        prevStruct = oufti_getCellStructure(celln,frame-1,cellList);
        cellStruct = prevStruct;
        cellStruct.mesh = single(0);
        cellStruct.stage = 0;
		cellList = oufti_addCell(celln, frame, cellStruct, cellList);
        reason = 'problem getting mesh';
        disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
        continue;
    end
    celln = proccells(i);
    prevStruct = oufti_getCellStructure(celln,frame-1,cellList);
    res          = cellTemp{i}.res;
    cellMesh     = double(cellTemp{i}.mesh);
    pcCell       = single(cellTemp{i}.pcCell);
    cCell        = single(cellTemp{i}.cCell);
    isct         = cellTemp{i}.isct;
    fitquality   = cellTemp{i}.fitquality;
    roiBox       = cellTemp{i}.roiBox;
    boxModel     = cellTemp{i}.boxModel;
    roiImg       = single(cellTemp{i}.roiImg);
    roiExtDx     = single(cellTemp{i}.roiExtDx);
    roiExtDy     = single(cellTemp{i}.roiExtDy);
    roiAmap      = single(cellTemp{i}.roiAmap);
    if ~isempty(cCell),cellarea = polyarea(cCell(:,1),cCell(:,2)); else cellarea = 0;end
    % checking quality and storing the cell
    if ~isempty(cCell) && ~isempty(isct) && ~isct && fitquality<p.fitqualitymax && ...
               min(min(cCell))>1+p.noCellBorder && max(cCell(:,1))<imsizes(1,2)-p.noCellBorder...
              && max(cCell(:,2))<imsizes(1,1)-p.noCellBorder &&...
              length(cellMesh)>1 && p.areaMin<cellarea && p.areaMax>cellarea

        % if the cell passed the quality test and it is not on the
        % boundary of the image - store it
     if res>0 % Splitting the cell
        % mesh1 = flipud(mesh(1:res-1,:)); % daughter cell
        % mesh2 = mesh(res+1:end,:);
        % select the cells so that the mesh always goes from the stalk pole
        mesh1 = flipud(cellMesh(res+1:end,:)); % daughter cell
        mesh2 = cellMesh(1:res-1,:); % mother cell
        if ismember(p.algorithm,[2 3])
           pcCell1 = splitted2model(mesh1,p);
           pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
           pcCell1 = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,p,false,roiBox,...
                           thres,[frame celln]);
           pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
           cCell1 = double(model2geom(pcCell1,p.algorithm));
           pcCell2 = splitted2model(mesh2,p);
           pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
           pcCell2 = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,p,false,roiBox,...
                           thres,[frame celln]);
           pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
           cCell2 = double(model2geom(pcCell2,p.algorithm));
        else
           pcCell1 = align4IM(mesh1,p);
           pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
           pcCell1 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,p,roiBox,...
                            thres,[frame celln]);
           pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
           cCell1 = double(pcCell1);
           pcCell2 = align4IM(mesh2,p);
           pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
           pcCell2 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,p,roiBox,...
                            thres,[frame celln]);
           boxModel2 = pcCell2;
           pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
           cCell2 = double(pcCell2);
        end
            
        mesh1 = model2mesh(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
        mesh2 = model2mesh(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
        cellStruct1.algorithm = p.algorithm;
        cellStruct2.algorithm = p.algorithm;
        cellStruct1.birthframe = frame;
        cellStruct2.birthframe = prevStruct.birthframe;
        if size(pcCell1,2)==1, model=pcCell1'; else model=pcCell1; end
        cellStruct1.model = single(model);
        if size(pcCell2,2)==1, model=pcCell2'; else model=pcCell2; end
        cellStruct2.model = single(model);
        cellStruct1.polarity = 1;
        cellStruct2.polarity = 1;
        cellStruct1.mesh = single(mesh1);
        cellStruct2.boxModel = single(boxModel2);
        cellStruct2.mesh = single(mesh2);
        cellStruct1.stage = 1;
        cellStruct2.stage = 1;
        cellStruct1.timelapse = 1;
        cellStruct2.timelapse = 1;
        cellStruct1.divisions = []; % frame?
        cellStruct2.divisions = [prevStruct.divisions frame];
        cellStruct1.box = roiBox;
        cellStruct2.box = roiBox;
        daughter = getDaughterNum();%getdaughter(celln,length(cellStruct2.divisions),max(cellList.cellId{frame-1})+1);
        cellStruct1.ancestors = [prevStruct.ancestors celln];
        cellStruct2.ancestors = prevStruct.ancestors;
        cellStruct1.descendants = [];
        cellStruct2.descendants = [prevStruct.descendants daughter];
		cellList = oufti_addCell(celln, frame, cellStruct2, cellList);%mother cell keeps the number
        if (frame>1) && oufti_doesCellExist(celln, frame-1, cellList) 
            cellList = oufti_addFieldToCellList(celln, frame, 'timelapse', 1, cellList);
        end
        
		cellList = oufti_addCell(daughter, frame, cellStruct1, cellList);
        proccells = [proccells daughter];%#ok<AGROW>
        disp(['cell ', num2str(celln),' splitted, cell ', num2str(daughter), ' was born'])
        continue;
     end
        
     cellStruct.birthframe = prevStruct.birthframe;
     cellStruct.algorithm = p.algorithm;
     if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
     cellStruct.model = single(model);
     cellStruct.mesh = single(cellMesh);
     cellStruct.boxModel = boxModel;
     cellStruct.polarity = prevStruct.polarity;
     cellStruct.ancestors = prevStruct.ancestors;
     cellStruct.descendants = prevStruct.descendants;
     cellStruct.stage = 1;
     cellStruct.timelapse = 1;
     %cellStruct.stage = getStage(roiImg,cellStruc.model);
     cellStruct.divisions = prevStruct.divisions;
     cellStruct.box = roiBox;
     %%%if isMicroFluidic
        %%%cellList = oufti_addCell(celln, frame, cellStruct, cellList);
     %%%else
        %%%cellList.meshData{frame}{celln} = cellStruct;
     %%%end
     cellList = oufti_addCell(celln, frame, cellStruct, cellList);
     if (frame>1) && oufti_doesCellExist(celln, frame-1, cellList) 
         cellList = oufti_addFieldToCellList(celln, frame, 'timelapse', 1, cellList);
     end
     continue; 
    else
        cellStruct = prevStruct;
        if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
        cellStruct.model = single(model);
        cellStruct.mesh = single(0);
        cellStruct.stage = 0;

		cellList = oufti_addCell(celln, frame, cellStruct, cellList);

        % if the cell is not on the image border OR it did not pass the
        % quality test - split it
        reason = 'unknown';
        if isempty(pcCell) || isempty(cCell), reason = 'no cell found';
        elseif fitquality>=p.fitqualitymax, reason = 'bad fit quality';
        elseif min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary';
        elseif min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary';
        elseif min(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary';
        elseif min(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary';
        elseif isct, reason = 'model has intersections';
        elseif length(cellMesh)<=1 || cellarea==0, reason = 'problem getting mesh';
        elseif p.areaMin>=cellarea, reason = 'cell too small';
        elseif p.areaMax<=cellarea, reason = 'cell too big';
        end
        %gdisp(['fitting cell ' num2str(cell) ' - quality check failed - ' reason])
        disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
    end
    catch err
% %         disp(err.message);
        celln = proccells(i);
        prevStruct = oufti_getCellStructure(celln,frame-1,cellList);
        cellStruct = prevStruct;
        cellStruct.mesh = single(0);
        cellStruct.stage = 0;
		cellList = oufti_addCell(celln, frame, cellStruct, cellList);
        reason = 'problem getting mesh';
        disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
        continue;
    end
 
end


    

end





























% % % function proccells = processFrameGreaterThanOneTextMode(frame, proccells,~)
% % % 
% % % %--------------------------------------------------------------------------
% % % %--------------------------------------------------------------------------
% % % %function processFrameGreaterThanOne(frame,proccells,saveFile)
% % % %oufti.v0.1.5
% % % %@author:  Ahmad J Paintdakhi
% % % %@date:    May 23 2012
% % % %@modified: August 31 2012
% % % %@copyright 2012-2013 Yale University
% % % %==========================================================================
% % % % This function is for processing all frames except the first one
% % % % 
% % % % It is only looking for the cells that existed before and splits them if
% % % % necessary.
% % % %**********output********:
% % % %proccells -- cell array that are processed using parallel or serial
% % % %computation.
% % % %**********Input********:
% % % %frame -- frame # that is to be processed.
% % % %proccells -- array of cells that need to be processed.
% % % %saveFile -- name of the file where data is saved.  This input variable is
% % % %needed for naming the command window output message's file.
% % % %==========================================================================
% % % 
% % % global maskdx maskdy imsizes cellList cellListN rawPhaseData se p shiftframes
% % % global wCell mC1 mC2 wthres w_err w0_err 
% % % global toggle_err coefPCA mCell
% % % global wcc mlp slp mln sln coefS N weights dMax
% % % 
% % % %global CS_V CS_Kch CS_m
% % % isShiftFrame = 0;
% % % if ~isempty(shiftframes), isShiftFrame = 1; end
% % % 
% % % disp(['Processing frame ' num2str(frame)])
% % % cellListN = cellfun(@length,cellList.meshData);
% % % l_maskdx = maskdx;
% % % l_maskdy = maskdy;
% % % l_se = se;
% % % l_p = p;
% % % l_wCell = wCell;
% % % l_mC1 = mC1;
% % % l_mC2 = mC2;
% % % l_wthres = wthres;
% % % l_wcc = wcc;
% % % l_mlp = mlp;
% % % l_slp = slp;
% % % l_mln = mln;
% % % l_sln = sln;
% % % 
% % % % For the new processCell()
% % % l_args.wcc = l_wcc;
% % % l_args.mlp = l_mlp;
% % % l_args.slp = l_slp;
% % % l_args.mln = l_mln;
% % % l_args.sln = l_sln;
% % % l_args.se  = l_se;
% % % l_args.maskdx = l_maskdx;
% % % l_args.maskdy = l_maskdy;
% % % l_args.l_mC1 = l_mC1;
% % % l_args.l_mC2 = l_mC2;
% % % l_args.l_wCell = l_wCell;
% % % l_args.coefPCA = coefPCA;
% % % l_args.mCell   = mCell;
% % % l_args.coefS   = coefS;
% % % l_args.N       = N;
% % % l_args.weights = weights;
% % % l_args.dMax    = dMax;
% % % l_args.l_wthres = l_wthres;
% % % l_args.w_err=w_err;
% % % l_args.w0_err=w0_err;
% % % l_args.toggle_err=toggle_err;
% % % l_shiftframes = shiftframes;
% % % 
% % % if frame>size(rawPhaseData,3), return; end
% % % img = rawPhaseData(:,:,frame);
% % % imge = img2imge(img,p.erodeNum,se);
% % % imge16 = img2imge16(img,p.erodeNum,se);
% % % thres = graythreshreg(imge,p.threshminlevel);
% % % %bgr = phasebgr(imge,thres,se,p.bgrErodeNum);
% % % allMap = zeros(size(img));
% % % [~,cellIdPrevious] = oufti_getFrame(frame-1,cellList);
% % % for cell = cellIdPrevious
% % %     mesh = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(cell,frame-1,cellList)}.mesh;
% % %     if size(mesh,2)==4
% % %         allMap = allMap +... 
% % %         imerode(roipoly(allMap,[mesh(:,1);flipud(mesh(:,3))],[mesh(:,2);flipud(mesh(:,4))]),se);
% % %     end
% % % end
% % % allMap = min(allMap,1);
% % % [extDx,extDy] = getExtForces(imge,imge16,maskdx,maskdy,p);
% % % if isempty(extDx), disp('Processing timelapse frame failed: unable to get energy'); return; end
% % % [cellListPrevious ~] = oufti_getAllCellStructureInFrame(proccells, frame-1, cellList);
% % % cellTempParts = matlabWorkerProcessCells(cellListPrevious, ...
% % %                  proccells,l_p,l_args,img, imge,extDx, extDy, allMap, thres, frame,isShiftFrame,l_shiftframes);
% % % %--------------------------------------------------------------------------
% % % % Stitch together the output
% % % cellTemp = [];
% % % for i=1:length(cellTempParts)
% % %     
% % %     if iscell(cellTempParts{i})
% % %         if cellfun(@isempty,cellTempParts{i})
% % %            cellTemp{i} = cellTempParts{i};%#ok<AGROW>
% % %         else
% % %            cellTemp{i} = cellTempParts{i};%#ok<AGROW>
% % %         end
% % %     else
% % %         %------------------------------------------------------------------
% % %         %check if gathered cell parts from a thread or empty or not.  If
% % %         %they are empty then allocate empty spaces for all the empty cells.
% % %         %This change makes certain that due to empty cellTempParts cells
% % %         %matrix allocation or deletion error is not encountered.  Ahmad.P
% % %         %October 3, 2012.
% % %         if isempty(cellTempParts{i})
% % %            cellTempParts{i} = {[]};
% % %            cellTemp{i} = cellTempParts{i};%#ok<AGROW>
% % %         else
% % %             cellTemp{i} = cellTempParts{i};%#ok<AGROW>
% % %         end
% % %         %------------------------------------------------------------------
% % %     end
% % % end
% % % %--------------------------------------------------------------------------
% % % try
% % % for i = 1:length(proccells)
% % %     if isempty(cellTemp{i}),continue;end
% % %     celln = proccells(i);
% % %     prevStruct = oufti_getCellStructure(celln,frame-1,cellList);
% % %     res          = cellTemp{i}.res;
% % %     mesh         = double(cellTemp{i}.mesh);
% % %     pcCell       = single(cellTemp{i}.pcCell);
% % %     cCell        = single(cellTemp{i}.cCell);
% % %     isct         = cellTemp{i}.isct;
% % %     fitquality   = cellTemp{i}.fitquality;
% % %     roiBox       = cellTemp{i}.roiBox;
% % %     boxModel     = cellTemp{i}.boxModel;
% % %     roiImg       = single(cellTemp{i}.roiImg);
% % %     roiExtDx     = single(cellTemp{i}.roiExtDx);
% % %     roiExtDy     = single(cellTemp{i}.roiExtDy);
% % %     roiAmap      = single(cellTemp{i}.roiAmap);
% % %     cellarea     = cellTemp{i}.cellarea;
% % % 
% % %     % checking quality and storing the cell
% % %     if ~isempty(cCell) && ~isempty(isct) && ~isct && fitquality<p.fitqualitymax && ...
% % %                min(min(cCell))>1+p.noCellBorder && max(cCell(:,1))<imsizes(1,2)-p.noCellBorder...
% % %               && max(cCell(:,2))<imsizes(1,1)-p.noCellBorder &&...
% % %               length(mesh)>1 && p.areaMin<cellarea && p.areaMax>cellarea
% % % 
% % %         % if the cell passed the quality test and it is not on the
% % %         % boundary of the image - store it
% % %      if res>0 % Splitting the cell
% % %         % mesh1 = flipud(mesh(1:res-1,:)); % daughter cell
% % %         % mesh2 = mesh(res+1:end,:);
% % %         % select the cells so that the mesh always goes from the stalk pole
% % %         mesh1 = flipud(mesh(res+1:end,:)); % daughter cell
% % %         mesh2 = mesh(1:res-1,:); % mother cell
% % %        
% % %         pcCell1 = align4IM(mesh1,p);
% % %         pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
% % %         pcCell1 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,p,roiBox,...
% % %                          thres,[frame celln]);
% % %         pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
% % %         cCell1 = double(pcCell1);
% % %         pcCell2 = align4IM(mesh2,p);
% % %         pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
% % %         pcCell2 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,p,roiBox,...
% % %                             thres,[frame celln]);
% % %         boxModel2 = pcCell2;
% % %         pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
% % %         cCell2 = double(pcCell2);   
% % %         mesh1 = model2mesh(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
% % %         mesh2 = model2mesh(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
% % %         cellStruct1.algorithm = p.algorithm;
% % %         cellStruct2.algorithm = p.algorithm;
% % %         cellStruct1.birthframe = frame;
% % %         cellStruct2.birthframe = prevStruct.birthframe;
% % %         if size(pcCell1,2)==1, model=pcCell1'; else model=pcCell1; end
% % %         cellStruct1.model = single(model);
% % %         if size(pcCell2,2)==1, model=pcCell2'; else model=pcCell2; end
% % %         cellStruct2.model = single(model);
% % %         cellStruct1.polarity = 1;
% % %         cellStruct2.polarity = 1;
% % %         cellStruct1.mesh = single(mesh1);
% % %         cellStruct2.boxModel = single(boxModel2);
% % %         cellStruct2.mesh = single(mesh2);
% % %         cellStruct1.stage = 1;
% % %         cellStruct2.stage = 1;
% % %         cellStruct1.timelapse = 1;
% % %         cellStruct2.timelapse = 1;
% % %         cellStruct1.divisions = []; % frame?
% % %         cellStruct2.divisions = [prevStruct.divisions frame];
% % %         cellStruct1.box = roiBox;
% % %         cellStruct2.box = roiBox;
% % %         daughter = getdaughter(celln,length(cellStruct2.divisions),max(cellList.cellId{frame-1})+500);
% % %         cellStruct1.ancestors = [prevStruct.ancestors celln];
% % %         cellStruct2.ancestors = prevStruct.ancestors;
% % %         cellStruct1.descendants = [];
% % %         cellStruct2.descendants = [prevStruct.descendants daughter];
% % % 		cellList = oufti_addCell(celln, frame, cellStruct2, cellList);%mother cell keeps the number
% % %         if (frame>1) && oufti_doesCellExist(celln, frame-1, cellList) 
% % %             cellList = oufti_addFieldToCellList(celln, frame, 'timelapse', 1, cellList);
% % %         end
% % % 		cellList = oufti_addCell(daughter, frame, cellStruct1, cellList);
% % %         proccells = [proccells daughter];%#ok<AGROW>
% % %         disp(['cell ', num2str(celln),' splitted, cell ', num2str(daughter), ' was born'])
% % %         continue;
% % %      end
% % %         
% % %      cellStruct.birthframe = prevStruct.birthframe;
% % %      cellStruct.algorithm = p.algorithm;
% % %      if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
% % %      cellStruct.model = single(model);
% % %      cellStruct.mesh = single(mesh);
% % %      cellStruct.boxModel = boxModel;
% % %      cellStruct.polarity = prevStruct.polarity;
% % %      cellStruct.ancestors = prevStruct.ancestors;
% % %      cellStruct.descendants = prevStruct.descendants;
% % %      cellStruct.stage = 1;
% % %      cellStruct.timelapse = 1;
% % %      %cellStruct.stage = getStage(roiImg,cellStruc.model);
% % %      cellStruct.divisions = prevStruct.divisions;
% % %      cellStruct.box = roiBox;
% % %      cellList = oufti_addCell(celln, frame, cellStruct, cellList);
% % %      if (frame>1) && oufti_doesCellExist(celln, frame-1, cellList) 
% % %          cellList = oufti_addFieldToCellList(celln, frame, 'timelapse', 1, cellList);
% % %      end
% % %      continue; 
% % %     else
% % %         cellStruct = prevStruct;
% % %         if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
% % %         cellStruct.model = single(model);
% % %         cellStruct.mesh = single(0);
% % %         cellStruct.stage = 0;
% % % 		cellList = oufti_addCell(celln, frame, cellStruct, cellList);
% % %         % if the cell is not on the image border OR it did not pass the
% % %         % quality test - split it
% % %         reason = 'unknown';
% % %         if isempty(pcCell) || isempty(cCell), reason = 'no cell found';
% % %         elseif fitquality>=p.fitqualitymax, reason = 'bad fit quality';
% % %         elseif min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary';
% % %         elseif min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary';
% % %         elseif min(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary';
% % %         elseif min(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary';
% % %         elseif isct, reason = 'model has intersections';
% % %         elseif length(mesh)<=1 || cellarea==0, reason = 'problem getting mesh';
% % %         elseif p.areaMin>=cellarea, reason = 'cell too small';
% % %         elseif p.areaMax<=cellarea, reason = 'cell too big';
% % %         end
% % %         disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
% % %     end
% % %  
% % % end
% % % catch
% % %         cellStruct = prevStruct;
% % %         if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
% % %         cellStruct.model = single(model);
% % %         cellStruct.mesh = single(0);
% % %         cellStruct.stage = 0;
% % % 		cellList = oufti_addCell(celln, frame, cellStruct, cellList);
% % %         % if the cell is not on the image border OR it did not pass the
% % %         % quality test - split it
% % %         reason = 'unknown';
% % %         if isempty(pcCell) || isempty(cCell), reason = 'no cell found';
% % %         elseif fitquality>=p.fitqualitymax, reason = 'bad fit quality';
% % %         elseif min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary';
% % %         elseif min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary';
% % %         elseif min(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary';
% % %         elseif min(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary';
% % %         elseif isct, reason = 'model has intersections';
% % %         elseif length(mesh)<=1 || cellarea==0, reason = 'problem getting mesh';
% % %         elseif p.areaMin>=cellarea, reason = 'cell too small';
% % %         elseif p.areaMax<=cellarea, reason = 'cell too big';
% % %         end
% % %         disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
% % % end
% % % end
% % % 
% % % 
% % % 
% % % 
% % % 
