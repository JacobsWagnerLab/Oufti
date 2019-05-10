% this script opens every image in the user-selected folder, applies a
% long-pass gaussian filter (defined by h below) and saves under the same name

h = fspecial('gaussian', 3, 1);
if isempty(who('filename')), filename=[]; end
if isempty(who('pathname')), pathname=[]; end
[filename,pathname] = uigetfile('*.TIF','Select first file',[pathname '/' filename]);
for i=0:20
    q = filename(end-4-i:end-4);
    if isempty(str2num(q)), break; end
end
basename = filename(1:end-4-i);
dirlist = dir([pathname '/' basename '*']);
namelist = {};
for i=1:length(dirlist)
    namelist{i} = dirlist(i).name;
end
for i=1:length(namelist)
    img = imread([pathname '/' namelist{i}]);
    img = imfilter(img,h,'replicate');
    imwrite(img,[pathname '/' namelist{i}],'TIFF');
end
disp([num2str(length(namelist)) ' files written'])