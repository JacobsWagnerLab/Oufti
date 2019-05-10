function writeMovie(shiftedIMs, alignFromSelData, varargin)
if ~iscell(shiftedIMs{1})
    error('Input shiftedIMs must be a cell array of cells.')
end
%input arg should be a matrix of cells indicating positions...
%2 signals in one cell array indicates an overlay
%
%
%construct default positions cell array
%locations is a sort of coloring index
locations{1} = 1;
locations{2} = [2, 3];
locations{3} = 3;
locations{4} = [2, 4];
locations{5} = 2;
locations{6} = 4;
nPanels = length(shiftedIMs);
rowsCols = ceil(sqrt(nPanels));
positions = cell(floor((nPanels-1)/rowsCols)+1, mod(nPanels-1,rowsCols)+1);
for k = 1:nPanels
    r = floor((k-1)/rowsCols)+1;
    c = mod(k-1,rowsCols)+1;
   if r == 1 && c == 1
        positions{1,1} = 1;
    else
        positions{r,c}(locations{k}) = k;
   end
end

imScale = repmat([0, 1], [length(shiftedIMs), 1]);
timeStampColor = [0, 0, 0];
scaleBarColor = [0, 0, 0];
magnification = 200;
scaleBarPosition = [5, size(shiftedIMs{1}{1},1) - 4];
timeStampPosition = [5,10];
frameRate = 10;
experimentFrameRate = 1;
subtractBackground = false;
timeUnits = 'sec';
pixelSize = 0.0642;
bgMod(1:(length(shiftedIMs)-1)) = 1;
save2path = [cd,'\writeMovieOut'];
writeMovie = true;
relBrightness = ones(1, length(shiftedIMs));
for k = 1:length(varargin)
    if strcmpi(varargin{k},'positions')
        if iscell(varargin{k+1})
            positions = varargin{k+1};
        else
            error('Positions arguement was not understood')
        end
    elseif strcmpi(varargin{k},'imscale')
        imScale = varargin{k+1};
        if size(imScale,1) < length(shiftedIMs)
            error('number of imscale rows must == length(shiftedIMs)')
        end
    elseif strcmpi(varargin{k},'timestampposition')
        timeStampPosition = varargin{k+1};
        if length(timeStampPosition(:)) == 1
            error('timeStampPosition length must == 2')
        elseif isempty(timeStampPosition)
            timeStampPosition = [5,10];
        end
    elseif strcmpi(varargin{k},'timestampcolor')
        timeStampColor = varargin{k+1};
        if isempty(timeStampColor)
            timeStampColor = [0, 0, 0];
        end
    elseif strcmpi(varargin{k},'framerate')
        frameRate = varargin{k+1};
        if isempty(frameRate)
            frameRate = 30;
        end
    elseif strcmpi(varargin{k},'timeunits')
        timeUnits = varargin{k+1}';
    elseif strcmpi(varargin{k},'pixelsize')
        pixelSize = varargin{k+1};
    elseif strcmpi(varargin{k},'scalebarcolor')
        scaleBarColor = varargin{k+1};
        if isempty(scaleBarColor)
            scaleBarColor = [0, 0, 0];
        end
    elseif strcmpi(varargin{k},'scalebarposition')
        scaleBarPosition = varargin{k+1};
        if isempty(scaleBarPosition)
            scaleBarPosition = [5, size(shiftedIMs{1}{1},1) - 4];
        end
    elseif strcmpi(varargin{k},'magnification')
        magnification = varargin{k+1};
        if isempty(magnification)
            magnification = 200;
        end
    elseif strcmpi(varargin{k},'test')
        writeMovie = false;
    elseif strcmpi(varargin{k},'savelocation')
        save2path = varargin{k+1};
    elseif strcmpi(varargin{k},'subtractbackground')
        subtractBackground = true;
        if k+1 <= length(varargin) && isnumeric(varargin{k+1}) && length(varargin{k+1}) == length(shiftedIMs)-1
            bgMod = varargin{k+1};
        end
    elseif strcmpi(varargin{k},'experimentframerate')
        experimentFrameRate = varargin{k+1};
        if isempty(experimentFrameRate)
            experimentFrameRate = 1;
        end
    elseif strcmpi(varargin{k},'relbrightness')
        relBrightness = varargin{k+1};
    end      
end

sz = size(shiftedIMs{1}{1});
%create a template from positions
szp = size(positions);

if subtractBackground
    for k = 2:length(shiftedIMs)
        for q = 1:length(shiftedIMs{k})
            shiftedIMs{k}{q} = shiftedIMs{k}{q} - (mean(shiftedIMs{k}{q}(:)) + bgMod(k-1)*std(shiftedIMs{k}{q}(:)));
            shiftedIMs{k}{q}(shiftedIMs{k}{q}<0) = 0;
        end
    end
end

