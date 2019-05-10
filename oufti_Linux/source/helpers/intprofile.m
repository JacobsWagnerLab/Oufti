function [profile,coordinate] = intprofile(cellList,frame,cell,varargin)
% intprofile(cellList,frame,cell)
% intprofile(cellList,frame,cell,signal)
% intprofile(cellList,frame,cell,normalization)
% intprofile(cellList,frame,cell,pix2mu)
% intprofile(cellList,frame,cell,pix2mu,background)
% intprofile(cellList,frame,cell,[],background)
% [profile,coordinate] = intprofile(cellList,frame,cell,...)
% 
% This function plots a intensity profile for a single cell. Note, the
% background has to be subtracted before detecting the signal in cellTracker.
% 
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <frame> - the frame number of the cell to display.
% <cell> - the cell number of the cell to display.
% <signal> - the signal channel in which the data is written, e.g.
%     'signal1', 'signal2', etc. Has to be in single quotes and start from
%     the word 'signal'. Default: 'signal1'.
% <normalization> - the type of normalization of the plot, one of the words
%     below:
%   - 'integrate' - full integral signal in each segment will be plotted
%   - 'area' (default) - the integral signal in each segment will be
%     divided by the area of the segment.
%   - 'volume' - the total signal in the segment will be divided by the
%     estimated volume of the segment assuming it's ideal cut cone shape
%     (the height equal to the width).
% <pix2mu> - conversion factor from pixels to microns, the size of a pixel
%     in microns.
% 'unitlength' - normalize the x-scale so that the length of the cell is 1.
% <background> - background level (usually obtained in a control experiment
%     with a different strain not containing the signal), which will be
%     plotted in addition to the signal profile.
% <profile> - the profile for this cell as plotted.
% <coordinate> - the coordinate of the positins in which the profile is
%     sampled.
% 'nodisp' - do not display the profile.

%------------------------------------------------------------------
%update:  Feb. 20, 2013 Ahmad.P new data format
if isfield(cellList,'meshData')
    cellList = oufti_makeCellListDouble(cellList);
    try
        cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)} = getextradata(cellList.meshData{frame}{oufti_cellId2PositionInFrame(cell,frame,cellList)});
    catch
        warndlg('Adding extra data to cell failed:  check cellList');
        return;
    end
end
%------------------------------------------------------------------

if iscell(varargin) && length(varargin)==1 && iscell(varargin{1})
    varargin = varargin{1};
end
signal = 'signal1';
normalization = 'area';
pix2mu = 1;
pix2mucheck = false;
background = [];
nooutput = false;
dispmode = true;
unitlength = false;
coordinate = [];
profile = [];
for i=length(varargin):-1:1
    if ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
        signal = varargin{i};
    elseif ischar(varargin{i}) && strcmp(varargin{i},'integrate')
        normalization = 'integrate';
    elseif ischar(varargin{i}) && strcmp(varargin{i},'volume')
        normalization = 'volume';
    elseif ischar(varargin{i}) && strcmp(varargin{i},'nooutput')
        nooutput = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'nodisp')
        dispmode = false;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'unitlength')
        unitlength = true;
    elseif strcmp(class(varargin{i}),'double') && length(varargin{i})<=1
        if pix2mucheck
            background = pix2mu;
            if isempty(varargin{i})
                pix2mucheck=false;
                pix2mu=1; 
            else
                pix2mu=varargin{i}; 
            end
        else
            pix2mu = varargin{i};
            pix2mucheck = true;
        end
    end
end
if ~isfield(cellList,'meshData')
    if length(cellList)<frame || length(cellList{frame})<cell || ...
            isempty(cellList{frame}{cell}) || length(cellList{frame}{cell}.mesh)<4
        if ~nooutput
            disp('No such cell in the list');
        end
        return;
    end
else
    isMesh = oufti_doesCellStructureHaveMesh(cell,frame,cellList);
    if ~isMesh
        if ~nooutput
            warndlg('No such cell in the list');
        end
        return;
    end
end

if iscell(varargin) && length(varargin)==1 && iscell(varargin{1})
    varargin = varargin{1};
end
if ~isfield(cellList,'meshData')
    eval(['issignal=isfield(cellList{frame}{cell},''' signal ''');'])
else
    cellStructure = oufti_getCellStructure(cell, frame, cellList);
    issignal = isfield(cellStructure,(signal));
end
if ~issignal
    if ~nooutput
        warndlg(['No field ''' signal ''' recorded for this cell:  Use Reuse meshes toggle button to compute ' signal]);
    end
    return;
end
if ~isfield(cellList,'meshData')
    if unitlength, pix2mu = 1/cellList{frame}{cell}.length; end
else
    cellStructure = oufti_getCellStructure(cell, frame, cellList);
    if unitlength,pix2mu = 1/cellStructure.length;end
end
if ~isfield(cellList,'meshData')
    eval(['sgn=cellList{frame}{cell}.' signal ';'])
else
    cellStructure = oufti_getCellStructure(cell, frame, cellList);
    sgn = cellStructure.(signal);
end
if ~isfield(cellList,'meshData')
    if strcmp(normalization,'area')
        sgn = sgn./cellList{frame}{cell}.steparea;
    elseif strcmp(normalization,'volume')
        sgn = sgn./cellList{frame}{cell}.stepvolume;
    end
else
    if strcmp(normalization,'area')
        sgn = sgn./cellStructure.steparea;
    elseif strcmp(normalization,'volume')
        sgn = sgn./cellStructure.stepvolume;
    end
end
if ~isfield(cellList,'meshData')
    x = cellList{frame}{cell}.lengthvector*pix2mu;
    if dispmode
        plot(x,sgn);
        xlm = [0 cellList{frame}{cell}.length*pix2mu];
        if ~isempty(background)
            hold on
            plot(xlm,[1 1]*background,'--');
            hold off
        end
        xlim(xlm)
        if pix2mucheck && ~unitlength
            xlabel('Length, \mum','FontSize',16)
        elseif ~pix2mucheck && ~unitlength
            xlabel('Length, pixels','FontSize',16)
        else
            xlabel('Relative length','FontSize',16)
        end
        if strcmp(normalization,'area')
            ylabel('Fluorescence, normalized by area','FontSize',16)
        elseif strcmp(normalization,'volume')
            ylabel('Fluorescence, normalized by volume','FontSize',16)
        else
            ylabel('Fluorescence, integrated','FontSize',16)
        end
        set(gca,'FontSize',14)
    end
else
    
   x = cellStructure.lengthvector*pix2mu;
    if dispmode
        plot(x,sgn);
        xlm = [0 cellStructure.length*pix2mu];
        if ~isempty(background)
            hold on
            plot(xlm,[1 1]*background,'--');
            hold off
        end
        xlim(xlm)
        if pix2mucheck && ~unitlength
            xlabel('Length, \mum','FontSize',16)
        elseif ~pix2mucheck && ~unitlength
            xlabel('Length, pixels','FontSize',16)
        else
            xlabel('Relative length','FontSize',16)
        end
        if strcmp(normalization,'area')
            ylabel('Fluorescence, normalized by area','FontSize',16)
        elseif strcmp(normalization,'volume')
            ylabel('Fluorescence, normalized by volume','FontSize',16)
        else
            ylabel('Fluorescence, integrated','FontSize',16)
        end
        set(gca,'FontSize',14)
    end 
    
    
end
coordinate = x;
profile = sgn;