function processIndependentFrames(frameList,tl,processRegion,saveFile)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function processIndependentFrames(frameList,tl,processRegion,saveFile)
%oufti.v0.0.5
%@author:  Ahmad J Paintdakhi
%@date:    May 23 2012
%@modified: February 1 2013
%@copyright 2012-2013 Yale University
%
%==========================================================================
%**********output********:
%no output, although it does updates cellList at the end of the routine,
%which is used by the rest of the program.
%
%**********Input********:
%frameList -- list of frames e.g. [1 10]
%t1 -- input needed for subfunctions below.
%processRegion -- process cells only detected in the processRegion vector
%saveFile -- name of the file where data is saved.  This input variable is
%needed for naming the command window output message's file.
%==========================================================================
%
%--------------------------------------------------------------------------
%All these parameters are declared global as they are either needed in
%other functions or their values are modified here in this routine to be
%used by other friendly routines.
global imsizes maskdx maskdy cellList rawPhaseData se p imageForce 
global coefPCA coefS N weights dMax mCell regionSelectionRect flevel
%--------------------------------------------------------------------------


 %-------------------------------------------------------------------------
 %pragma function needed to include files for deployment
 %#function [interp2_ B Bf M align4 truncateFile.pl box2model circShiftNew alignParallel]
 %#function [frdescp getnormals getrigidityforces getrigidityforcesL ifdescp interp2a logvalley]
 %#function [intersections intxy2 intxy2C intxyMulti intxyMultiC intxySelfC gdisp graythreshregParallel]
 %#function [isContourClockwise isDivided makeccw model2box model2geom model2mesh edgeforce]
 %#function [setdispfiguretitle spsmooth createdispfigure projectCurve alignParallel matlabWorkerProcessCells]
 %#function [phaseBackground processIndividualCells align4I align4IM getExtForces splitonereg splitted2model]
 %#function [matlabWorkerProcessIndependentFrames processIndividualIndependentFrames getRegions]
 %#function [graythreshreg img2imge img2imge16 mmax mmin phasebgr quantile2]
 %-------------------------------------------------------------------------
