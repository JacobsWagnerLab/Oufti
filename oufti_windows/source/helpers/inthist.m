function varargout = inthist(varargin)
% inthist(cellList)
% inthist(cellList1,cellList2,...)
% inthist(cellList1,cellList2,signal1,signal2,...)
% inthist(cellList,xarray) 
% inthist(cellList1,cellList2,xarray)
% inthist(cellList1,img2int)
% inthist(cellList1,img2int1,cellList2,img2int2)
% inthist(cellList1,cellList2,'overlap')  
% intlist = inthist(cellList)
% inthist(...'nooutput')
% inthist(...'nodisp')
% [intlist1,intlist2] = inthist(cellList1,cellList2)
% 
% This function plots a histogram of the total intensity inside every cell
% in a population. Note, the background has to be subtracted before
% detecting the signal in MicrobeTracker.
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
%     for example [1 2 3 4 5] to display all the cells with the intensity
%     less than 1.5 units in the first bin, between 1.5 and 2.5 units in 
%     the second, etc.).
% <img2int>, <img2int1>, <img2int2> - conversion factors from image units.
%     Use only if normalization is known.
% 'overlap' - indicate this if you wish the histograms to overlap,
%     otherwise they will be displayed separately.
% <intlist>, <intlist1>, <intlist2> - arrays containing the length of every
%     cell to save and plot separately.
% 'nooutput' - blocks standard output (type of data processed, mean, and
%     standard deviation).
% 'nodisp' - suppresses displaying the results as a figure.


expr = {};
for i=1:length(varargin)
    if ~isfield(varargin{1},'meshData')
        if ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
            expr = [expr ['value=sum(cellList{frame}{cell}.' varargin{i} ');']];
        end
    else
        if ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
            expr = [expr ['value=sum(cellStructure.' varargin{i} ');']];
        end
    end
end
if ~isfield(varargin{1},'meshData')
    if isempty(expr)
        expr = 'value=sum(cellList{frame}{cell}.signal1);';
    end
else
    if isempty(expr)
        expr = 'value=sum(cellStructure.signal1);';
    end
end
xlabel1 = 'Total intensity inside cells, image units';
xlabel2 = 'Total intensity inside cells, normalized';
intarray = plothist(expr,xlabel1,xlabel2,varargin);
for i=1:nargout, varargout{i} = intarray{i}; end
