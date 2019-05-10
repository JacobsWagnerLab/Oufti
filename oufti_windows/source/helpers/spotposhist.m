function varargout = spotposhist(cellList,varargin)
% spotposhist(cellList)
% spotposhist(cellList,xarray)
% spotposlist = spotposhist(cellList)
% 
% This function plots a histogram of the relative positions of all spots in all cells. Note, is the orientation of the cells is important, the cells have to be oriented either manually (see cellTracker), with a fluorescent marker, or by any other mean.
% 
% <cellList> is an array that contains the meshes. You can drag and drop the file with the data into MATLAB workspace or open it using MATLAB Import Tool. The default name of the variable is cellList, but it can be renamed.
% <xarray> ? array of x values for the histogram, which serve the the centers of bins of the histogram (the boundaries will be in between, for example 0.05:0.1:0.95 to display spots with relative position below 0.1 in the first bin, the spots with the relative position between 0.1 and 0.2 in the second bin, etc.).
% <spotposlist> - an array of relative spot positions for all cells. 

c = 0.025:0.05:05;
if isfield(cellList,'meshData')
    cellList = oufti_makeCellListDouble(cellList);
    for ii = 1:length(cellList.meshData)
        for jj = 1:length(cellList.meshData{ii})
            cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
        end
    end
end
for i=1:length(varargin)
    if strcmp(class(varargin{i}),'double')
        c = varargin{i};
    end
end

spotlist = [];
if ~isfield(cellList,'meshData')
    for frame=1:length(cellList)
        for cell=1:length(cellList{frame})
            if cell<=length(cellList{frame}) && ~isempty(cellList{frame}{cell}) && ...
                length(cellList{frame}{cell}.mesh)>4 && isfield(cellList{frame}{cell},'spots')
                spotlist = [spotlist cellList{frame}{cell}.spots.l./cellList{frame}{cell}.length];
            end
        end
    end
else
    for frame=1:length(cellList.meshData)
        [~,cellId] = oufti_getFrame(frame,cellList);
        for cell = cellId
            cellStructure = oufti_getCellStructure(cell,frame,cellList);
            if oufti_doesCellStructureHaveMesh(cell,frame,cellList) && isfield(cellStructure,'spots')
                spotlist = [spotlist cellStructure.spots.l./cellStructure.length];
            end
        end
    end
end
h = hist(spotlist,c);
h = 100*h/sum(h);
bar(c,h);
ylabel('% spots')
xlabel('Relative position')
xlim([0 1])

if nargout==1
    varargout{1} = spotlist;
end