imageForce_   = imageForce;
p.stopButton = 0;
if imsizes(1,1) < 1600 || imsizes(1,2) < 1600 || p.algorithm == 1
 
    fileDependicies = {     
      'interp2_'
      'getRigidityForces_'
      'getRigidityForcesL_'
      'oufti_addCell.m'
      'oufti_getCellStructure.m'
      'B.m'
      'Bf.m'
      'M.m'
      'nanmean.m'
      'align.m'
      'align4.m'
      'align4I.m'
      'align4IM.m'
      'box2model.m'
      'circShiftNew.m'
      'frdescp.m'
      'getExtForces.m'
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
      'splitonereg.m'
      'splitted2model.m'
      'spsmooth.m'
      'createdispfigure.m'
      'edgeforce.m'
      'gdisp.m'
      'logvalley.m'
      'projectCurve.m'
      'alignParallel.m'
      'graythreshregParallel.m'
      'matlabWorkerProcessIndependentFrames.m'
      'processIndividualIndependentFrames.m'
      'getRegions.m'
      'graythreshreg.m'
      'img2imge.m'
      'img2imge16.m'
      'mmax.m'
      'mmin.m'
      'phasebgr.m'
      'quantile2.m'};
    %--------------------------------------------------------------------------
    %Global variables are converted to either local variables or data
    %structures for the parallel process to function correctly.  Remember no
    %global variables can be utilized inside parallel functions.
    l_maskdx = maskdx;
    l_maskdy = maskdy;
    l_imsizes= imsizes;
    l_se     = se;
    l_p      = p;
    l_rawPhaseData = rawPhaseData;
    l_args.maskdx = l_maskdx;
    l_args.maskdy = l_maskdy;
    l_args.imsizes= l_imsizes;
    l_args.se     = l_se;
    l_args.p      = l_p;
    l_args.coefPCA = coefPCA;
    l_args.coefS   = coefS;
    l_args.N       = N;
    l_args.weights = weights;
    l_args.dMax    = dMax;
    l_args.mCell   = mCell;
    l_args.tl      = tl;
    l_args.regionSelectionRect = regionSelectionRect;
    l_args.flevel = flevel;
    
    %--------------------------------------------------------------------------
    tic; %set clock here
    try
    numFrames = length(frameList);
    %--------------------------------------------------------------------------  
    %parallel job is created here, the number of tasks -- to be supplied to
    %each core in the host machine -- is created using the number of threads
    %(cores) in a host machine.  The default maxWorkder number is 6 or
    %otherwise declared by the user inside "p" structure.  For example, if the
    %number of cores inside a host machine is 4 and the maxWorkers number is 6
    %then the number of tasks would be 4 since that is the minimum in a vector
    %[4 6].
    %finds matlab version and assigns multi-threading variables
    %accordingly.  Matlab programming language has changed initialization
    %routines of parallel computation from version 7 onwards.... Weird!!!!
    matlabVersion = version;
    if str2double(matlabVersion(1)) < 8 
        sched = parcluster('scheduler','type','local');
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
    maxWorkers = p.maxWorkers;
    numTasks = min(numTasks, maxWorkers);
    numTasks = min(numTasks, numFrames);
    %--------------------------------------------------------------------------

    %-------------------------------------------------------------
    %if number of frames is less than or equal to 4 don't bother
    %processing frames in parallel loop.
    if numFrames <= 3, numTasks = 1;end
    %-------------------------------------------------------------

    %--------------------------------------------------------------------------
    % One job with a suitable number of tasks is faster than many jobs and
    % easier to manage.  
    %This is where function matlabWorkerProcessIndependentFrames is called to
    %streamline the parallel process for all the frames selected.  If the
    %number of tasks or threads is declared 4 in the above statements while the
    %number of frames chosen for processing is 20, then each task or thread
    %will process 5 frames in parallel.  For debugging purposes the
    %variable "numTasks" can be uncommented.

    %numTasks = 1;
    if ~isempty(processRegion), numTasks = 1; end;
    cellStructure = oufti_allocateCellList(cellList,frameList);
    tmpNumFrames = 1:numTasks:numFrames;
    frameTemp = oufti_allocateCellList(cellStructure,frameList);
    frameTemp.meshData(frameList) = {[]}; frameTemp.cellId(frameList) = {[]};
    for ii = 1:length(tmpNumFrames)
        if str2double(matlabVersion(1)) < 8 
            newJob = createJob(sched);
        else
            newJob = createJob(sched);
            set(newJob,'AutoAttachFiles', false);
            set(newJob,'AttachedFiles',fileDependicies);
        end
        for i = 1:numTasks
            if numFrames >=  (tmpNumFrames(ii)-1+i)
                if numTasks == 1
                    disp(['Making task for 1 frame: ' num2str(frameList(tmpNumFrames(ii))) '-' ...
                    num2str(frameList(tmpNumFrames(ii)))]);
                % For debugging
                    frameTempParts={matlabWorkerProcessIndependentFrames(l_rawPhaseData...
                    (:,:,frameList(tmpNumFrames(ii)):frameList(tmpNumFrames(ii))),...
                    frameList(tmpNumFrames(ii):tmpNumFrames(ii)),l_p, l_args, processRegion, cellStructure,imageForce_)};
                else
                    disp(['Making task for 1 frame: ' num2str(frameList(tmpNumFrames(ii)-1+i)) '-' ...
                    num2str(frameList(tmpNumFrames(ii)-1+i))]);
                    t = createTask(newJob, @matlabWorkerProcessIndependentFrames, 1,{...
                        l_rawPhaseData(:,:,frameList(tmpNumFrames(ii)-1+i):frameList(tmpNumFrames(ii)-1+i))...
                        frameList(tmpNumFrames(ii)-1+i:tmpNumFrames(ii)-1+i) l_p l_args processRegion cellStructure imageForce_((tmpNumFrames(ii)-1+i:tmpNumFrames(ii)-1+i))});
                end
            end
        end

    %--------------------------------------------------------------------------


    %--------------------------------------------------------------------------
    %if the number of tasks or threads chosen above is greater than 1, the
    %number of tasks are submitted to each thread for processing.  Variable
    %newJob is the vector containing number of tasks.
    if numTasks > 1 
        disp('Submitting job')
        alltasks = get(newJob, 'Tasks');
        if str2double(matlabVersion(1)) < 8
            set(alltasks, 'CaptureCommandWindowOutput', true);
            submit(newJob);
            disp('Awaiting results')
            waitForState(newJob, 'finished');
            alltasks
            outputMessages = get(alltasks, 'CommandWindowOutput');
        else
            set(alltasks, 'CaptureDiary', true);
            %set(newJob, 'AttachedFiles', fileDependicies);
            %set(newJob, 'AutoAttachFiles', false);
            submit(newJob);
            disp('Awaiting results');
            wait(newJob,'finished',1500);
            outputMessages = get(alltasks, 'Diary');
            alltasks
        end

    %try-catch statement is used to avoid error while creating command window
    %output file.  If the "window messages" file is created without errors all
    %the command window messaged are gathered in variable "outputMessages" are
    %printed in the chosen file.  The name of the file is the same as the name
    %of the output file but with a modified extension of ".dat".  The ".dat"
    %file can be openend in wordpad for better viewing.
    try
       fileName = saveFile(length(fileparts(saveFile))+2:end-4);
       fid = fopen([saveFile(1:end-4) '.dat'],'a');
       errName = ferror(fid);
       disp(['messages saved to ' fileName ' in directory ' ...
              saveFile(1:end-(length(fileName)+4))])
       if iscell(outputMessages)
            for kk = 1:length(outputMessages)
                fprintf(fid,['\n','---------------  Frame ' num2str(frameList(tmpNumFrames(ii)-1+kk))...
                        ' --------------------']);
                fprintf(fid,['\n','%']);
                fwrite(fid,outputMessages{kk});  
            end
       else
           fprintf(fid,['\n','---------------  Frame ' num2str(frameList(tmpNumFrames(ii)))...
                        ' --------------------']);
           fprintf(fid,['\n','%']);
           fwrite(fid,outputMessages); 
       end
    catch err
          disp([err 'problem while attempt to open ' saveFile ...
                    '-->' errName])
          disp(outputMessages{kk})   
    end

      if ~isempty(t.Error),errorMessage = get(t,'ErrorMessage');...
         disp(['Error:  ' errorMessage]),end

    %all the outputs from different tasks are created and stored inside
    %variable frameTempParts.
    if str2double(matlabVersion(1)) < 8
        frameTempParts = newJob.getAllOutputArguments;
    else
        frameTempParts = newJob.fetchOutputs;

    end
    if fid ~= -1,fclose(fid);end
    end

    %--------------------------------------------------------------------------


    %--------------------------------------------------------------------------
    % Stitch together the output to be stored in a cell structure called
    % frameTemp.

    for jj=1:length(frameTempParts)

        if isempty(frameTempParts{jj})
            frameTemp.meshData(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj)) = {[]};
            frameTemp.cellId(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj))   = {[]};
        elseif length(frameList) == 1
            frameTemp.meshData(frameList) = frameTempParts{jj}.meshData;
            frameTemp.cellId(frameList)   = frameTempParts{jj}.cellId;
            imageForce_(frameList)        = frameTempParts{jj}.imageForce;
        else
        frameTemp.meshData(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj)) = frameTempParts{jj}.meshData;
        frameTemp.cellId(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj))   = frameTempParts{jj}.cellId;
        imageForce_(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj))        = frameTempParts{jj}.imageForce;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%this routine will make sure output data is not cluttered when dataset
            %is large, otherwise keeping the imageForce active helps in the speed
            %of the program.
             if numFrames > 20
                try
                    imageForce_(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj)).forceX = [];
                    imageForce_(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj)).forceY = [];
                catch
                end
             end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        end
    end
    destroy(newJob);% all the tasks are destroyed here to free up memory and
                    % system resources.
    try
    cellList.meshData(frameList) = frameTemp.meshData(frameList);
    cellList.cellId(frameList)   = frameTemp.cellId(frameList);
    catch err
          disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)]);
          disp(err.message);
    end
    if p.stopButton == 1 || p.pauseButton == 1
        if p.stopButton == 1
            error('all tasks aborted and data being saved')
        else
            f = figure('OuterPosition',[600,700,300,100],'MenuBar','none','Name','','NumberTitle','off',...
                       'DockControls','off');
            h = uicontrol('Position',[40 10 200 40],'String','Continue',...
                  'Callback','uiresume(gcbf)');
            uiwait(gcf);
            close(f);
        end
    end
    end

    catch err
        disp(err.message);
        disp(err.stack(1));
        disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        disp('all tasks aborted and data being saved');
        disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
        if length(frameTemp.meshData) > 1
            nonEmptyFramesMeshData   = ~cellfun(@isempty,frameTemp.meshData);
            nonEmptyFramesCellId = ~cellfun(@isempty,frameTemp.cellId);
            cellList.meshData(frameList(nonEmptyFramesMeshData)) = frameTemp.meshData(nonEmptyFramesMeshData);
            cellList.cellId(frameList(nonEmptyFramesCellId))     = frameTemp.cellId(nonEmptyFramesCellId);
        end
        savemesh(saveFile,[],[],[]);
    end
    %--------------------------------------------------------------------------

