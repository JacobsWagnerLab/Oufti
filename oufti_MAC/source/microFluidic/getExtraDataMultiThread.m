function cellList = getExtraDataMultiThread(CL)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%cellList = getExtraDataMultiThread(CL)
%calls getExtraDataMicroFluidic function which adds extra field names as
%indicated in that function.  The call to the function uses spmd mode,
%which is a parallel mode via co-distributed arrays.  The functions
%requires parallel computation toolbox.
%oufti.v0.2.7
%@authos:  Ahmad Paintdakhi
%@date:    December 19, 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%str:  cellList structure with additional field names of steplength,
%length,lengthvector,area,steparea,volume,stepvolume
%**********Input********:
%CL:  cellList structure
%==========================================================================
matlabVersion = version;
if str2double(matlabVersion(1)) < 8
    sched = findResource('scheduler','type','local');
    numThreads = sched.ClusterSize;
else
    sched = parcluster(parallel.defaultClusterProfile); 
    numThreads = sched.NumWorkers;
end
if matlabpool('size') == 0, matlabpool open;end

disp('--------- Adding extra fields to cellList ---------')

try
    if isfield(CL,'meshData')
        numFrames = length(CL.meshData);
        tempCellList = CL.meshData;
    else
        numFrames = length(CL);
        tempCellList = CL;
    end
    
if numFrames > 500
    counter = 0;
    tempArray = 0:99:numFrames;
    for ii = 1:length(tempArray) - 1
        plusOne = 1;
        if tempArray(ii+1)+counter+plusOne > numFrames
            frameTemp = builtin('cell',1,numFrames - tempArray(end));
            plusOne = -1;
        else
            frameTemp = builtin('cell',1,tempArray(ii+1)+1 - tempArray(ii));
        end
         if isfield(CL,'meshData')
            tempCellList = CL.meshData(tempArray(ii)+counter+1:tempArray(ii+1)+counter+plusOne);
         else
            tempCellList = CL(tempArray(ii)+counter+1:tempArray(ii+1)+counter+plusOne);
        end
        spmd(numThreads)
        d_cellList = codistributed(tempCellList);
        d_frameTemp = codistributed(frameTemp);
        for framen = drange(1:numFrames)
            str = getExtraDataMicroFluidic(d_cellList(framen));
            d_frameTemp(framen) = {str};

        end
        end
        frameTemp = gather(d_frameTemp);
        meshData  = cell(1,size(frameTemp,2));
        for jj = 1:length(frameTemp)
            meshData{jj} = frameTemp{jj}{1};
        end
        if isfield(CL,'meshData')
           cellList.meshData(tempArray(ii)+counter+1:tempArray(ii+1)+counter+plusOne) = meshData;
        else
            cellList(tempArray(ii)+counter+1:tempArray(ii+1)+counter+plusOne) = meshData;
        end
        counter = counter + 1;
    end
    if matlabpool('size') > 0, matlabpool close; end
    
    cellList.cellId = CL.cellId; 
else   
    frameTemp = builtin('cell', 1, numFrames);
    spmd(numThreads)
        d_cellList = codistributed(tempCellList);
        d_frameTemp = codistributed(frameTemp);

        for framen = drange(1:numFrames)
    % % %         cell_current_c = d_cellList(celln);
    % % %         cell_current = cell_current_c{1};
            str = getExtraDataMicroFluidic(d_cellList(framen));
            d_frameTemp(framen) = {str};

        end
    end
    frameTemp = gather(d_frameTemp);
    meshData  = cell(1,size(frameTemp,2));
    for ii = 1:length(frameTemp)
        meshData{ii} = frameTemp{ii}{1};
    end
    if isfield(CL,'meshData')
       cellList.cellId = CL.cellId;
       cellList.meshData = meshData;
    else
        cellList = meshData;
    end

    if matlabpool('size') > 0, matlabpool close; end

end

catch err
    disp(err.message);
     disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)]);
    if matlabpool('size') > 0, matlabpool close; end
end
end
            
