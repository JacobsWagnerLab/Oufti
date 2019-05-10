function varargout = meaninthist(varargin)
% meaninthist(cellList)
% meaninthist(cellList1,cellList2,...)
% meaninthist(cellList1,cellList2,signal1,signal2,...)
% meaninthist(cellList,xarray)
% meaninthist(cellList1,cellList2,xarray)
% meaninthist(cellList1,normfactor)
% meaninthist(cellList1,normfactor1,cellList2,normfactor2)
% meaninthist(cellList1,cellList2,'overlap') 
% intlist = meaninthist(cellList)
% [intlist1,intlist2] = meaninthist(cellList1,cellList2)
% meaninthist(...'nooutput')
% meaninthist(...'nodisp') 
% 
% This function plots a histogram of the mean intensity inside every cell
% in a population, i.e. total intensity divided by the area of the cell.
% Note, the background has to be subtracted before detecting the signal in
% cellTracker.
% 
% <cellList> - an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <cellList1>, <cellList2> - you can load two arrays, they will be plotted
%     together for comparison.
% <signal1>, <signal2> - the signal field which will be processed. Must be
%     in single quotes and must start from the word 'signal'. The default
%     is 'signal1'.
% <xarray> - array of x values for the histogram, which serve the the
%     centers of bins of the histogram (the boundaries will be in between,
%     for example [1 2 3 4 5] to display all the cells with intensities
%     less than 1.5 in the first bin, between 1.5 and 2.5 in the second, etc.).
% <normfactor>, <normfactor1>, <normfactor2> - conversion factors from
%     image units. Use only if normalization is known.
% 'overlap' - indicate this if you wish the histograms to overlap,
%     otherwise they will be displayed separately. The default colors for
%     overlapping bars are red (first set), green (second set), and yellow
%     (overlap).
% <intlist>, <intlist1>, <intlist2> - arrays containing the intensity of 
%     every cell to save and plot separately.
% 'nooutput' - blocks standard output (type of data processed, mean, and
%     standard deviation).
% 'nodisp' - suppresses displaying the results as a figure.

expr = {};
if ~isfield(varargin{1},'meshData')
    for i=1:length(varargin)
        if ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
        expr = [expr ['value=sum(cellList{frame}{cell}.' varargin{i} ')/cellList{frame}{cell}.area;']];
        end
    end
    if isempty(expr)
    expr = 'value=sum(cellList{frame}{cell}.signal1)/cellList{frame}{cell}.area;';
    end
else
    for i=1:length(varargin)
        if ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
        expr = [expr ['value=sum(cellStructure.' varargin{i} ')/cellStructure.area;']];
        end
    end
    if isempty(expr)
    expr = 'value=sum(cellStructure.signal1)/cellStructure.area;';
    end
end
xlabel1 = 'Mean intensity inside cells, image units';
xlabel2 = 'Mean intensity inside cells, normalized';
intarray = plothist(expr,xlabel1,xlabel2,varargin);
for i=1:nargout, varargout{i} = intarray{i}; end
