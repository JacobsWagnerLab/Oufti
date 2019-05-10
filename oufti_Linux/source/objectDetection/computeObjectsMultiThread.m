function [objectData] = computeObjectsMultiThread(fluorimage,CL,params,objectDetectionManualValue)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%objectData = getExtraDataMultiThread(CL)
%calls getExtraDataMicroFluidic function which adds extra field names as
%indicated in that function.  The call to the function uses spmd mode,
%which is a parallel mode via co-distributed arrays.  The functions
%requires parallel computation toolbox.
%microbeTracker.v0.2.7
%@authos:  Ahmad Paintdakhi
%@date:    December 19, 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%str:  objectData structure with additional field names of steplength,
%length,lengthvector,area,steparea,volume,stepvolume
%**********Input********:
%CL:  objectData structure
%==========================================================================
sched = parcluster(parallel.defaultClusterProfile); 
numTasks = sched.NumWorkers;
maxWorkers = 6;
numTasks = min(numTasks, maxWorkers);

disp('--------- Adding extra fields to objectData ---------')
% fluorimage = DAPI;%loadimageseries('\\Aunt\Users 1\Manuel Campos\FM\Keio\Plate09 2013-02-19\c2');
%get objectData
% CL = load('\\Aunt\Users 1\Manuel Campos\FM\Keio\2013-02-13 WTx48\Mesh 2013-02-13.mat');
tic;
%numTasks = 1;
if isfield(CL,'meshData')
        numFrames = length(CL.meshData);
        tempobjectData = CL.meshData;
else
        numFrames = length(CL);
        tempobjectData = CL;
end
numTasks = min(numTasks, numFrames);
tmpNumFrames = 1:numTasks:numFrames;
frameList = 1:numFrames;
for ii = 1:length(tmpNumFrames)
    newJob = createJob(sched);
    for i = 1:numTasks
        if numFrames >=  (tmpNumFrames(ii)-1+i)
            if numTasks == 1
                disp(['Making task for 1 frame: ' num2str(frameList(tmpNumFrames(ii))) '-' ...
                num2str(frameList(tmpNumFrames(ii)))]);
            % For debugging
                frameTempParts={matlabWorkerProcessObjects(tempobjectData...
                (frameList(tmpNumFrames(ii)):frameList(tmpNumFrames(ii))),...
                frameList(tmpNumFrames(ii):tmpNumFrames(ii)),fluorimage(:,:,frameList(tmpNumFrames(ii)):frameList(tmpNumFrames(ii))),params,objectDetectionManualValue)};
            else
                disp(['Making task for 1 frame: ' num2str(frameList(tmpNumFrames(ii)-1+i)) '-' ...
                num2str(frameList(tmpNumFrames(ii)-1+i))]);
                t = createTask(newJob, @matlabWorkerProcessObjects, 1,{...
                    tempobjectData(frameList(tmpNumFrames(ii)-1+i):frameList(tmpNumFrames(ii)-1+i))...
                    frameList(tmpNumFrames(ii)-1+i:tmpNumFrames(ii)-1+i) fluorimage(:,:,frameList(tmpNumFrames(ii)-1+i):frameList(tmpNumFrames(ii)-1+i)) ...
                    params objectDetectionManualValue});
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
% % % set(alltasks, 'CaptureCommandWindowOutput', true);
submit(newJob);
disp('Awaiting results')
wait(newJob);
alltasks

         
%try-catch statement is used to avoid error while creating command window
%output file.  If the "window messages" file is created without errors all
%the command window messaged are gathered in variable "outputMessages" are
%printed in the chosen file.  The name of the file is the same as the name
%of the output file but with a modified extension of ".dat".  The ".dat"
%file can be openend in wordpad for better viewing.

      
%all the outputs from different tasks are created and stored inside
%variable frameTempParts.
frameTempParts = newJob.fetchOutputs;
end

%--------------------------------------------------------------------------
        

%--------------------------------------------------------------------------
% Stitch together the output to be stored in a cell structure called
% frameTemp.

for jj=1:length(frameTempParts)

    if isempty(frameTempParts{jj})
        frameTemp(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj)) = {[]};
      %  frameTemp.cellId(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj))   = {[]};
    elseif length(frameList) == 1
        frameTemp(frameList) = frameTempParts{jj};
      %  frameTemp.cellId(frameList)   = frameTempParts{jj}.cellId;
    else
    frameTemp(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj)) = frameTempParts{jj};
 %   frameTemp.cellId(frameList(tmpNumFrames(ii)-1+jj):frameList(tmpNumFrames(ii)-1+jj))   = frameTempParts{jj}.cellId;
    end
end
destroy(newJob);% all the tasks are destroyed here to free up memory and
                % system resources.
end
objectData = frameTemp;
toc;
end
