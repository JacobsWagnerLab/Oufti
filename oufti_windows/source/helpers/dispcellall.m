function dispcellall(cellList,varargin)
% dispcellall(cellList,images)
% dispcellall(cellList,images,framelist)
% dispcellall(cellList,images,...,spotfieldname)
% dispcellall(cellList,images,...,spotfieldname1,spotfieldname2,spotfieldname3)
% dispcellall(cellList,images,...,signalfieldname)
% dispcellall(cellList,images,...,'numbers')
% dispcellall(cellList,images,...,'disk')
% dispcellall(cellList,images,...,'circle')
% dispcellall(cellList,images,...,parametername,parametervalue,...)
% 
% This function displays a microscope image with the cells detected on this
% image and spots inside (if present). The cells and the spots to be 
% displayed can be filtered using several criteria.
% 
% <cellList> - an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <images> - a 3D array of images. It can be obtained using loadimageseries
%     command, e.g.: images=loadimageseries('c:\users\test\imagefiles',1);
% <framelist> - list of frames to display, i.e. [1 3 4 10] to display
%     frames 1, 3, 4, and 10. Default: all frames.
% <spotfieldname>, <spotfieldname1>, ... - names of the fields containing 
%     spots, must start with 'spots', e.g. 'spots', 'spots1', 'spots2', 
%     etc. Several fields can be listed. Only first one is used for
%     filtering cells. Default: 'spots'. To not display spots, put a 
%     non-existent field name, e.g. 'spotsx'.
% <signalfieldname> - name of the field containing signal (for filtering).
%     It must start with 'signal', e.g. 'signal1', 'signal2', etc. Default: 
%     'signal1'.
% 'numbers' - use this option to display the numbers inside cells.
% 'disk' - display spots as filled disks rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 'circle' - display spots as circles rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 
% The rest of the parameters must be submitted in the format 
% <parametername>,<parametervalue>, where <parametername> must be in quotes
% and <parametervalue> must be the value of this parameter. For example:
% dispcellall(cellList,images,cell,'markersize',2). Here are the
% possible parameters:
% 
% 'markersize' - spots marker size, 0 - don't show, default automatic.
% 'imagelimits' - image scaling limits, default max to min.
% 'colortable' - nx3 table of the marker disk colors. The table is an
%     n-by-3 or n+1-by-3 matrix, where n if the number of fields. Each row
%     corresponds to the color of the field, in the RGB (red, green, blue)
%     format, the optional extra row corresponds to the color of 
%     overlapping regions.
% 
% Filtering parameters: only cells/spots satisfying them will be displayed.
% If no spot exists in the cell or should bedisplayed and any of the spot
% filters is used, the cell will only be displayed if 'nspots' parameter is
% present and contains zero.
%
% 'cellintensity' - array of two numbers: low and high limits of the total 
%     intensity in the cell (as written in the mesh - either 
%     <spotfieldname> field or, if not provided, 'signal1' field)
% 'cellmeanintensity' - mean intensity in the cell
% 'celllength' - low and high limits of the cell length (in pixels)
% 'cellarea' - low and high limits of the cell area (in pixels squared)
% 'cellvolume' - low and high limits of the cell volume (in pixels cubic)
% 'cellmeanwidth' - low and high limits of the mean (along the length)
%     width of the cell
% 'cellmaxwidth' - low and high limits of the maximum width of the cell
% 'cellcurvature' - low and high limits of the cell curvature (in 1/pixel)
% 'nspots' - list of possible numbers of spots (e.g. 0:3 for up to 3 spots)
% 'spotmagnitude' - low and high limits of the spot magnitude
% 'spotheight' - low and high limits of the spot height (intensity units)
% 'spotwidth' - low and high limits of the spot width (in pixels)
% 'spotposition' - low and high limits of the spot position from the "old"
%     pole of the cell. This parameter allows more than 2 limits, in which
%     case the spot will be displayed if it is either between 1st and 2nd,
%     or 3rd and 4th, etc.
% 'spotrelposition' - low and high limits of the relative (between 0 and 1)
%     spot position, measured from the "lod" pole. This parameter also
%     allows more than two limits.  

%------------------------------------------------------------------
%update:  Feb. 20, 2013 Ahmad.P new data format
cellId = [];
if isfield(cellList,'meshData')
    cellId = cellList.cellId;
    cellList = oufti_makeCellListDouble(cellList);
    cellList = cellList.meshData; 
    for ii = 1:length(cellList)
        for jj = 1:length(cellList{ii})
            cellList{ii}{jj} = getextradata(cellList{ii}{jj});
        end
    end
end
%------------------------------------------------------------------

