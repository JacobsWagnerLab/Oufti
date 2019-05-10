function [shiftedIMs] = shiftMovieImages(alignFromSelData, loadStackValue, varargin)
%applies the tranformations found in alignFromSelData to all image series
%supplied. alignFromSelData is obtained from alignFromSelection.m
% Images are supplied as:
%   shiftMovieImages(alignFromSelData, IM1, IM2, IM3, ... IMn)
% in the above command, IM1... is a string that points to the first image
% in a series of images.
% 
% See accompanying documentation in subPixMovieReg
% 
% Brad Parry, June 2013
global phaseData signalData1 signalData2 signalData3
shiftedIMs{length(varargin)} = [];

for k = 1:length(varargin)
    if ~loadStackValue
        [File1Name,FileExtension] = strtok(varargin{k},'.');
        indFile = regexp(File1Name,'\d+$');
        firstIndFile = str2num(File1Name(indFile:end));

        for frame = alignFromSelData.frameRange
            frameIndex = find(frame == alignFromSelData.frameRange);

            FilenameFrame = [File1Name(1:indFile-1), num2str(frame + firstIndFile - 1,...
                ['%0',num2str(length(indFile:length(File1Name))),'d']), FileExtension];

            IM = imread(FilenameFrame);
            im = shiftImage(IM, alignFromSelData.shifts(frameIndex,:));
            roi = alignFromSelData.matrixSliceROI +...
                round([alignFromSelData.shifts(end,2), alignFromSelData.shifts(end,2), +...
                alignFromSelData.shifts(end,1), +alignFromSelData.shifts(end,1)]);
            shiftedIMs{k}{frameIndex} = im(roi(1):roi(2), roi(3):roi(4));
        end
    else
        for frame = alignFromSelData.frameRange
            frameIndex = find(frame == alignFromSelData.frameRange);
            if k == 1
                IM = phaseData(:,:,frameIndex);
            elseif k == 2
                IM = signalData1(:,:,frameIndex);
            elseif k == 3
                IM = signalData2(:,:,frameIndex);
            elseif k == 4
                IM = signalData3(:,:,frameIndex);
            end
            im = shiftImage(IM, alignFromSelData.shifts(frameIndex,:));
            roi = alignFromSelData.matrixSliceROI +...
                round([alignFromSelData.shifts(end,2), alignFromSelData.shifts(end,2), +...
                alignFromSelData.shifts(end,1), +alignFromSelData.shifts(end,1)]);
            shiftedIMs{k}{frameIndex} = im(roi(1):roi(2), roi(3):roi(4));
        end
    end
end
end

function [shiftedImage] = shiftImage(image, shift)
% applies the shift to image. shift contains an [x, y] vector and need not
% be integer values. If non-integer, a convolution will be used shuffle
% intensities from adjacent pixels after any requisite integer based
% operations have been performed.

if isempty(shift), shiftedImage = image; return, end
image = double(image);
if nargout == 0
    isho = @(im) imshow(im,[min(im(:)) max(im(:))],'initialmagnification','fit');
    image1 = image;
end

mnx = min(image(:));
%split the shifting operation into integer based (s) and fractional (shiftx,
% shifty)
[s(1),shiftx]=deal(fix(shift(1)),shift(1)-fix(shift(1)));
[s(2),shifty]=deal(fix(shift(2)),shift(2)-fix(shift(2)));

if s(1)>=1
    image(:,end-s(1)+1:end)=[];
    m = repmat(mnx, [size(image,1),s(1)]);
    image = cat(2,m,image);
elseif s(1)<=-1
    image(:,1:abs(s(1))) = [];
    m = repmat(mnx,[size(image,1),abs(s(1))]);
    image = cat(2,image,m);
end
if s(2)>=1
    image(end-s(2)+1:end,:)=[];
    m = repmat(mnx,[s(2),size(image,2)]);
    image = cat(1,m,image);
elseif s(2)<=-1
    image(1:abs(s(2)),:)=[];
    m = repmat(mnx,[abs(s(2)),size(image,2)]);
    image=cat(1,image,m);
end

if shiftx ~= 0
    sx = [-shiftx,1-abs(shiftx) shiftx];
    sx(sx<0)=0;
    sx = sx / sum(sx(:));
    image=conv2(double(image),sx,'same');
end

if shifty ~= 0
    sy = [-shifty,1-abs(shifty),shifty];
    sy(sy<0)=0;
    sy = sy / sum(sy(:));
    image=conv2(double(image'),sy,'same')';   
end

shiftedImage=image;
end