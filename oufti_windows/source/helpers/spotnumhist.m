function varargout = spotnumhist(varargin)
% spotnumhist(cellList)
% spotinthist(cellList1,cellList2,...)
% spotinthist(cellList,xarray)
% spotinthist(cellList1,cellList2,xarray)
% spotinthist(cellList1,cellList2,'overlap') 
% numlist = spotinthist(cellList)
% [numlist1,numlist2] = spotinthist(cellList1,cellList2)
% spotinthist(...'nooutput') 
% 
% This function plots a histogram of the number of previously detected
% spots inside every cell in a population.
% 
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <cellList1>, <cellList2> ? you can load two arrays, they will be plotted
%     together for comparison.
% <xarray> ? array of x values for the histogram, which serve the the
%     centers of bins of the histogram (the boundaries will be in between,
%     for example [1 2 3 4 5] to display cells with 1 spot, then with 2
%     spots, etc., [2 5 8 11] will group in the first bin cells with 1-3
%     spots, in the second cells with 4-6 spots, etc.).
% 'overlap' ? indicate this if you wish the histograms to overlap,
%     otherwise they will be displayed separately.
% <numlist>, <numlist1>, <numlist2> ? arrays containing the number of spots
%     in every cell to save and plot separately.
% <nooutput> blocks standard output (type of data processed, mean, and
%     standard deviation). 
if ~isfield(varargin{1},'meshData')
    expr = 'value=length(cellList{frame}{cell}.spots.magnitude);';
else
    expr = 'value=length(cellStructure.spots.magnitude);';
end
xlabel1 = 'Number of spots per cell';
xlabel2 = xlabel1;
intarray = plothist(expr,xlabel1,xlabel2,varargin);
for i=1:nargout, varargout{i} = intarray{i}; end
