
function CL = getExtraDataMultiThreadNew(CL)


sched = findResource('scheduler','type','local');
newJob = createJob();
nTasks = sched.ClusterSize;


disp('--------- Adding extra fields to cellList ---------');


if isfield(CL,'meshData')
   numFrames = length(CL.meshData);
   tempCellList = CL.meshData;
else
   numFrames = length(CL);
   tempCellList = CL;
end

%--------------------------------------------------------------------------------
% Divide the compact cell lists and send them to the workers.
wFrames= 1;
processIncrement = ceil(numFrames/nTasks);
lastIncrement = numFrames - ((nTasks-1)*processIncrement);
if lastIncrement <= 0, nTasks = nTasks -1;end
for i = 2:nTasks
    wFrames(i) = wFrames(i-1)+processIncrement; %#ok<AGROW>
    if wFrames(i) >= numFrames, nTasks = i; break; end
end
if lastIncrement <=0, wFrames(end) = numFrames;end
%--------------------------------------------------------------------------------

%--------------------------------------------------------------------------------
%for debugging purposes make number of nTasks = 1, otherwise if nTasks
%greater than 1 prallel computation is done.  In this stage one can not
%perform debugging as computation is done in the background utilizing
%different number of threads/tasks.
%nTasks = 1;

for i = 1:nTasks
    if i<nTasks
        wFinalFrame = wFrames(i+1)-1;
    else
        wFinalFrame = numFrames;
    end
    disp(['Making tasks for ' num2str(wFinalFrame-wFrames(i)+1) ' cells given the range: ' ...
           num2str(wFrames(i)) '-' num2str(wFinalFrame)]);
    if i <= numFrames
       if nTasks == 1
       
       % For debugging
        cellTempParts = {getExtraDataMicroFluidic(tempCellList(wFrames(i):wFinalFrame))};
       else
        t = createTask(newJob,@getExtraDataMicroFluidic,1,{tempCellList(wFrames(i):wFinalFrame)});
       end
    end
end 

%--------------------------------------------------------------------------------
%if the number of tasks or threads chosen above is greater than 1, the
%number of tasks are submitted to each thread for processing.  Variable
%newJob is the vector containing number of tasks.
if nTasks > 1 
    disp('Submitting job')
    alltasks = get(newJob, 'Tasks');
    submit(newJob);
    disp('Awaiting results')
    waitForState(newJob, 'finished');
    %all the outputs from different tasks are created and stored inside
    %variable frameTempParts.
    cellTempParts = getAllOutputArguments(newJob);
end

%--------------------------------------------------------------------------
% Stitch together the output
cellTemp = {};
for i=1:length(cellTempParts)
    if i<nTasks
        wFinalFrame = wFrames(i+1)-1;
    else
        wFinalFrame = numFrames;
    end
    if iscell(cellTempParts{i})
        if cellfun(@isempty,cellTempParts{i})
           cellTemp(wFrames(i):wFinalFrame) = cellTempParts{i};
        else
           cellTemp(wFrames(i):wFinalFrame) = cellTempParts{i};
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
           cellTemp(wFrames(i):wFinalFrame) = cellTempParts{i};
        else
            cellTemp(wFrames(i):wFinalFrame) = cellTempParts{i};
        end
        %------------------------------------------------------------------
    end
end
%destroy newJob, a variable that stores all the data from the different
%tasks/threads.  This is almost equivalent to delete function in c++ as the
%memory is de-allocated back to the system.
destroy(newJob);
%--------------------------------------------------------------------------

if isfield(CL,'meshData')
   
   CL.meshData = meshData;
else
    CL = meshData;
end

end


