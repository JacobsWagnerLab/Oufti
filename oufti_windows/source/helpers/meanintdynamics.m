function [intarray,timepoints,erroarray] = meanintdynamics(clist,varargin)
% intdynamics(cellList)
% intdynamics(cellList,timelist)
% intdynamics(cellList,frame2time)
% intdynamics(cellList,signal)
% intdynamics(cellList,...,'area')
% intdynamics(cellList,...,'volume')
% intdynamics(cellList,...,'errorbar')
% intdynamics(cellList,...,'nodisp')
% [intlist,timelist,errors] = intdynamics(cellList,...)
% 
% This function plots the dynamics of the signal in a list of cells 
% obtained by MicrobeTracker. Note, the background has to be corrected 
% and necessary controls taken to accont for possible background 
% fluorescence and the signal integrated and present in the list.
% 
% <cellList> - an array that contains the meshes. You can drag and drop the 
%     file with the data into MATLAB workspace or open it using MATLAB 
%     Import Tool. The default name of the variable is cellList, but it can 
%     be renamed.
% <timelist> - the list of timepoints when each frame was taken. For 
%     example, if 3 images were taken at zero time and 2 more 10 minutes 
%     this array must be [0 0 0 10 10].
% <frame2time> - the intervals between frames. If 'timelist' array is not 
%     provided, the each frame will be considered taken at a different 
%     timepoint separated by 'frame2time' intervals. If not provided, the 
%     data will be plotted versus frame rathen than time. The constructed 
%     timelist can be obtained at function's output.
% <signal> - the signal field which will be processed. Must be in single 
%     quotes and must start with the word 'signal'. The default is 
%     'signal1'.
%  'area'/'volume' - normalize the signal inside cells by the area or 
%     volume of that cell. Otherwise the total signal will be calculated 
%     for each cell (and averaged for each timepoint).
% 'errorbar' - plot errorbars.
% 'nodisp' - do not produce a plot. Note, the command does not create a new 
%     figure window if at least on is open, MATLAB's 'figure' command to 
%     create a new figure if you wish to avoid replotting any of the 
%     existing figures.
% <intlist> - mean intensity array corresponding to all cells at the 
%     'timelist' points.
% <errors> - errorbar sizes corresponding to the standard error of the mean 
%     for each intensity value in 'intlist'.

% get the inputs
if ~isfield(clist,'meshData')
    timelist = 1:length(clist);
else
    clist = oufti_makeCellListDouble(clist);
    for ii = 1:length(clist.meshData)
        for jj = 1:length(clist.meshData{ii})
            clist.meshData{ii}{jj} = getextradata(clist.meshData{ii}{jj});
        end
    end
    timelist =  1:length(clist.meshData);
end
frame2time = 1;
areamode = false;
volumemode = false;
errormode = false;
dispmode = true;
sfield = 'signal1';
timelistflag = false;
frame2timeflag = false;
for i=1:length(varargin)
    if isnumeric(varargin{i}) && length(varargin{i})>1
        timelist = varargin{i};
        timelistflag = true;
    elseif isnumeric(varargin{i}) && length(varargin{i})==1
        frame2time = varargin{i};
        frame2timeflag = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'area') && ~volumemode
        areamode = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'volume') && ~areamode
        volumemode = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'errorbar')
        errormode = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'nodisp')
        dispmode = false;
    elseif ischar(varargin{i}) && length(varargin{i})>6 && strcmp(varargin{i}(1:6),'signal')
        sfield = varargin{i};
    end
end
if ~timelistflag && frame2timeflag
    timelist = (timelist-1)*frame2time;
end

% get the list of unique timepoints
timepoints = [];
timeindex = {};
for i=1:length(timelist)
    [tf,loc] = ismember(timelist(i),timepoints);
    if tf
        timeindex{loc} = [timeindex{loc} i];
    else
        timepoints = [timepoints timelist(i)];
        timeindex{length(timepoints)} = i;
    end
end

% collect the data from the cells
intarray = zeros(1,length(timepoints));
erroarray = zeros(1,length(timepoints));
ncellsarray = zeros(1,length(timepoints));
if ~isfield(clist,'meshData')
    
    for tpoint = 1:length(timepoints)
        cintarray = [];
        ncells = 0;
        for frame=timeindex{tpoint}
            for cell=1:length(clist{frame})
                if ~isempty(clist{frame}{cell}) && isfield(clist{frame}{cell},sfield) && ...
                    isfield(clist{frame}{cell},'area') && isfield(clist{frame}{cell},'volume')
                    eval(['signal=sum(clist{frame}{cell}.' sfield ');'])
                    if areamode
                        area = clist{frame}{cell}.area;
                        if isempty(area) || area==0, continue; end
                        signal = signal/area;
                    elseif volumemode
                        volume = clist{frame}{cell}.volume;
                        if isempty(volume) || volume==0, continue; end
                        signal = signal/volume;
                    end
                    cintarray = [cintarray signal];
                    ncells = ncells+1;
                end
            end
        end
        if ncells>=1
            intarray(tpoint) = mean(cintarray);
        end
        if ncells>=2
            erroarray(tpoint) = std(cintarray)/sqrt(ncells-1);
        end
        ncellsarray(tpoint) = ncells;
    end
else
    for tpoint = 1:length(timepoints)
        cintarray = [];
        ncells = 0;
        for frame=timeindex{tpoint}
            [~,cellId] = oufti_getFrame(frame,clist);
            for cell = cellId
                cellStructure = oufti_getCellStructure(cell,frame,clist);
                if oufti_doesCellStructureHaveMesh(cell,frame,clist)&& isfield(cellStructure,sfield) && ...
                    isfield(cellStructure,'area') && isfield(cellStructure,'volume')
                    eval(['signal=sum(cellStructure.' sfield ');'])
                    if areamode
                        area = cellStructure.area;
                        if isempty(area) || area==0, continue; end
                        signal = signal/area;
                    elseif volumemode
                        volume = cellStructure.volume;
                        if isempty(volume) || volume==0, continue; end
                        signal = signal/volume;
                    end
                    cintarray = [cintarray signal];
                    ncells = ncells+1;
                end
            end
        end
        if ncells>=1
            intarray(tpoint) = mean(cintarray);
        end
        if ncells>=2
            erroarray(tpoint) = std(cintarray)/sqrt(ncells-1);
        end
        ncellsarray(tpoint) = ncells;
    end
    
end
if sum(ncellsarray<=1)>=1, disp('Insufficient data to evaluate some timepoints'); end
if dispmode
    if errormode
        errorbar(timepoints,intarray,erroarray,'.-')
    else
        plot(timepoints,intarray,'.-')
    end
    set(gca,'FontSize',16)
    if frame2timeflag
        xlabel('Time','FontSize',16)
    else
        xlabel('Frame','FontSize',16)
    end
    if areamode
        ylabel('Mean signal intensity','FontSize',16)
    elseif volumemode
        ylabel('Mean signal concentration','FontSize',16)
    else
        ylabel('Mean integrated signal','FontSize',16)
    end
end
