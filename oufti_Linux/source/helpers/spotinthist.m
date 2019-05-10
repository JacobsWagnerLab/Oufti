function varargout = spotinthist(varargin)
% spotinthist(cellList)
% spotinthist(cellList1,cellList2,...)
% spotinthist(cellList,xarray)
% spotinthist(cellList1,cellList2,xarray)
% spotinthist(cellList1,normfactor)
% spotinthist(cellList1,normfactor1,cellList2,normfactor2)
% spotinthist(cellList1,cellList2,'overlap') 
% intlist = spotinthist(cellList)
% [intlist1,intlist2] = spotinthist(cellList1,cellList2)
% spotinthist(...'nooutput') 
% 
% This function plots a histogram of the intensities of all spots in every
% cell in a population. Note, the cells manually detected with spotfinderM
% will all have zero intensity.
% 
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <cellList1>, <cellList2> ? you can load two arrays, they will be plotted
%     together for comparison.
% <xarray> ? array of x values for the histogram, which serve the the
%     centers of bins of the histogram (the boundaries will be in between,
%     for example [1 2 3 4 5] to display all the spots with intensities
%     less than 1.5 in the first bin, between 1.5 and 2.5 in the second,
%     etc.).
% <normfactor>, <normfactor1>, <normfactor2> ? conversion factors from
%     image units. Use only if normalization is known.
% 'overlap' ? indicate this if you wish the histograms to overlap,
%     otherwise they will be displayed separately.
% <intlist>, <intlist1>, <intlist2> ? arrays containing the intensity of
%     every spot to save and plot separately.
% <nooutput> blocks standard output (type of data processed, mean, and
%     standard deviation). 
if ~isfield(varargin{1},'meshData')
    expr = 'value=reshape(cellList{frame}{cell}.spots.magnitude,1,[]);';
else
    expr = 'value=reshape(cellStructure.spots.magnitude,1,[]);';
end
xlabel1 = 'Spot intensity, image units';
xlabel2 = 'Spot intensity, normalized';
intarray = plothist(expr,xlabel1,xlabel2,varargin);
for i=1:nargout, varargout{i} = intarray{i}; end
