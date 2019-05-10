function dispcellgrid(cellList,images,varargin)
% dispcellgrid(cellList,images)
% dispcellgrid(cellList,images,framelist)
% dispcellgrid(cellList,images,...,spotfieldname)
% dispcellgrid(cellList,images,...,spotfieldname1,spotfieldname2,spotfieldname3)
% dispcellgrid(cellList,images,...,signalfieldname)
% dispcellgrid(cellList,images,...,'numbers')
% dispcellgrid(cellList,images,...,'disk')
% dispcellgrid(cellList,images,...,'circle')
% dispcellgrid(cellList,images,...,parametername,parametervalue,...)
% 
% This function displays the cells from a microscope image with the cells
% detected on this image and spots inside, cropped and displayed on a grid
% (the dimensions can be regulated). The cells and the spots to be
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
% <spotfieldname> - name of the field containing spots, must start with
%     'spots', e.g. 'spots', 'spots1', 'spots2', etc. Default: 'spots'. Set 
%     the spotfieldnames to an unexisting field to display  cell outlines, 
%     but not spots, e.g. dispcellgrid(cellList,images,1,0,'spotsx').
% 'numbers' - use this option to display the numbers inside cells.
% 'disk' - display spots as filled disks rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 'circle' - display spots as circles rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 
% The rest of the parameters must be submitted in the format 
% <parametername>,<parametervalue>, where <parametername> must be in quotes
% and <parametervalue> must be the value of this parameter. For example:
% savedispseries(cellList,images,cell,'resolution',300). Here are the
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
% 'border' - border around the cell in pixels. Set <0 to use standard box.
% 'dimensions' - dimensions of the 'grid' to display: [#rows #colums].
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
if isfield(cellList,'meshData')
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
framelist = 1:length(cellList);
numbers = false;

p.border = 20;
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
p.dimensions = [10 10];
fields = fieldnames(p);
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
    if i==1 && isnumeric(varargin{i})
         framelist = ismember(varargin{i},1:length(cellList));
         if isempty(framelist), return, end
    elseif ischar(varargin{i}) && strcmp(varargin{i},'disk')
        marker = 1; % disk
    elseif ischar(varargin{i}) && strcmp(varargin{i},'circle')
        marker = 2; % circle
    elseif ischar(varargin{i}) && strcmp(varargin{i},'numbers')
        numbers = true;
    elseif ischar(varargin{i}) && length(varargin{i})>=5 && strcmp(varargin{i}(1:5),'spots')
        spotfieldnames{nfields} = varargin{i};
        nfields = nfields+1;
    elseif ischar(varargin{i}) && length(varargin{i})>=6 && strcmp(varargin{i}(1:6),'signal')
        signalfieldnames{nsgnfields} = varargin{i};
        nsgnfields = nsgnfields+1;
    end
end
if p.markersize==-1
    if marker==0
        markersize = 8;
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

ind1 = 0; % column index of the cell in the grid
ind2 = 1; % row index of the cell in the grid
figure
makenewpanel = true;
for frame=framelist
    for cell=1:length(cellList{frame})
        if ~isempty(cellList{frame}{cell}) && length(cellList{frame}{cell}.mesh)>1
            % select the position for the new cell on the grod
            if makenewpanel
                ind1 = ind1 + 1;
                if ind1 == p.dimensions(1)+1
                    ind1=1;
                    ind2 = ind2 + 1;
                    if ind2 == p.dimensions(2)+1;
                        ind2 = 1;
                        figure
                    end
                end
            end
            % display the cell
            if p.border>=0
                mesh = cellList{frame}{cell}.mesh;
                box = [max(0,                             floor([min(min(mesh(:,[1 3]))) min(min(mesh(:,[2 4])))]-p.border)) ...
                       min([size(images,2) size(images,1)],ceil([max(max(mesh(:,[1 3]))) max(max(mesh(:,[2 4])))]+p.border))];
                box(3:4) = box(3:4)-box(1:2);
            else
                box = cellList{frame}{cell}.box;
            end
            dx = box(1)-1;
            dy = box(2)-1;
            subplot(p.dimensions(1),p.dimensions(2),ind1+(ind2-1)*p.dimensions(1));
            hold off
            imshow(imcrop(images(:,:,frame),box),p.imagelimits)
            hold on
            lst={}; lst{cell}=cellList{frame}{cell}; %#ok<AGROW>
            [~,~,nspotsdrawn]=drawcell(lst,1,spotfieldnames,signalfieldnames,markersize,colortable,marker,numbers,1,p,[-dx -dy]);
            if max(nspotsdrawn(cell,:))==-1
                makenewpanel=false; 
                delete(gca)
            else
                makenewpanel=true;
                hold off;
                pos = get(gca,'pos');
                exp = 0.009;
                set(gca,'pos',pos+[-exp -exp 2*exp 2*exp])
            end
        end
    end
end
