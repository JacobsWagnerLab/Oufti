function varargout = cleancelllist(varargin)
% cleancelllist
% outlist = cleancelllist(inlist)
% ...cleancelllist(...,startframe)
% 
% This function cleans the cell list produced by MicrobeTracker in
% timelapse regime by removing the cells which are not present on one frame
% from all subsequent frames. This is done to allow the user removing the 
% failed cells from a single frame, and then removing them from the 
% remaining frames.
%
% When run without arguments, this funtion will prompt the user for the 
% name of the data file and will save it to the new file the same name plus
% a suffix 'cleaned'.
% inlist - input cell list
% outlist - output cell list
% startframe - starting frame

startframe = 1;
fromfile = true;
for i=nargin:-1:1
    if isnumeric(varargin{i})
        startframe = varargin{i};
    elseif iscell(varargin{i}) && nargout>0
        fromfile = false;
        ld.cellList = varargin{i};
    end
end
if fromfile
    [filename,pathname] = uigetfile;
    if isempty(filename), return; end
    filename = [pathname '\' filename];
    ld = load(filename);
end
ncells = 0;
for frame = 1:length(ld.cellList)
    for cell = 1:length(ld.cellList{frame})
        if frame<startframe || isempty(ld.cellList{frame}{cell}) || ~isfield(ld.cellList{frame}{cell},'signal1')...
                || isempty(ld.cellList{frame}{cell}.signal1)
            if frame>=startframe
                for frame1=frame:length(ld.cellList)
                    ld.cellList{frame1}{cell} = [];
                end
            end
        end
    end
    ncells = max(ncells,length(ld.cellList{frame}));
end
lst = [];
for cell=1:ncells
    f = false;
    for frame=1:length(ld.cellList)
        if length(ld.cellList{frame})>=cell && ~isempty(ld.cellList{frame}{cell})
            f = true;
        end
    end
    if f, lst = [lst cell]; end
end
flst = [];
for frame=1:length(ld.cellList)
    f = false;
    for cell=lst
        if length(ld.cellList{frame})>=cell && ~isempty(ld.cellList{frame}{cell})
            f = true;
        end
    end
    if f, flst = [flst frame]; end
end
for frame = flst % 1:length(flst)
    for cell = 1:length(lst)
        if lst(cell)<=length(ld.cellList{frame})
            cellListNew{frame}{cell} = ld.cellList{frame}{lst(cell)};%ld.cellList{flst(frame)}{lst(cell)};
        end
    end
end
if fromfile
    ld.cellList = cellListNew;
    filename = [filename(1:end-4) ' cleaned.mat'];
    save(filename,'-struct','ld')
else
    varargout{1} = cellListNew;
end