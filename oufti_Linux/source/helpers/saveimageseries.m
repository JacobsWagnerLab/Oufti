function saveimageseries(images,varargin)
% saveimageseries(imagestack,pathtofolder,usewaitbar)
% 
% This function saves a set of images into a series of TIFF files
% 
% images - 3D array containing the images
% filename (optional) - name of the first file in the series of target 
%     files (TIFF by default, will open a file dialog if not provided). The
%     series will be created by incrementing an ingex at the end or by
%     incerting and incrementing such index if it is not provided.
% usewaitbar (optional) - 1 (true) to display a waitbar


if isempty(varargin), filename=''; usewaitbar=false; end
if length(varargin)==1, filename=varargin{1}; usewaitbar=false; end
if length(varargin)>=2, filename=varargin{1}; usewaitbar=varargin{2}; end
if ~ischar(filename), filename=''; end
if ~isnumeric(usewaitbar) && ~islogical(usewaitbar), usewaitbar=false; end
if isempty(filename)
    [filename,pathname] = uiputfile('*.tif', 'Enter a filename for the first image');
    if(filename==0), return; end;
else
    pathname = '';
end
if length(filename)>4 && strcmp(filename(end-3:end),'.tif'), filename = filename(1:end-4); end
lng = size(images,3);
if lng==0, return; end
ndig = ceil(log10(lng+1));
istart = 1;
for k=1:ndig
    if length(filename)>=k && ~isempty(str2num(filename(end-k+1:end)))
        istart = str2num(filename(end-k+1:end));
    else
        k=k-1;
        break
    end
end
filename = fullfile2(pathname,filename(1:end-k));
if usewaitbar, w = waitbar(0, 'Saving files'); end
for i=1:lng;
    fnum=i+istart-1;
    cfilename = [filename num2str(fnum,['%.' num2str(ndig) 'd']) '.tif'];
    img = images(:,:,i);
    imwrite(img,cfilename,'tif','Compression','none');
    if usewaitbar, waitbar(i/lng, w); end
end
if usewaitbar, close(w); end
disp('Series of images saved')

