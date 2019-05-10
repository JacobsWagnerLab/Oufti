
function  processCellsForFitting(frame,proccells,imge,thres,extDx,extDy,allMap,tl)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function  processCellsForFitting(frame, proccells)
%oufti 
%@author:  Ahmad J Paintdakhi
%@date:    January 23, 2014
%@copyright 2012-2014 Yale University
%==========================================================================
% This functions uses sub-pixel fitting algorithm in align4 function to 
% refine cells.
% 
%**********output********:
%
%**********Input********:
%frame -- frame # that is to be processed.
%proccells -- array of cells that need to be processed.
%==========================================================================

global maskdx maskdy imsizes cellList cellListN rawPhaseData se p shiftframes
global wCell mC1 mC2 wthres w_err w0_err 
global coefPCA mCell
global wcc mlp slp mln sln coefS N weights dMax
global maxWorkers
%global CS_V CS_Kch CS_m
%-------------------------------------------------------------------------
%pragma function needed to include files for deployment
%#function [interp2_ B Bf M align4 truncateFile.pl box2model circShiftNew]
%#function [frdescp getnormals getrigidityforces getrigidityforcesL ifdescp interp2a]
%#function [intersections intxy2 intxy2C intxyMulti intxyMultiC intxySelfC]
%#function [isContourClockwise isDivided makeccw model2box model2geom model2mesh]
%#function [setdispfiguretitle spsmooth createdispfigure projectCurve alignParallel matlabWorkerProcessCells]
%#function [phaseBackground processIndividualCells repmat_ interp2_]
%-------------------------------------------------------------------------
reason = 'unknown';
isShiftFrame = 0;
t = [];
fileDependicies = {     'processCellsForFitting'
                        'B'
                        'Bf'
                        'oufti_addCell'
                        'oufti_cellId2PositionInFrame'
                        'oufti_getCellStructure'
                        'oufti_getLengthOfCellList'
                        'oufti_isFrameEmpty'
                        'oufti_doesFrameExist'
                        'oufti_isFrameNonEmpty'
                        'oufti_removeCellStructureFromCellList'
                        'M'
                        'align'
                        'align4'
                        'align4I'
                        'align4IM'
                        'alignParallel'
                        'box2model'
                        'circShiftNew'
                        'createdispfigure'
                        'frdescp'
                        'gdisp'
                        'getDaughterNum'
                        'getRigidityForcesL_'
                        'getRigidityForces_'
                        'getnormals'
                        'getrigidityforces'
                        'getrigidityforcesL'
                        'ifdescp'
                        'interp2_'
                        'interp2a'
                        'intersections'
                        'intxy2'
                        'intxy2C'
                        'intxyMulti'
                        'intxyMultiC'
                        'intxySelfC'
                        'isContourClockwise'
                        'isDivided'
                        'makeccw'
                        'matlabWorkerProcessCells'
                        'model2box'
                        'model2geom'
                        'model2mesh'
                        'phaseBackground'
                        'processIndividualCells'
                        'projectCurve'
                        'repmat_'
                        'setdispfiguretitle'
                        'splitted2model'
                        'spsmooth'};
if ~isempty(shiftframes), isShiftFrame = 1; end
disp(['Fitting cells in frame ' num2str(frame)])
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

l_shiftframes = shiftframes;
if p.invertimage
    if frame>size(rawPhaseData,3), return; end 
    img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
else
    if frame>size(rawPhaseData,3), return; end
    img = rawPhaseData(:,:,frame);
end

%allMap = zeros(size(img));

if isempty(extDx), disp('Processing timelapse frame failed: unable to get energy'); return; end

% % % for celln = proccells
% % %     allMap = allMap+imerode(poly2mask(cellList.meshData{frame}{oufti_cellId2PositionInFrame(celln,frame,cellList)}.model(:,1),...
% % %              cellList.meshData{frame}{oufti_cellId2PositionInFrame(celln,frame,cellList)}.model(:,2),size(allMap,1),size(allMap,2)),se); 
% % % end

allMap = min(allMap,1);
nr_cells = length(proccells);
if isempty(length(proccells)) || proccells(1) == 0,disp('No cells to process'); return; end
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
    newJob = createJob(sched);
    nTasks = sched.ClusterSize;
