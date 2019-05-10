function cellstat(cellList,varargin)
% cellstat(cellList)
% cellstat(cellList,range)
%
% This function displays basic statistics on an experiment, such as the 
% number of frames, the number of detected cells and spots, cell length,
% width (area divided by length), area, volume, values of fluorescence
% signals.
%
% <cellList> - an array that contains the meshes. You can drag and drop
% the file with the data into MATLAB workspace or open it using MATLAB
% Import Tool. The default name of the variable is cellList, but it can be
% renamed.
% <range> - an optional parameter, indicating the frames on which
% statistics will be calculated, e.g. 1 for the first frame, 2:5 for all
% frames from frame 2 to frame 5.
if isfield(cellList,'meshData')
    cellList = oufti_makeCellListDouble(cellList);
    cellList = cellList.meshData; 
    for ii = 1:length(cellList)
        for jj = 1:length(cellList{ii})
            cellList{ii}{jj} = getextradata(cellList{ii}{jj});
        end
    end
end
if ~isempty(varargin),
    range = varargin{1};
else
    range = 1:length(cellList);
end
ncells = 0;
frames = zeros(1,length(cellList));
nspots = 0;
ncellswithspots = 0;
totlength = [];
totarea = [];
totvolume = [];
nsignal1 = 0;
nsignal2 = 0;
isignal1 = [];
isignal2 = [];
asignal1 = [];
asignal2 = [];
for frame=range
    for cell=1:length(cellList{frame})
        if isfield(cellList{frame}{cell},'mesh') && ~isempty(cellList{frame}{cell}) && length(cellList{frame}{cell}.mesh)>4
            ncells = ncells + 1;
            frames(frame) = 1;
            if isfield(cellList{frame}{cell},'spots') && ~isempty(eval('cellList{frame}{cell}.spots.l'))
                nspots = nspots + length(eval('cellList{frame}{cell}.spots.l'));
                ncellswithspots = ncellswithspots + 1;
            end
            area = cellList{frame}{cell}.area;
            totlength = [totlength cellList{frame}{cell}.length];
            totarea = [totarea area];
            totvolume = [totvolume cellList{frame}{cell}.volume];
            if isfield(cellList{frame}{cell},'signal1') && area>0
                nsignal1=nsignal1+1;
                isignal1=[isignal1 sum(cellList{frame}{cell}.signal1)]; 
                asignal1=[asignal1 area];
            end
            if isfield(cellList{frame}{cell},'signal2') && area>0
                nsignal2=nsignal2+1;
                isignal2=[isignal2 sum(cellList{frame}{cell}.signal2)];
                asignal2=[asignal2 area];
            end
        end
    end
end
if ncellswithspots==0 && nspots==0, ncellswithspots=1; end
disp(' ')
disp(['Total number of cells: ' num2str(ncells) ', located on ' num2str(sum(frames)) ' frames'])
disp(['Total number of spots: ' num2str(nspots) ', located in ' num2str(ncellswithspots) ' cells (' num2str(nspots/ncellswithspots) ' spots/cell)'])
disp(['Cell length is ' num2str(mean(totlength)) ' +/- ' num2str(std(totlength)) ' pixels (mean +/- st. dev.)'])
disp(['Cell width is ' num2str(mean(totarea./totlength)) ' +/- ' num2str(std(totarea./totlength)) ' pixels'])
disp(['Cell area is ' num2str(mean(totarea)) ' +/- ' num2str(std(totarea)) ' pixels^2'])
disp(['Cell volume is ' num2str(mean(totvolume)) ' +/- ' num2str(std(totvolume)) ' pixels^3'])
if nsignal1>0, disp(['Signal1 intensity (total) is ' num2str(sum(isignal1)/nsignal1) ' +/- ' num2str(std(isignal1)) ' (in ' num2str(nsignal1) ' cells)']); end
if nsignal1>0, disp(['Signal1 intensity (normalized by area) is ' num2str(sum(isignal1)/sum(asignal1)) ' +/- ' num2str(std(isignal1./asignal1))]); end
if nsignal2>0, disp(['Signal2 intensity (total) is ' num2str(sum(isignal2)/nsignal2) ' +/- ' num2str(std(isignal2)) ' (in ' num2str(nsignal2) ' cells)']); end
if nsignal2>0, disp(['Signal2 intensity (normalized by area) is ' num2str(sum(isignal2)/sum(asignal2)) ' +/- ' num2str(std(isignal2./asignal2))]); end
disp(' ')