function varargout = meanwidthhist(varargin)
% meanwidthhist(cellList)
% meanwidthhist(cellList1,cellList2,...)
% meanwidthhist(cellList,xarray)
% meanwidthhist(cellList1,cellList2,xarray)
% meanwidthhist(cellList1,pix2mu)
% meanwidthhist(cellList1,pix2mu1,cellList2,pix2mu2)
% meanwidthhist(cellList1,cellList2,'overlap')
% meanwidthhist(...'nooutput') 
% meanwidthhist(...'nodisp') 
% mwanwidthlist = meanwidthhist(cellList)
% [mwanwidthlist1,mwanwidthlist2] = meanwidthhist(cellList1,cellList2)
% 
% This function plots a histogram of the mean width of every cell in a
% population
% 
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <cellList1>, <cellList2> - you can load two arrays, they will be plotted
%     together for comparison.
% <xarray> - array of x values for the histogram, which serve the the
%     centers of bins of the histogram (the boundaries will be in between,
%     for example [1 2 3 4 5] to display all the cells narrower than 1.5
%     micron in the first bin, between 1.5 and 2.5 microns in the second,
%     etc.).
% <pix2mu>, <pix2mu1>, <pix2mu2> - conversion factors from pixels to
%     microns, the size of a pixel in microns. Typical value 0.064.
% 'overlap' - indicate this if you wish the histograms to overlap,
%     otherwise they will be displayed separately.
% <meanwidthhlist>, <meanwidthhlist1>, <meanwidthhlist2> - arrays
%     containing the width of every cell to save and plot separately.
% 'nooutput' - blocks standard output (type of data processed, mean, and
%     standard deviation).
% 'nodisp' - suppresses displaying the results as a figure.
if ~isfield(varargin{1},'meshData')
    expr = 'mesh=cellList{frame}{cell}.mesh; w=sqrt((mesh(:,4)-mesh(:,2)).^2+(mesh(:,3)-mesh(:,1)).^2); value=mean(w);';
else
    expr = 'mesh=cellStructure.mesh; w=sqrt((mesh(:,4)-mesh(:,2)).^2+(mesh(:,3)-mesh(:,1)).^2); value=mean(w);';
end
xlabel1 = 'Mean cell width, pixels';
xlabel2 = 'Mean cell width, \mum';
widtharray = plothist(expr,xlabel1,xlabel2,varargin);
for i=1:nargout, varargout{i} = widtharray{i}; end