if l_p.algorithm ~= 1

    %==========================================================================
    %==========================================================================
    %---------JoinCells that are too close to each other-----------------------
    %The process is very similar to the above mentioned parallel routine,
    %however a different parallel function --matlabWorkerJoinCellsParallel is
    %called here which called "joinCellsParallel" function for the chose
    %threads.

    if str2double(matlabVersion(1)) < 8 
        sched = parcluster('scheduler','type','local');
        numTasks = sched.ClusterSize;
        newJob = createJob(sched);
    else
        sched = parcluster();
        numTasks = sched.NumWorkers;
        newJob = createJob(sched);
        set(newJob,'AutoAttachFiles', false);
        set(newJob,'AttachedFiles',fileDependicies);
    end
    maxWorkers = p.maxWorkers;
    numTasks = min(numTasks, maxWorkers);
    numTasks = min(numTasks, numFrames);

    %-------------------------------------------------------------
    %if number of frames is less than or equal to 4 don't bother
    %processing frames in parallel loop.
    if numFrames <= 7, numTasks = 1;end
    %-------------------------------------------------------------

    % Divide the compact frame list and send them to the workers.
    wFrames = 1;
    % remaining = numFrames - ceil(numFrames/numTasks);
    %         
    % for i = 2:numTasks
    %     chunk = ceil(remaining / (numTasks-i+1));
    %     wFrames(i) = wFrames(i-1)+chunk; %#ok<AGROW>
    %     remaining = remaining - chunk;
    % end

    processIncrement = ceil(numFrames/numTasks);
    lastIncrement = numFrames - ((numTasks-1)*processIncrement);
    if lastIncrement <= 0, numTasks = numTasks -1;end
    for i = 2:numTasks
        wFrames(i) = wFrames(i-1)+processIncrement;%#ok<AGROW>
        if wFrames(i) >= numFrames, numTasks = i; break; end
    end
    if lastIncrement <=0, wFrames(end) = numFrames;end        
    % One job with a suitable number of tasks is faster than many jobs and
    % easier to manage.

    for i = 1:numTasks
        if i<numTasks
           wFinalFrame = wFrames(i+1)-1;
        else
           wFinalFrame = numFrames;
        end

    disp(['Making cell attachment --"join" tasks for ' ...
           num2str(wFinalFrame-wFrames(i)+1)...
          ' frames: ' num2str(frameList(wFrames(i))) '-' ...
          num2str(frameList(wFinalFrame))]);
      if i <= numFrames
