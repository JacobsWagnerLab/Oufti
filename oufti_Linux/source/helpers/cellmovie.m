function cellmovie(cellList,images,cell,varargin)
% under development
%
% cellmovie(cellList,images,cell)
% cellmovie(cellList,images,cell,firstfilename,...)
% cellmovie(cellList,images,cell,fieldname,...)
% cellmovie(cellList,images,cell,'circle',...)
% cellmovie(cellList,images,cell,'disk',...)
% cellmovie(cellList,images,cell,...,parametername,parametervalue,...)
% 
% This function displays or saves a movie or a series of images of one cell
% through a range of frames in a timelapse series of images.
%
% <cellList> is an array that contains the meshes. You can drag and drop
%     the file with the data into MATLAB workspace or open it using MATLAB
%     Import Tool. The default name of the variable is cellList, but it can
%     be renamed.
% <images> - a 3D array of images. It can be obtained using loadimageseries
%     command, e.g.: images=loadimageseries('c:\users\test\imagefiles',1);
% <cell> - the cell number of the cell to display.
% <firstfilename> - the name of the first file which will be saved. If left
%     empty (default), no file will be saved and the images will be only 
%     displayed on the screen. Otherwise the name will be taken, and if it
%     ends with a number, the number will be incremented according to the
%     number of the image displayed. If it does not end with a number, it
%     will be appended automatically. The file name must end with .avi,
%     .jpg, .eps, or .tif extension to specify the format of the file.
% <fieldnames> - names of the fields containing spots, must start with
%     'spots', e.g. 'spots', 'spots1', 'spots2', etc. Several fields can be 
%     listed. Default: 'spots'. To not display spots, put a non-existent
%     field name, e.g. 'spotsx'.
% 'disk' - display spots as filled disks rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 'circle' - display spots as circles rather than dots. The radius in
%     this case is measured in image pixels, not screen points.
% 
% The rest of the parameters must be submitted in the format 
% <parametername>,<parametervalue>, where <parametername> must be in quotes
% and <parametervalue> must be the value of this parameter. For example:
% cellmovie(cellList,images,cell,'resolution',300). Here are the
% possible parameters:
% 
% 'resolution' - image resolution in dots per inch, default 150.
% 'magnification' - image magnification factor, default 5.
% 'barlength' - length of a scale bar added, default 0 (no bar).
% 'barpos' - position of the scalebar added from bottom left (set negative
%     to go from top or right), default [2 2].
% 'barwidth - width of the scalebar added, default 2.
% 'timestamp' - should the timestamp be added, default false.
% 'timeinterval - length of the time interval for the timestamp, default 1.
% 'timestamppos' - position of the timestamp, default [] (program picks).
% 'timestampfont' - font of the timestamp, default 14.
% 'align' - should alignment to the center of mass be done, default true.
% 'border' - border left around the cell, default 20.
% 'markersize' - spots marker size, 0 - don't show, default automatic.
% 'imagelimits' - image scaling limits, default max to min.
% 'frange' - range (list) of frames to output, default all frames.
% 'colortable' - table nx3 of colors each line being RGB of the particular
%     field; if n># fields, last line represents the color of merged spots.
% 'infocolor' - color of the timestamp and scalebar.

marker = 0; % dot
ind = [];
fieldname = {'spots'};
nfields = 1;
outtype = '';
p.resolution = 150;
p.magnification = 5;
p.barlength = 0;
p.barpos = [2 2];
p.barwidth = 1;
p.timestamp = false;
p.timeinterval = 1;
p.timestamppos = [2 -2];
p.timestampfont = 16;
p.align = true;
p.border = 20;
p.markersize = -1;
p.imagelimits = [];
p.frange = 1:length(cellList);
p.colortable = 0;
p.infocolor = [1 1 1];
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
    if ischar(varargin{i}) && length(varargin{i})>4 && ...
            (strcmp(varargin{i}(end-3:end),'.avi') || strcmp(varargin{i}(end-3:end),'.jpg') || ...
             strcmp(varargin{i}(end-3:end),'.eps') || strcmp(varargin{i}(end-3:end),'.tif'))
         basefile = varargin{i}(1:end-4);
         outtype = varargin{i}(end-2:end);
    elseif ischar(varargin{i}) && strcmp(varargin{i},'disk')
        marker = 1; % disk
    elseif ischar(varargin{i}) && strcmp(varargin{i},'circle')
        marker = 2; % circle
    elseif ischar(varargin{i}) && length(varargin{i})>=5 && strcmp(varargin{i}(1:5),'spots')
        fieldname{nfields} = varargin{i};
        nfields = nfields+1;
    elseif strcmp(class(varargin{i}),'double')
        ind = [ind i];
    end
end
%if isempty(outtype), disp('Unsupported output format'); return; end
if p.markersize==-1
    if marker==0
        markersize = 8;
    else
        markersize = 1.5;
    end
end
nfields = length(fieldname);
if p.colortable==0
    colortable = repmat([0 1 0],nfields,1);
    colortable(1,:) = [1 0 0];
    if nfields>1, colortable = [colortable;[1 1 0]]; end
end

% refine the frange
frange = [];
for frame=p.frange
    if frame<=length(cellList) && cell<=length(cellList{frame}) && ~isempty(cellList{frame}{cell}) && ...
            isfield(cellList{frame}{cell},'mesh') && length(cellList{frame}{cell}.mesh)>1
        frange = [frange frame];
    end
end