marker = 0; % dot
spotfieldnames = {'spots'};
signalfieldnames = {'signal1'};
nfields = 1;
nsgnfields = 1;
numbers = false;
ind = [];
if ~isempty(varargin{1}) && isnumeric(varargin{1}) && length(size(varargin{1}))>=2, images=varargin{1}; else images=1; end

p.markersize = -1;
p.imagelimits = [];
p.colortable = 0;
p.cellintensity = [];
p.cellmeanintensity = [];
p.celllength = [];
p.cellarea = [];
p.cellvolume = [];
p.cellmeanwidth = [];
p.cellmaxwidth = [];
p.cellcurvature = [];
p.nspots = [];
p.spotmagnitude = [];
p.spotheight = [];
p.spotwidth = [];
p.spotposition = [];
p.spotrelposition = [];
fields = fieldnames(p);
% dispspotsgrid(cellList,images,framelist,nspots,intensity,position,radius,color,dimensions)
i=0;
while i<length(varargin)
    i=i+1;
    for f=1:length(fields)
        if ischar(varargin{i}) && strcmp(varargin{i},fields{f})
            if length(varargin)>i && isa(varargin{i+1},class(p.(fields{f})))
                p.(fields{f}) = varargin{i+1};
                varargin = varargin([1:i-1 i+2:end]);
                i = i-1;
                break
            else
                disp('Incorrect parameter combination');
                return
            end
        end
    end
end
for i=1:length(varargin)
    if ischar(varargin{i}) && strcmp(varargin{i},'circle')
        marker = 2; % circle
    elseif ischar(varargin{i}) && strcmp(varargin{i},'disk')
        marker = 1; % disk
    elseif ischar(varargin{i}) && strcmp(varargin{i},'numbers')
        numbers = true;
    elseif ischar(varargin{i}) && length(varargin{i})>=5 && strcmp(varargin{i}(1:5),'spots')
        spotfieldnames{nfields} = varargin{i};
        nfields = nfields+1;
    elseif ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
        signalfieldnames{nsgnfields} = varargin{i};
        nsgnfields = nsgnfields+1;
    elseif strcmp(class(varargin{i}),'double')
        ind = [ind i];
    end
end
varargin = varargin(ind);
if length(varargin{:})>=2 && ~isempty(varargin{1})
        framelist = varargin{1};
        try
            if framelist(2) ~= 1
                framelist = framelist(1):framelist(2);
            end
        catch
        end
else
    framelist = 1:min(length(cellList),size(images,3));
end
framelist = framelist(ismember(framelist,1:min(length(cellList),length(cellList))));
if isa(p.markersize,'numeric')
    if marker==0
        markersize = 8;
    elseif marker == 1
        markersize = p.markersize;
    else
        markersize = 1.5;
    end
end
nfields = length(spotfieldnames);
if p.colortable==0
    colortable = repmat([0 1 0],nfields,1);
    colortable(1,:) = [1 0 0];
    if nfields>1, colortable = [colortable;[1 1 0]]; end
end

mode = 0; % mode=1 - spotFinderZ's cellList, mode=2 - spotFinderF's spotList
try
    if framelist(1) == 1 && framelist(2) ==1
          framelist = 1;
    end
catch
end
for frame=framelist
    if iscell(cellList{frame})
        for i=1:length(cellList{frame})
            if ~isempty(cellList{frame}{i}) && isstruct(cellList{frame}{i})
                if isfield(cellList{frame}{i},'mesh')
                    mode=1;
                elseif isfield(cellList{frame}{i},'x')
                    mode=2;
                end
                break
            end
        end
    end
end
if mode==0, disp('No data in this list or wrong format'); return; end

for frame=framelist
    figure('name',[' Frame ' num2str(frame)])
    warning off
    if frame<=size(images,3) && numel(images)>1, imshow(images(:,:,frame),p.imagelimits); end
    warning on
    set(gca,'pos',[0 0 1 1])
    hold on
    [xlim2,ylim2] = drawcell(cellList{frame},mode,spotfieldnames,signalfieldnames,markersize,colortable,marker,numbers,1,p,[],cellId{frame});
    hold off
    if frame>size(images,3) || numel(images)<=1
        xlim([0 xlim2(2)]);
        ylim([0 ylim2(2)]);
        axis off; 
        set(gca,'YDir','reverse')
        pos=get(gcf,'pos');
        set(gcf,'pos',[pos(1) pos(2)+pos(4)-pos(3)*ylim2(2)/xlim2(2) pos(3) pos(3)*ylim2(2)/xlim2(2)],'Color',[0 0 0]); 
    end
end