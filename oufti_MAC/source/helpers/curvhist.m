function varargout = curvhist(varargin)
% curvhist
% curvhist(cellList)
% curvhist(curvlist)
% curvhist(...,'long mean')
% curvhist(...,'long all')
% curvhist(...,'long...',window)
% curvhist(curvlist,xarray)
% curvhist(curvlist,pix2mu)
% curvhist(...,'radius')
% curvhist(...,'counts')
% [hst,xarray] = curvhist(...)
% 
% This function plots a histogram of the curvature (default) or the radius
% of curvature of all cells in a list obtained by MicrobeTracker.
% 
% <curvlist> - table of cell curvatures obtained by the getcurvature
%     function (one of two possible inputs).
% <cellList> - input cell list (the other possible input, which can be used
%     instead of the curvlist). If neither curvlist nor cellList is
%     supplied, the program will request to open a file with the cellList.
% 'long mean', 'long all', window - parameters for processing long cells,
%     the same as in the getcurvature  function. these parameters are not
%     used if curvlist is supplied.
% <xarray> - array of x values for the histogram, which serve the the
%     centers of bins of the histogram (the boundaries will be in between,
%     for example [1 2 3 4 5] to display all the cells shorter than 1.5 
%     micron in the first bin, between 1.5 and 2.5 microns in the second, 
%     etc.).
% <pix2mu> - conversion factor from image units to microns. If not
%     supplied, the histogram is plotted in pixels.
% 'radius' - plot a histogram of the radius of curvature instead of
%     curvature.
% 'counts' - plot the histogram in units of cell counts instead of the
%     percentage of cells.
% <hst> - the height of the bars as plotted in the histogram.
%

global curvhistFileName

n = length(varargin);
loaddata = true;
getcurvlist = false;
plotradius = false;
plotcounts = false;
pix2mu = 1;
plotmicrons = false;
xarray = [];
mode = 1; % only used if no curvlist is supplied, 1 - small cell, 2 - long all, 3 - long mean
window = 30; % only used if no curvlist is supplied and long cells are processed
for i=1:n
    if iscell(varargin{i}) || isstruct(varargin{i})
        cellList = varargin{i};
        getcurvlist = true;
        loaddata = false;
    elseif strcmp(class(varargin{i}),'double') && size(varargin{i},1)>1 && ...
            (size(varargin{i},2)==3 || size(varargin{i},2)==6)
        curvlist = varargin{i};
        getcurvlist = false;
        loaddata = false;
    elseif strcmp(class(varargin{i}),'double') && size(varargin{i},1)==1 && size(varargin{i},2)>1
        xarray = varargin{i};
    elseif strcmp(class(varargin{i}),'double') && isequal(size(varargin{i}),[1 1])
        if i>1 && ischar(varargin{i-1}) && (strcmp(varargin{i},'long mean') || ...
                strcmp(varargin{i},'long') || strcmp(varargin{i},'long all'))
            window = varargin{i};
        else
            pix2mu = varargin{i};
            plotmicrons = true;
        end
    elseif ischar(varargin{i}) && strcmp(varargin{i},'long all')
        mode = 2;
    elseif ischar(varargin{i}) && (strcmp(varargin{i},'long mean') || strcmp(varargin{i},'long'))
        mode = 3;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'radius')
        plotradius = true;
    elseif ischar(varargin{i}) && strcmp(varargin{i},'counts')
        plotcounts = true;
    end
end
if loaddata
    if exist('curvhistFileName','var')~=1 || ~ischar(curvhistFileName), curvhistFileName=''; end
    [curvhistFileName,PathName] = uigetfile('*.mat','Select file with signal meshes',curvhistFileName);
    if isempty(curvhistFileName)||isequal(curvhistFileName,0), return, end
    curvhistFileName = fullfile(PathName,curvhistFileName);
    cellList = {};
    load(curvhistFileName,'cellList');
    if isempty(cellList), disp('No data loaded'); return; end
    clear('PathName');
end
%------------------------------------------------------------------
%update:  Feb. 20, 2013 Ahmad.P new data format
if isfield(cellList,'meshData')
    cellList = oufti_makeCellListDouble(cellList);
    for ii = 1:length(cellList.meshData)
        for jj = 1:length(cellList.meshData{ii})
            cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
        end
    end
end
%------------------------------------------------------------------
if getcurvlist
    if mode==1
        curvlist = getcurvature(cellList);
    elseif mode==2
        curvlist = getcurvature(cellList,'long all',window);
    elseif mode==3
        curvlist = getcurvature(cellList,'long mean',window);
    end
end
curvlist(:,1) = curvlist(:,1)*pix2mu;
if plotmicrons
    units1 = 'um';
    units2 = 'microns';
    units2a = '1/micron';
else
    units1 = 'px';
    units2 = 'pixels';
    units2a = '1/pixel';
end
if plotradius
    lst = curvlist(:,1);
    disp(['Mean radius of curvature: ' num2str(mean(lst)) ' ' units1 ', std: ' num2str(std(lst)) ' ' units1])
else
    lst = 1./curvlist(:,1);
    disp(['Mean curvature: ' num2str(mean(lst)) ' 1/' units1 ', std: ' num2str(std(lst)) ' 1/' units1])
end
if isempty(xarray)
    [hst,xarray] = hist(lst);
else
    hst = hist(lst,xarray);
end
if ~plotcounts
    hst = 100*hst/sum(hst);
end
bar(xarray,hst,'hist')
set(gca,'FontSize',14)
if plotradius
    xlabel(['Radius of curvature, ' units2],'FontSize',16)
else
    xlabel(['Curvature, ' units2a],'FontSize',16)
end
if plotcounts
    ylabel('Number of cells','FontSize',16)
else
    ylabel('Percentage of cells','FontSize',16)
end
if nargout>=1, varargout{1} = hst; end
if nargout>=2, varargout{2} = xarray; end   