for frame = alignFromSelData.frameRange
    %things would be much easier with a Python enumerate...
    frameIndex = find(alignFromSelData.frameRange == frame);
    movTemplate = zeros(sz(1)*szp(1),sz(2)*szp(2),3);
    for positionsRow = 1:size(positions,1)
        for positionsCol = 1:size(positions,2)
            if isempty(positions{positionsRow,positionsCol}), continue, end

            IMs = cell(1,length(shiftedIMs));
            for z = 1:length(shiftedIMs)
                IMs{z} = shiftedIMs{z}{frameIndex};
            end
            
            panelPos = positions{positionsRow,positionsCol};
            imColors = readPos(panelPos,nPanels);

            [tmpim] = imOverlay(IMs, imColors,'imscales',imScale,'relbrightness',relBrightness);

            %arrange panels into the movie
            rows = [positionsRow*sz(1) - sz(1) + 1, positionsRow*sz(1)];
            cols = [positionsCol*sz(2) - sz(2) + 1, positionsCol*sz(2)];
            movTemplate(rows(1):rows(2),cols(1):cols(2),1:3) = tmpim;
        end
    end
    mov{frameIndex} = movTemplate;
end

if writeMovie
    testobj = VideoWriter(save2path);
    testobj.FrameRate = frameRate;
    open(testobj)
end
%determine scale bar coordinates
scaleBarX = [scaleBarPosition(1) scaleBarPosition(1) + 1/pixelSize];
scaleBarY = [scaleBarPosition(2) scaleBarPosition(2)];
strFmt = length(num2str((length(shiftedIMs{1})-1)*experimentFrameRate));
if floor(experimentFrameRate) ~= experimentFrameRate
    strFmt = length(num2str((length(shiftedIMs{1})-1)*ceil(experimentFrameRate)))+2;
    strFmt = ['%0',num2str(strFmt),'.1f'];
else
    strFmt = ['%0',num2str(strFmt),'.0f'];
end
figure;
for k = 1:length(mov)
    cla
    imshow(mov{k},'InitialMagnification',magnification)
    hold on

    t = num2str((k - 1)*experimentFrameRate, strFmt);
    t = [t,' ',timeUnits];
    text(timeStampPosition(1),timeStampPosition(2),t,'Color',timeStampColor,'FontSize',18)
    plot(scaleBarX,scaleBarY,'Color',scaleBarColor,'LineWidth',3)
    if writeMovie
        frame = getframe;
        writeVideo(testobj,frame);
    else
        pause(1/frameRate)
    end
end

if writeMovie
    close(testobj)
end
end

function [imColors] = readPos(panelPos,nPanels)
imColors = zeros(nPanels,4);
for r = 1:size(panelPos,1)
    for c = 1:size(panelPos,2)
        if panelPos(r,c) == 0
            continue
        end
        imColors(panelPos(r,c),c) = 1;
    end
end
end

function [overlayed] = imOverlay(IMs, imColors, varargin)
%parameters
% relBrightness = [2.5, 3, 1];
% imScales = [.1, 1;.4, .9;.3, .9];
% imColors = [1, 0, 0, 0;
%             0, 1, 0, 0;
%             0, 0, 1, 1];

%check imColors...
if size(imColors,2) ~= 4 || size(imColors,1) ~= length(IMs)
    %fail
    error('size(imColors) == [length(IMs), 4]')
end
relBrightness = ones(1,length(IMs));
imScales = repmat([0, 1], [length(IMs), 1]);
for k = 1:length(varargin)
    if strcmpi(varargin{k}, 'relbrightness')
        relBrightness = varargin{k+1};
    elseif strcmpi(varargin{k},'imscales')
        imScales = varargin{k+1};
    end
end

relBrightness = relBrightness / max(relBrightness);
%test if size(imScales,1) == length(IMs)
%scale all images 
for k = 1:length(IMs)
    IMs{k} = setImageScale(IMs{k},imScales(k,:));
    %apply relative brightness
    IMs{k} = IMs{k}*relBrightness(k);
end
[sz1, sz2] = size(IMs{1});
greyrgb = zeros(sz1,sz2,4);
for k = 1:size(imColors,1)
    %translate imColors into an index
    ix = (imColors(k,:) ~= 0).*(1:length(imColors(k,:)));
    ix(ix == 0) = [];
    
    greyrgb(:,:,ix) = greyrgb(:,:,ix) + repmat(IMs{k}, [1, 1, length(ix)]);
end

%WARNINGthis will need to be modified to account for channels that share do not
%share space with other channels
%NOT ADDRESSED SINCE IS UNLIKELY THAT MANY CHANNELS WILL BE NEEDED
%SIMULATANEOUSLY
reScale = max([max(sum(imColors(:,2:end))), 1]);
greyrgb(:,:,2:end) = greyrgb(:,:,2:end) / reScale;
greyrgb(:,:,2:end) = greyrgb(:,:,2:end) / max([1, max(max(max(greyrgb(:,:,2:end))))]);

grey = repmat(greyrgb(:,:,1), [1, 1, 3]);
overlayed = (1 - grey).*greyrgb(:,:,2:4) + grey;

% image(greyrgb(:,:,2:end))
% image(overlayed)
end

function im = setImageScale(im, imscale)
%init to min
im = im - min(im(:));
im = im ./ max(im(:));%scale to 1
im(im < imscale(1)) = imscale(1);%thresh to min imscale
im(im > imscale(2)) = imscale(2);%thresh to max imscale
%scale from 0 to 1
im = im - imscale(1);
im = im / imscale(2);
end
