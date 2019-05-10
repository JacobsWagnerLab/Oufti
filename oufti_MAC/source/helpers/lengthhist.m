function varargout = lengthhist(varargin)
% lengthhist(cellList)
% lengthhist(cellList1,cellList2,...)
% lengthhist(cellList,xarray)
% lengthhist(cellList1,cellList2,xarray)
% lengthhist(cellList1,pix2mu)
% lengthhist(cellList1,pix2mu1,cellList2,pix2mu2)
% lengthhist(cellList1,cellList2,'overlap') 
% lengthlist = lengthhist(cellList)
% lengthlist(...'nooutput')
% lengthlist(...'nodisp')
% [lengthlist1,lengthlist2] = lengthhist(cellList1,cellList2)
% 
% This function plots a histogram of the length of every cell in a population
% 
% <cellList> is an array that contains the meshes. You can drag and drop 
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <cellList1>, <cellList2> - you can load two arrays, they will be plotted
%     together for comparison.
% <xarray> - array of x values for the histogram, which serve the the
%     centers of bins of the histogram (the boundaries will be in between,
%     for example [1 2 3 4 5] to display all the cells shorter than 1.5 
%     micron in the first bin, between 1.5 and 2.5 microns in the second, etc.).
% <pix2mu>, <pix2mu1>, <pix2mu2> - conversion factors from pixels to 
%     microns, the size of a pixel in microns. Typical value 0.064.
% 'overlap' - indicate this if you wish the histograms to overlap,
%     otherwise they will be displayed separately.
% <lengthlist>, <lengthlist1>, <lengthlist2> - arrays containing the length
%     of every cell to save and plot separately.
% 'nooutput' - blocks standard output (type of data processed, mean, and
%     standard deviation).
% 'nodisp' - suppresses displaying the results as a figure.
if ~isfield(varargin{1},'meshData')
    expr = 'value = cellList{frame}{cell}.length;';
else
    expr = 'value = cellStructure.length;';
end
xlabel1 = 'Cell length, pixels';
xlabel2 = 'Cell length, \mum';
lengtharray = plothist(expr,xlabel1,xlabel2,varargin);
for i=1:nargout, varargout{i} = lengtharray{i}; end

% n = length(varargin);
% pix2mu = 1;
% pix2mu2 = 1;
% cellList2 = [];
% c = [];
% cfactorcount = 0;
% overlap = false;
% if n>0
%     for i=n:-1:1
%         if strcmp(class(varargin{i}),'double') && length(varargin{i})==1
%             cfactorcount = cfactorcount + 1;
%             pix2mu2 = pix2mu;
%             pix2mu = varargin{i};
%         elseif strcmp(class(varargin{i}),'double') && length(varargin{i})>1
%             c = varargin{i};
%         elseif ischar(varargin{i}) && strcmp(varargin{i},'overlap')
%             overlap = true;
%         elseif iscell(varargin{i})
%             cellList2 = varargin{i};
%         end
%     end
%     if cfactorcount==1, pix2mu2 = pix2mu; end
% end
% 
% lengtharray = [];
% for frame = 1:length(cellList)
%     for cell=1:length(cellList{frame})
%         if cell<=length(cellList{frame}) && ~isempty(cellList{frame}{cell})...
%                 && length(cellList{frame}{cell}.mesh)>4
%             lengtharray = [lengtharray cellList{frame}{cell}.length]*pix2mu;
%         end
%     end
% end
% if nargout>0, varargout{1} = lengtharray; end
% 
% if ~isempty(cellList2)
%     lengtharray2 = [];
%     for frame = 1:length(cellList2)
%         for cell=1:length(cellList2{frame})
%             if cell<=length(cellList2{frame}) && ~isempty(cellList2{frame}{cell})...
%                     && length(cellList2{frame}{cell}.mesh)>4
%                 lengtharray2 = [lengtharray2 cellList2{frame}{cell}.length]*pix2mu2;
%             end
%         end
%     end
%     if nargout>1, varargout{2} = lengtharray2; end
% end
% 
% if isempty(cellList2)
%     if isempty(c)
%         [h,c] = hist(lengtharray);
%     else
%         h = hist(lengtharray,c);
%     end
%     h = 100*h/sum(h);
%     hnd = bar(c,h);
%     set(hnd(1),'EdgeColor',[0 0 1])
%     set(hnd(1),'FaceColor',[0 0 1])
% else
%     if isempty(c)
%         [h1,c] = hist(lengtharray);
%     else
%         h1 = hist(lengtharray,c);
%     end
%     h1 = 100*h1/sum(h1);
%     h2 = hist(lengtharray2,c);
%     h2 = 100*h2/sum(h2);
%     if ~overlap
%         h = [h1;h2]';
%         hnd = bar(c,h);
%         set(hnd(1),'EdgeColor',[1 0 0])
%         set(hnd(1),'FaceColor',[1 0 0])
%         set(hnd(2),'EdgeColor',[0 1 0])
%         set(hnd(2),'FaceColor',[0 1 0])
%     else
%         bar(c,h1,'EdgeColor',[1 0 0],'FaceColor',[1 0 0])
%         hold on
%         bar(c,h2,'EdgeColor',[0 1 0],'FaceColor',[0 1 0])
%         bar(c,min(h1,h2),'EdgeColor',[1 1 0],'FaceColor',[1 1 0])
%         hold off
%     end
% end
% if cfactorcount==0
%     xlabel('Cell length, pixels')
% else
%     xlabel('Cell length, \mum')
% end
% ylabel('% cells')