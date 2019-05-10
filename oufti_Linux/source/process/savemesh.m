function savemesh(filename,listOfCells,saveList,range)
%-----------------------------------------------------------------------------------------------------
%-----------------------------------------------------------------------------------------------------
%function savemesh(filename,listOfCells,saveList,range)
%
%@author:  Oleksii Sliusarenko
%@date:    October 27, 2011
%@modified:  Ahmad Paintdakhi -- August 06, 2013
%@copyright 2011-2013 Yale University
%==========================================================================
%**********output********:
%none.
%**********Input********:
%filename:  filename where cellList and other variables need to be saved
%listOfCells:   list if any of cells that need to saved only
%saveList:  list of variables that need to be saved.
%range: 2-element array indicating the frame range to save
%
%Purpose: 
%==========================================================================

% % % try
% % % sched = parcluster(parallel.defaultClusterProfile); 
% % % all_jobs = get(sched, 'Jobs');
% % % destroy(all_jobs);
% % % catch err
% % %     disp('no jobs to clear from memory');
% % % end
try
    warning('off','MATLAB:warn_r14_stucture_assignment')
    global p coefPCA weights mCell rawPhaseFolder cellList handles handles1 shiftframes shiftfluo %#ok<NUSED>
    cellListN = [];
    isMicroFluidic = get(handles.highThroughput,'value');
    if isempty(filename), return; end
    if ~isfield(cellList,'meshData'),cellList = oufti_makeNewCellListFromOld(cellList);end
    cellListN = cellfun(@length,cellList.meshData);
    nonEmptyFrame = ~cellfun(@isempty,cellList.meshData);
    nonEmptyFrame = find(nonEmptyFrame==1,1,'first');
    nonEmptyCell = ~cellfun(@isempty,cellList.meshData{nonEmptyFrame});
    nonEmptyCell = find(nonEmptyCell==1,1,'first');
    if isempty(range) || ~isnumeric(range), range = [1 oufti_getLengthOfCellList(cellList)]; end
    if length(range)==1, range=[range range]; end
    range = [max(range(1),1),min(range(2),oufti_getLengthOfCellList(cellList))];
    if range(2)-range(1)<0, return; end
    paramString = getparamstring(handles);
    if ~isMicroFluidic && (isempty(listOfCells) || ~saveList) && range(1)==1 && range(2)==oufti_getLengthOfCellList(cellList) % Saving whole cellList
        if ~isempty(dir(filename)) && ~strcmpi(filename(end-3:end),'.out'), delete(filename); pause(0.1); end
       
       if ~isMicroFluidic && isfield(cellList.meshData{nonEmptyFrame}{nonEmptyCell},'objects')
            objectParams = handles1.objectParams;
            save(filename,'cellList','cellListN','objectParams','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo','-v7.3');
       elseif ~isMicroFluidic
            if length(cellList.meshData) ~= length(cellList.cellId),cellList = oufti_makeNewCellListFromOld(cellList.meshData);end
            save(filename,'cellList','cellListN','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo');
       elseif p.outCsvFormat == 0 && isMicroFluidic
			   cellList.meshData = oufti_makeCellListCompact(cellList);
			   save(filename,'cellList','cellListN','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo','-v7.3');
        end
    elseif (isempty(listOfCells) || ~saveList) % Saving all cells in a range of frames
		cellListTmp = oufti_sliceFrames(range, cellList);
        if range(1) > 1
            cellListTmp = CL_oufti_wipeFrames([1 range(1)-1], cellListTmp);
        end
        if isMicroFluidic,cellListTmp = oufti_makeCellListCompact(cellListTmp);end
        if ~isempty(dir(filename)) && ~isMicroFluidic && ~strcmpi(filename(end-3:end),'.out'), delete(filename); pause(0.1); end
	    if ~isMicroFluidic && isfield(cellList.meshData{nonEmptyFrame}{nonEmptyCell},'objects')
            objectParams = handles1.objectParams;
            save(filename,'cellListN','objectParams','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo','-v7.3');
        elseif isMicroFluidic && p.outCsvFormat == 0 
            save(filename,'cellListN','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo','-v7.3');
        else
            if ~strcmpi(filename(end-3:end),'.out')
                save(filename,'cellListN','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo');
            end
		end
        savetmp(filename,cellListTmp,isMicroFluidic,p)
    else % Saving selected cells in a range of frames
        % cellListTmp = {};
        % for j=range(1):range(2)
            % if j~=range(1), lst = selNewFrame(lst,j-1,j); end
            % for i=lst
                % cellListTmp{j}{i} = cellList{j}{i};
            % end
        % end
		cellListTmp = CL_oufti_sliceFrames(range, cellList);
        cellListTmp = CL_oufti_wipeFrames([1 range(2)], cellList); % empty cellList
        for j=range(1):range(2)
            if j~=range(1), listOfCells = selNewFrame(listOfCells,j-1,j); end
            for i=listOfCells
                %cellListTmp{j}{i} = cellList{j}{i};
                cellListTmp = oufti_addCell(i, j, cellListTmp);
            end
        end
        if isMicroFluidic,cellListTmp = makeNewCellListCompact(cellListTmp);end
        if ~isempty(dir(filename)) && ~isMicroFluidic && ~strcmpi(filename(end-3:end),'.out'), delete(filename); pause(0.1); end

	   if isMicroFluidic && p.outCsvFormat == 0 
           save(filename,'cellListN','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo','-v7.3');
       else
           if ~strcmpi(filename(end-3:end),'.out')
                save(filename,'cellListN','p','coefPCA','weights','mCell','rawPhaseFolder','paramString','shiftframes','shiftfluo');
           end
	   end
        savetmp(filename,cellListTmp,isMicroFluidic,p)
    end
    % display if succeded
    [~,filename,ext] = fileparts(filename);
    if isempty(ext), ext='.mat'; end
    disp(['Analysis saved to file ' filename ext])
catch err
    errorMessage = err.message;
    warndlg(['Analysis was not saved due to error: ' errorMessage]);
end
end

function savetmp(filename,cellList,isMicroFluidic,p)
    % This function adds cellList to a file
    % to use with 'savemesh' function only
	if isMicroFluidic && p.outCsvFormat == 0 
    save(filename,'-append','cellList','-v7.3')
    elseif ~strcmpi(filename(end-3:end),'.out')
	save(filename,'-append','cellList')
	end
end