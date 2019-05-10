function dispcell(cellList,images,frame,cell,varargin)
% dispcell(cellList,images,frame,cell)
% dispcell(cellList,images,frame,cell,radius)
% dispcell(cellList,images,frame,cell,radius,border)
% dispcell(cellList,images,frame,cell,radius,border,color)
% dispcell(cellList,images,frame,cell,[],border)
% dispcell(cellList,images,frame,cell,[],[],color)
% dispcell(cellList,images,frame,cell,...,fieldnames)
% dispcell(cellList,images,frame,cell,...,'disk')
% dispcell(cellList,images,frame,cell,...,'circle')
%
% This function plots a digram of the number of spots vs. the length of a
% cell. The meshes and the spots have to be previously detected.
%
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <images> - a 3D array of images. It can be obtained using loadimageseries
%     command, e.g.: images=loadimageseries('c:\users\test\imagefiles',1);
% <frame> - the frame number of the cell to display.
% <cell> - the cell number of the cell to display.
% <radius> - radius of the marker disk in image pixels.
% <border> - width of the empty area to display outside of the cell.
%     Default: the box field created by MicrobeTracker is used.
% <color> - color table of the marker disk in image pixels. The table is an
%     n-by-3 or n+1-by-3 matrix, where n if the number of fields. Each row
%     corresponds to the color of the field, in the RGB (red, green, blue)
%     format, the optional extra row corresponds to the color of 
%     overlapping regions.
% <fieldnames> - names of the fields containing spots, must start with
%     'spots', e.g. 'spots', 'spots1', 'spots2', etc. Several fields can be 
%     listed. Default: 'spots'. To not display spots, put a non-existent
%     field name, e.g. 'spotsx'.
% 'disk' - display spots as filled disks rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 'circle' - display spots as circles rather than dots. The radius in
%     this case is measured in image pixels, not screen points.

%------------------------------------------------------------------
%update:  Feb. 20, 2013 Ahmad.P new data format
if isfield(cellList,'meshData')
    cellList = oufti_makeCellListDouble(cellList); 
    for ii = 1:length(cellList.meshData)
        for jj = 1:length(cellList.meshData{ii})
            cellList.meshData{ii}{jj} = getextradata(cellList.meshData{ii}{jj});
        end
    end
end
%------------------------------------------------------------------
if ~isfield(cellList,'meshData')

    if frame>length(cellList) || cell>length(cellList{frame}) || ...
        isempty(cellList{frame}{cell}) || length(cellList{frame}{cell}.mesh)<5
        disp('No such cell in the list')
    return
    end

else
    if frame>length(cellList.meshData) || ~oufti_doesCellStructureHaveMesh(cell,frame,cellList)
        disp('No such cell in the list')
    return
    end
    
end

if isempty(images), images = 1; end
marker = 0; % dot
ind = [];
border = [];
flag1 = false;
fieldnames = {'spots'};
nfields = 1;
for i=1:length(varargin)
    if ischar(varargin{i}) && strcmp(varargin{i},'disk')
        marker = 1; % disk
    elseif ischar(varargin{i}) && strcmp(varargin{i},'circle')
        marker = 2; % circle
    elseif ischar(varargin{i}) && length(varargin{i})>=5 && strcmp(varargin{i}(1:5),'spots')
        fieldnames{nfields} = varargin{i};
        nfields = nfields+1;
    elseif strcmp(class(varargin{i}),'double') && ~flag1
        if length(varargin{i})==1, markersize = varargin{i}; end
        flag1 = true;
    elseif strcmp(class(varargin{i}),'double') && length(varargin{i})==1
        border = varargin{i};
    elseif strcmp(class(varargin{i}),'double')
        ind = [ind i];
    end
end
nfields = length(fieldnames);
varargin = varargin(ind);
if length(varargin)>=1 && size(varargin{1},2)==3 && min(min(varargin{1}))>=0 && max(max(varargin{1}))<=1
    colortable = varargin{1};
else
    colortable = repmat([0 1 0],nfields,1);
    colortable(1,:) = [1 0 0];
    if nfields>1, colortable = [colortable;[1 1 0]]; end
end
if ~flag1
    if marker==0
        markersize = 8;
    else
        markersize = 1.5;
    end
end
if ~isfield(cellList,'meshData')
    mesh = cellList{frame}{cell}.mesh;
    if isempty(border)
        box = cellList{frame}{cell}.box;
    else
        boxmin = [min(min(mesh(:,[1 3]))) min(min(mesh(:,[2 4]))) max(max(mesh(:,[1 3]))) max(max(mesh(:,[2 4])))];
        box = [max(floor(boxmin(1:2)-border),1) min(ceil(boxmin(3:4)+border),[size(images,2),size(images,1)])-max(floor(boxmin(1:2)-border),1)];
    end
else
    cellStructure = oufti_getCellStructure(cell,frame,cellList);
     mesh = cellStructure.mesh;
    if isempty(border)
        box = cellStructure.box;
    else
        boxmin = [min(min(mesh(:,[1 3]))) min(min(mesh(:,[2 4]))) max(max(mesh(:,[1 3]))) max(max(mesh(:,[2 4])))];
        box = [max(floor(boxmin(1:2)-border),1) min(ceil(boxmin(3:4)+border),[size(images,2),size(images,1)])-max(floor(boxmin(1:2)-border),1)];
    end
    
end

if frame<=size(images,3), imshow(imcrop(images(:,:,frame),box),[]); hold on; end
set(gca,'pos',[0 0 1 1])
if ~isfield(cellList,'meshData')
    drawcell(cellList{frame}(cell),1,fieldnames,'',markersize,colortable,marker,0,1,[],[-box(1)+1 -box(2)+1],cell);
else
    drawcell({cellStructure},1,fieldnames,'',markersize,colortable,marker,0,1,[],[-box(1)+1 -box(2)+1],cell);
end

hold off
if frame>size(images,3)
    xlim([0 box(3)]);
    ylim([0 box(4)]);
    axis off; 
    set(gca,'YDir','reverse')
    pos=get(gcf,'pos');
    set(gcf,'pos',[pos(1) pos(2)+pos(4)-pos(3)*box(4)/box(3) pos(3) pos(3)*box(4)/box(3)],'Color',[0 0 0]); 
end