% get the shift array
shiftarray.x = zeros(1,frange(end));
shiftarray.y = zeros(1,frange(end));
if p.align
    mesh = cellList{frange(1)}{cell}.mesh;
    [x0,y0] = polycenter([mesh(:,1);flipud(mesh(2:end-1,3))],[mesh(:,2);flipud(mesh(2:end-1,4))]);
    for frame=frange(2:end)
        mesh = cellList{frame}{cell}.mesh;
        shiftarray.x(frame) = mean(mean(mesh(:,[1 3]))) - x0;
        shiftarray.y(frame) = mean(mean(mesh(:,[2 4]))) - y0;
    end
end

% get the box positions at each step
xrange = [Inf -Inf];
yrange = [Inf -Inf];
for frame=frange
    mesh = cellList{frame}{cell}.mesh;
    xrange = [min(xrange(1),min(min(mesh(:,[1 3])))-shiftarray.x(frame)) max(xrange(2),max(max(mesh(:,[1 3])))-shiftarray.x(frame))];
    yrange = [min(yrange(1),min(min(mesh(:,[2 4])))-shiftarray.y(frame)) max(yrange(2),max(max(mesh(:,[2 4])))-shiftarray.y(frame))];
end

% prepare the output format
if strcmp(outtype,'avi')
    aviobj = avifile(outfile,'fps',fps','quality',100,'compression','Cinepak');
elseif strcmp(outtype,'tif')
    fmt = 'tiffn';
elseif strcmp(outtype,'jpg')
    fmt = 'jpeg';
elseif strcmp(outtype,'eps')
    fmt = 'eps';
end
outfiles = {};
if strcmp(outtype,'tif') || strcmp(outtype,'jpg') || strcmp(outtype,'eps')
    if ~isempty(str2num(basefile(end)))
        i = length(basefile);
        while ~isempty(str2num(basefile(i:end)))
            istart = str2num(basefile(i:end));
            i = i-1;
        end
        ndig = ceil(log10(length(frange)+istart-1+1));
        for i=1:length(frange)
            outfiles = [outfiles [basefile num2str(i+istart-1,['%.' num2str(ndig) 'd']) '.' outtype]];
        end
    else
        ndig = ceil(log10(frange(end)+1));
        for i=1:length(frange)
            outfiles = [outfiles [basefile num2str(frange(i),['%.' num2str(ndig) 'd']) '.' outtype]];
        end
    end
end

% make the movie
fig = figure;
mi = mean(mean(mean(images(:,:,:))));
b = ceil(p.border+max(max(abs(shiftarray.x)),max(abs(shiftarray.y))));
for f=1:length(frange)
    frame = frange(f);
    boxmin = [xrange(1)+shiftarray.x(frame)-p.border yrange(1)+shiftarray.y(frame)-p.border ...
        xrange(2)+shiftarray.x(frame)+p.border yrange(2)+shiftarray.y(frame)+p.border];
    box = [boxmin(1:2) boxmin(3:4)-boxmin(1:2)];
    box1 = [floor(box(1:2)) ceil(box(3:4))+1];
    if min(box(1:2))<0
        img = zeros(2*b+size(images(:,:,frame)))+mi;
        img(b+1:end-b,b+1:end-b) = images(:,:,frame);
        imshow(imcrop(img,box1+[b b 0 0]),p.imagelimits)
    else
        imshow(imcrop(images(:,:,frame),box1),p.imagelimits)
    end
    hold on
    set(gca,'pos',[0 0 1 1])
    drawcell(cellList{frame}(cell),1,fieldname,'',markersize,colortable,marker,0,1,[],[-box1(1)+1 -box1(2)+1]);
    if p.barlength>0
        line(box(1)-box1(1)+mod(p.barpos(1),box(3)-p.barlength)+1+[0 p.barlength],box(2)-box1(2)+box(4)+1-mod(p.barpos(2),box(4))+[0 0],...
            'LineWidth',p.barwidth*p.magnification,'color',p.infocolor)
    end
    if p.timestamp
        tstring = [num2str(floor((f-1)*p.timeinterval/60),'%02.f') ':' num2str(mod((f-1)*p.timeinterval,60),'%02.f')];
        text(box(1)-box1(1)+mod(p.timestamppos(1),box(3))+1,box(2)-box1(2)+box(4)+1-mod(p.timestamppos(2),box(4)-p.timestampfont),...
            tstring,'Fontsize',p.timestampfont,'color',p.infocolor,'VerticalAlignment','baseline');
    end
    for i=1:nfields
        if isfield(cellList{frame}{cell},fieldname{i}) && ~isempty(cellList{frame}{cell}.(fieldname{i}))
            
        end
    end
    xlim([box(1)-box1(1) box(1)-box1(1)+box(3)]+1)
    ylim([box(2)-box1(2) box(2)-box1(2)+box(4)]+1)
    hold off
    if strcmp(outtype,'avi')
        aviobj = addframe(aviobj,ax2);
    elseif isempty(outtype)
        pause(0.5)
    else
        hgexport(fig,outfiles{f},hgexport('factorystyle'),'Format',fmt,'Units','pixels','Width',floor(box(3)*p.magnification),'Height',floor(box(4)*p.magnification),'Resolution',p.resolution);
    end
end

if strcmp(outtype,'avi')
    aviobj = close(aviobj); %#ok<NASGU>
end




function [x0,y0] = polycenter(xi,yi)
xi = xi(:); yi = yi(:);
x2 = [xi(2:end);xi(1)];
y2 = [yi(2:end);yi(1)];
a = 1/2*sum (xi.*y2-x2.*yi);
x0 = 1/6*sum((xi.*y2-x2.*yi).*(xi+x2))/a;
y0 = 1/6*sum((xi.*y2-x2.*yi).*(yi+y2))/a;