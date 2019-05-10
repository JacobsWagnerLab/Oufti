function [intarray,timepoints] = intdynamics(clist,cell,varargin)
% intdynamics(cellList,cell)
% intdynamics(cellList,cell,timelist)
% intdynamics(cellList,cell,frame2time)
% intdynamics(cellList,cell,signal)
% intdynamics(cellList,cell,...,'area')
% intdynamics(cellList,cell,...,'volume')
% intdynamics(cellList,...,'nodisp')
% [intlist,timelist] = intdynamics(cellList,...)
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
% <timelist> - the list of timepoints when each frame was taken. These 
% points must be unique.
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
if isfield(clist,'meshData')
    clist = oufti_makeCellListDouble(clist);
    clist = clist.meshData; 
    for ii = 1:length(clist)
        for jj = 1:length(clist{ii})
            clist{ii}{jj} = getextradata(clist{ii}{jj});
        end
    end
end

timelist = 1:length(clist);
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

% collect the data
intarray = zeros(1,length(timepoints));
for tpoint = 1:length(timepoints)
    frame=timeindex{tpoint}(1);
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
        intarray(tpoint) = signal;
    end
end
if dispmode
    plot(timepoints,intarray,'.-')
    set(gca,'FontSize',14)
    if frame2timeflag
        xlabel('Time','FontSize',16)
    else
        xlabel('Frame','FontSize',16)
    end
    if areamode
        ylabel('Signal intensity','FontSize',16)
    elseif volumemode
        ylabel('Signal concentration','FontSize',16)
    else
        ylabel('Integrated signal','FontSize',16)
    end
end