% % %          tempFrameTemp.meshData = frameTemp.meshData(frameList(wFrames(i)):frameList(wFinalFrame));
% % %          tempFrameTemp.cellId   = frameTemp.cellId(frameList(wFrames(i)):frameList(wFinalFrame));
         if numTasks == 1
         % For debugging
         frameTempParts={matlabWorkerJoinCellsParallel(l_rawPhaseData(:,:,...
                         frameList(wFrames(i)):frameList(wFinalFrame)),...
                         frameList(wFrames(i):wFinalFrame), frameTemp, l_p, l_args,imageForce_)};
         else
         t = createTask(newJob, @matlabWorkerJoinCellsParallel, 1,{...
                        l_rawPhaseData(:,:,frameList(wFrames(i))...
                        :frameList(wFinalFrame)) frameList(wFrames(i)...
                        :wFinalFrame) frameTemp l_p l_args imageForce_});
         end
      end
    end
    %--------------------------------------------------------------------------

    if numTasks > 1 
       disp('Submitting job')
       alltasks = get(newJob, 'Tasks');
       if str2double(matlabVersion(1)) < 8
            set(alltasks, 'CaptureCommandWindowOutput', true);
            submit(newJob);
            disp('Awaiting results')
            waitForState(newJob, 'finished');
            outputMessages = get(alltasks, 'CommandWindowOutput');
        else
            set(alltasks, 'CaptureDiary', true);
            %set(newJob, 'AttachedFiles', fileDependicies);
            %set(newJob, 'AutoAttachFiles', false);
            submit(newJob);
            disp('Awaiting results');
            wait(newJob);
            outputMessages = get(alltasks, 'Diary');
        end
       try
           fileName = saveFile(length(fileparts(saveFile))+2:end-4);
            fid = fopen([saveFile(1:end-4) '.dat'],'a');
            errName = ferror(fid);
            disp(['messages saved to ' fileName ' in directory ' ...
              saveFile(1:end-(length(fileName)+4))])
       for jj = 1:length(outputMessages)
           fprintf(fid,['\n','---------------  Frame ' num2str(frameList(jj))...
                        ' --------------------']);
           fprintf(fid,['\n','%']);
           fwrite(fid,outputMessages{jj});
           disp(outputMessages{jj})
        end
        if fid ~= -1,fclose(fid);end
        catch err
            disp([err 'problem while attempt to open ' saveFile ...
                    '-->' errName])
              disp(err)
              disp(outputMessages{jj})   
        end

       if ~isempty(t.Error),errorMessage = get(t,'ErrorMessage');...
          disp(['Error:  ' errorMessage]),end

    if str2double(matlabVersion(1)) < 8
        frameTempParts = newJob.getAllOutputArguments;
    else
        frameTempParts = newJob.fetchOutputs;

    end
    end


    frameTemp = oufti_allocateCellList(frameTemp,frameList);
    for i=1:length(frameTempParts)
        if i<numTasks
           wFinalFrame = wFrames(i+1)-1;
        else
           wFinalFrame = numFrames;
        end
        if length(frameList) == 1
            frameTemp.meshData(frameList) = frameTempParts{i}.meshData(frameList(wFrames(i)):frameList(wFinalFrame));
            frameTemp.cellId(frameList)   = frameTempParts{i}.cellId(frameList(wFrames(i)):frameList(wFinalFrame));
        else
            frameTemp.meshData(frameList(wFrames(i)):frameList(wFinalFrame))  = [frameTempParts{i}.meshData(frameList(wFrames(i)):frameList(wFinalFrame))];
            frameTemp.cellId(frameList(wFrames(i)):frameList(wFinalFrame))    = [frameTempParts{i}.cellId(frameList(wFrames(i)):frameList(wFinalFrame))];
        end
    end

    destroy(newJob);
    %--------------------------------------------------------------------------
    t1 = toc;
    try
    cellList.meshData(frameList) = frameTemp.meshData(frameList);
    cellList.cellId(frameList)   = frameTemp.cellId(frameList);

    disp(['Elapsed time is  ' num2str(t1) ' seconds. ' 'for ' ...
          num2str(length(frameList)) ' processed frame(s)']);
    catch err
          disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)]);
          disp(err.message);
    end
    %--------------------------------------------------------------------------
    clear l_rawPhaseData frameTemp frameTempParts  
    