else
    sched = parcluster(parallel.defaultClusterProfile); 
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
                cellTempParts = {matlabWorkerProcessCells(cellList.meshData{frame}(wCells(i):wFinalCell), ...
                                proccells(wCells(i):wFinalCell),l_p,...
                                l_args,img, imge,extDx, extDy, allMap, thres, frame,isShiftFrame,l_shiftframes,true)};
               else
                  if l_p.fitDisplay == 1, warndlg('set "fitDisplay" parameter value to 0');return;end
                  tempCellData = cellList.meshData{frame}(wCells(i):wFinalCell);
                  t = createTask(newJob,@matlabWorkerProcessCells,1,{tempCellData...
                                 proccells(wCells(i):wFinalCell) l_p l_args img ...
                                 imge extDx extDy allMap thres frame isShiftFrame ...
                                 l_shiftframes true});
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
                
                submit(newJob);
                disp('Awaiting results')
                waitForState(newJob, 'finished');
                
            else
                %set(newJob, 'AttachedFiles', fileDependicies);
                %set(newJob, 'AutoAttachFiles', true);
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
            eval('t')
        end

%catches an error sometimes caused due to matlab's issue with scheduling a
%task correctly and throws a false positive error called 
%"identifier: 'distcomp:localscheduler:InvalidState'" .
catch err
    
    disp(err);
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
if str2double(matlabVersion(1)) < 8
    destroy(newJob);
else
    delete(newJob);
end
%--------------------------------------------------------------------------

%--------------------------------------------------------------------------
indexToDeleteInMeshData = [];
indexToDeleteInCellId   = [];
for i = 1:length(proccells)
    celln = proccells(i);
    try
    if isempty(cellTemp{i}) || ~isfield(cellTemp{i},'mesh')
		cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)} = cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)};
        cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)}.mesh = model2MeshForRefine(cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)}.model,p.meshStep,p.meshTolerance,p.meshWidth);
        if length(cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)}.mesh) < 4
           indexToDeleteInCellId   = [indexToDeleteInCellId proccells(i)]; %#ok<AGROW>
           indexToDeleteInMeshData = [indexToDeleteInMeshData oufti_cellId2PositionInFrame(proccells(i),frame,cellList)]; %#ok<AGROW>
        end
        continue;
    end
  
    currentStruct = cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)};
    res          = cellTemp{i}.res;
    cellModel     = double(cellTemp{i}.mesh);
    pcCell       = single(cellTemp{i}.pcCell);
    cCell        = single(cellTemp{i}.cCell);
    isct         = cellTemp{i}.isct;
    fitquality   = cellTemp{i}.fitquality;
    roiBox       = cellTemp{i}.roiBox;
    roiImg       = single(cellTemp{i}.roiImg);
    %roiExtEnergy = single(cellTemp{i}.roiExtEnergy);+
    roiExtDx     = single(cellTemp{i}.roiExtDx);
    roiExtDy     = single(cellTemp{i}.roiExtDy);
    roiAmap      = single(cellTemp{i}.roiAmap);
    %lambda_div   = cellTemp{i}.lambda_div;
    %errvec       = cellTemp{i}.errvec;
    %errwarn      = cellTemp{i}.errwarn;
    if ~isempty(cCell),cellarea = polyarea(cCell(:,1),cCell(:,2)); else cellarea = 0;end

    % checking quality and storing the cell
    if ~isempty(cCell) && ~isempty(isct) && ~isct && fitquality<p.fitqualitymax && ...
               min(min(cCell))>1+p.noCellBorder && max(cCell(:,1))<imsizes(1,2)-p.noCellBorder...
              && max(cCell(:,2))<imsizes(1,1)-p.noCellBorder &&...
              length(cellModel)>1 && p.areaMin<cellarea && p.areaMax>cellarea

        % if the cell passed the quality test and it is not on the
        % boundary of the image - store it
     if res>0 % Splitting the cell
        % mesh1 = flipud(mesh(1:res-1,:)); % daughter cell
        % mesh2 = mesh(res+1:end,:);
        % select the cells so that the mesh always goes from the stalk pole
        mesh1 = flipud(cellModel(res+1:end,:)); % daughter cell
        mesh2 = cellModel(1:res-1,:); % mother cell
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
           pcCell1 = align4Manual(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,p,roiBox,...
                            thres,[frame celln]);
% %            pcCell1 = alignActiveContour(roiImg,pcCell1,0.00035,0.035,...
% %                                              0.25,0.35,0.05,15,3,500,2,roiExtDx,roiExtDy,roiBox);
           pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
           cCell1 = double(pcCell1);
           pcCell2 = align4IM(mesh2,p);
           pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
           pcCell2 = align4Manual(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,p,roiBox,...
                            thres,[frame celln]);
