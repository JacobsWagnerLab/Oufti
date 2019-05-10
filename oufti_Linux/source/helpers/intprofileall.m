function intprofileall(cellList,varargin)
% intprofileall(cellList)
% intprofileall(cellList,folder)
% intprofileall(cellList,signal)
% intprofileall(cellList,normalization)
% intprofileall(cellList,pix2mu)
% intprofileall(cellList,pix2mu,background)
% intprofileall(cellList,[],background)
% 
% This function plots a intensity profile for a all cells in the list and
% will save them to the folder indicated as MATLAB figures. Note, the
% background has to be subtracted before detecting the signal in cellTracker.
% 
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it
%     can be renamed.
% <folder> - the name of the folder where the figures will be saved, e.g.
%     'c:\users\test\'. Default: current folder.
% <signal> - the signal channel in which the data is written, e.g.
%     'signal1', 'signal2', etc. Has to be in single quotes and start from
%     the word 'signal'. Default: 'signal1'.
% <normalization> - the type of normalization of the plot, one of the words
%     below:
%   - 'integrate' - full integral signal in each segment will be plotted
%   - 'area' (default) - the integral signal in each segment will be divided by the area of the segment.
%   - 'volume' - the total signal in the segment will be divided by the estimated volume of the segment assuming it's ideal cut cone shape (the height equal to the width).
% <pix2mu> - conversion factor from pixels to microns, the size of a pixel
%     in microns.
% <background> ? background level (usually obtained in a control experiment
%     with a different strain not containing the signal), which will be
%     plotted in addition to the signal profile. 


%------------------------------------------------------------------
%update:  Feb. 20, 2013 Ahmad.P new data forma
if isfield(cellList,'meshData')
    cellList = oufti_makeCellListDouble(cellList);
% % %     for ii = 1:length(cellList.meshData)
% % %         for jj = 1:length(cellList.meshData{ii})
% % %             cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
% % %         end
% % %     end
end
%------------------------------------------------------------------

folder = '';
ind = [];
for i=length(varargin):-1:1
    if ischar(varargin{i}) && ~strcmp(varargin{i}(1:6),'signal') && ...
            ~ strcmp(varargin{i},'integrate') && ~strcmp(varargin{i},'volume') && ...
            length(varargin{i})>5
        folder = varargin{i};
        if ~strcmp(folder(end),'\') && ~strcmp(folder(end),'/')
            folder = [folder '\'];
        end
    else
        ind = [i ind];
    end
end
varargin = varargin(ind);

fig = figure;
if ~isfield(cellList,'meshData')
    for frame = 1:length(cellList)
            for cell = 1:length(cellList{frame})
                figure(fig);
                res = intprofile(cellList,frame,cell,[varargin 'nooutput']);
                if ~isempty(res)
                    title(['Frame ' num2str(frame) ', cell ' num2str(cell)])
                    saveas(gca,[folder 'frame' num2str(frame) '_cell' num2str(cell) '.fig'])
                end
            end   
    end
        
else
    for frame = 1:length(cellList.meshData)
            [~, cellId] = oufti_getFrame(frame, cellList);
            for cell = cellId
                figure(fig);
                res = intprofile(cellList,frame,cell,[varargin 'nooutput']);
                if ~isempty(res)
                    title(['Frame ' num2str(frame) ', cell ' num2str(cell)])
                    saveas(gca,[folder 'frame' num2str(frame) '_cell' num2str(cell) '.fig'])
                end
            end   
    end
end
close(fig)