end
else
    cellList = oufti_allocateCellList(cellList,frameList);
    for frame = frameList
        cellList.meshData(frame) = {[]}; cellList.cellId(frame) = {[]};
        processFrameI(frame,tl,processRegion);
    end
        
end

imageForce = imageForce_;

end

%
%         matlabpool
%         curr_frame = l_rawPhaseData(:,:,3);
%         frameTemp = builtin('cell', 1, numFrames);
%          spmd (4)
%             % distribute arrays
%            % d_clength = codistributed(clength);
%             d_frameListp = codistributed(l_rawPhaseData);
%             d_frameTemp = codistributed(frameTemp);
%             % nLabs = matlabpool('size');
%             for framen = drange(1:numFrames)
%                 
%     frame_current_c = d_frameListp(:,:,framen);% returns a 1x1 cell-array
%              % is it a struct or an empty matrix?
%              %frame_current = frame_current_c{1};
%                 
%        %if framen>numFrames || isempty(frame_current), continue; end
%        %gdisp(['processing cell ' num2str(celln)])
%               disp(['processing frame ' num2str(frameList(framen))])
%    ct = processIndividualIndependentFrames(curr_frame, 3, l_p, l_args,...
%                                            processRegion);
% %   ct = processIndivialCells(frame_current, framen,d_clength(framen),...
%          l_p, OptX, OptY, l_args, img, imge, ...
% %        extDx, extDy, extEnergy, allMap, thres, frame);
%                 
%      %d_frameTemp(framen) = {ct}; % store as a cell-array element
%      d_frameTemp{frameList(framen)} = ct;
%                 
%                 % d_cellListp(celln) = {cell_current}
%             end
%             % cellListp = gather(d_cellListp); % Do we need this?
%         end
%         
%         gdisp ('going back to serial code')
%         
%         % gather the distributed cell data
%         cellTemp = gather(individualFramesStruct);
%        
%
        
        