% %            pcCell2 = alignActiveContour(roiImg,pcCell2,0.00035,0.035,...
% %                                              0.25,0.35,0.05,15,3,500,2,roiExtDx,roiExtDy,roiBox);
           pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
           cCell2 = double(pcCell2);
        end
        %----------------------------------------------------------------
        %mother cell is dropped in this frame and the two daughter cells
        %are created.  Modified Nov. 12, 2013, Ahmad Paintdakhi
        %cellStruct1 ===> daughter 1
        %cellStruct2 ===> daughter 2
        %----------------------------------------------------------------
        mesh1 = model2MeshForRefine(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
        mesh2 = model2MeshForRefine(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
        cellStruct1.algorithm = p.algorithm;
        cellStruct2.algorithm = p.algorithm;
        cellStruct1.birthframe = frame;
        %cellStruct2.birthframe = prevStruct.birthframe;
        cellStruct2.birthframe = frame;
        if size(pcCell1,2)==1, model=pcCell1'; else model=pcCell1; end
        cellStruct1.model = single(model);
        if size(pcCell2,2)==1, model=pcCell2'; else model=pcCell2; end
        cellStruct2.model = single(model);
        cellStruct1.polarity = 1;
        cellStruct2.polarity = currentStruct.polarity + 1;
        cellStruct1.mesh = single(mesh1);
        cellStruct2.mesh = single(mesh2);
        cellStruct1.stage = 1;
        cellStruct2.stage = 1;
        cellStruct1.timelapse = tl;
        cellStruct2.timelapse = tl;
        cellStruct1.divisions = []; % frame?
        cellStruct2.divisions = [];
        daughter = getDaughterNum();%getdaughter(celln,length(cellStruct2.divisions),max(cellList.cellId{frame-1})+1);
        cellList.meshData{frame}{oufti_cellId2PositionInFrame(celln,frame,cellList)}.divisions =  frame;
        cellList.meshData{frame}{oufti_cellId2PositionInFrame(celln,frame,cellList)}.descendants = [daughter daughter+1];
        cellStruct1.box = roiBox;
        cellStruct2.box = roiBox;
        try
            cellStruct1.ancestors = [currentStruct.ancestors celln];
            cellStruct2.ancestors = [currentStruct.ancestors celln];
        catch
            cellStruct1.ancestors = [currentStruct.ancestors' celln];
            cellStruct2.ancestors = [currentStruct.ancestors' celln];
        end
        
        cellStruct1.descendants = [];
        cellStruct2.descendants = [];
       
		cellList = oufti_addCell(daughter+1, frame, cellStruct2, cellList); %daughter 2
		cellList = oufti_addCell(daughter, frame, cellStruct1, cellList);   %daughter 1
        %remove the mother cell from current cell since new approach of
        %cell division is in effect, where two cells are labelled as two
        %daughter cells.
        cellList = oufti_removeCellStructureFromCellList(celln,frame,cellList);
        
        disp(['cell ', num2str(celln),' splitted, cells ', num2str(daughter) ' and ' num2str(daughter+1), ' are born'])
        continue;
     end
        
     cellStruct.birthframe = currentStruct.birthframe;
     cellStruct.algorithm = p.algorithm;
     if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
     cellStruct.model = single(model);
     cellStruct.mesh = single(cellModel);
     cellStruct.polarity = currentStruct.polarity;
     cellStruct.ancestors = currentStruct.ancestors;
     cellStruct.descendants = currentStruct.descendants;
     cellStruct.stage = 1;
     cellStruct.timelapse = tl;
     cellStruct.divisions = currentStruct.divisions;
     cellStruct.box = roiBox;
     
    cellList.meshData{frame}{oufti_cellId2PositionInFrame(proccells(i),frame,cellList)} = cellStruct;
    
     continue; 
    else

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
        elseif length(cellModel)<=1 || cellarea==0, reason = 'problem getting mesh';
        elseif p.areaMin>=cellarea, reason = 'cell too small';
        elseif p.areaMax<=cellarea, reason = 'cell too big';
        end
        disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
        indexToDeleteInCellId   = [indexToDeleteInCellId proccells(i)]; %#ok<AGROW>
        indexToDeleteInMeshData = [indexToDeleteInMeshData oufti_cellId2PositionInFrame(proccells(i),frame,cellList)];%#ok<AGROW>
    end
    catch err
        disp(['fitting cell ' num2str(celln) ' - quality check failed - ' reason])
        indexToDeleteInCellId   = [indexToDeleteInCellId proccells(i)]; %#ok<AGROW>
        indexToDeleteInMeshData = [indexToDeleteInMeshData oufti_cellId2PositionInFrame(proccells(i),frame,cellList)];%#ok<AGROW>
    end
end

cellList.meshData{frame}(indexToDeleteInMeshData) = [];
cellList.cellId{frame}(indexToDeleteInCellId) = [];

end





