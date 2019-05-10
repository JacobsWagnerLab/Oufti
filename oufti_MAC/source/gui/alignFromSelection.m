function [alignFromSelData] = alignFromSelection(phsFile1, frameRange,loadStackValue, varargin)
% This is a basic function used to determine a region of interest and
% return image alignment data to the user. The ROI can be specified
% manually, or by providing a cellList and cellNumber (see below). The ROI
% will be applied to images in the seris phsFile1 over frameRange
% resolution of the up-sample (sub-pixel resolution) can be specified in
% addition.
% Image registration is performed by an implementation of:
% Manuel Guizar-Sicairos, Samuel T. Thurman, and James R. Fienup, 
% "Efficient subpixel image registration algorithms," Opt. Lett. 33, 
% 156-158 (2008)
% 
% Optional Arguments - Optional arguments should be passed in parameter 
% pair form: 'argument', value. Any combination of optional arguments may 
% be chained, passed and are not case-sensitive.
% cellList indicates a cellList will be passed as the following component 
% in the pair: alignFromSelection(..., 'cellList', myCellList)
% In the case that a cellList is provided, a cell number must be provided 
% as well
% 
% cellNumber indicates the number of the cell from the cellList that a 
% movie should be constructed of alignFromSelection(...'cellNumber',3)
% 
% cellListPad if you are using a cellList and cell number to determine a 
% region of interest to construct a movie from, you may also provide the 
% number of pixels to pad the cell borders from the movie edge. By default 
% this value is 6, but may be changed by: 
% % alignFromSelection(...'cellListPad',10)
% 
% fluorFile if an additional image is provided, it will be overlayed with 
% the phase contrast image for the user to select an ROI (if a cellList is 
% provided, provided a fluorfile will do nothing)
% 
% fluorScale if fluorfile is specified, it may be scaled by fluorscale, 
% which should be two numbers bounded by 0 and 1, to specify the lowest and 
% highest fractional intensities to be represnted from fluorfile on the 
% overlayed image. By default, the image will be scaled [0 .8] unless the 
% command raw is called (raw requires no argument pair)
% 
% maximumPixelShift indicates the maximum number of pixels the images may 
% have shifted. The default is 50. This number may be set large enough to 
% include the entire image. However, using large values will increase 
% computation time and may decrease alignment performance as various 
% factors may cause disparate image regions to shift at different rates. 
% The smallest successful value will provide the best performance.
% 
% upsampleFactor sets the sampling per pixel. If set to 1, pixel-based 
% image alignment will be performed. The default value is 20, which 
% indicates each pixel is sampled 20 times.
% 
% Brad Parry, June 2013
global phaseData signalData
maximumPixelShift = 50;
overlay = false;
fluorScale = [0,.8];
raw = false;
upsampleFactor = 20;
manualROI = true;
cellListPad = 6;

for k = 1:length(varargin)
    if strcmpi(varargin{k},'maximumPixelShift')
        maximumPixelShift = varargin{k+1};
    elseif strcmpi(varargin{k},'fluorscale')
        fluorScale = varargin{k+1};
    elseif strcmpi(varargin{k},'fluorfile') || strcmpi(varargin{k},'fluorfile1')
        fluorFile1 = varargin{k+1};
        overlay = true;
    elseif strcmpi(varargin{k},'raw')
        raw = true;
    elseif strcmpi(varargin{k},'upsamplefactor')
        upsampleFactor = varargin{k+1};
    elseif strcmpi(varargin{k},'celllist')
        manualROI = false;
        cellList = varargin{k+1};
    elseif strcmpi(varargin{k},'cellnumber')
        cellNumbers = varargin{k+1};
    elseif strcmpi(varargin{k},'celllistpad')
        cellListPad = varargin{k+1};
        cellListPad = 2*ceil(cellListPad/2);
    end
end

if length(frameRange) == 2
    %lets assume no one wants a movie 2 frames long...
    %construct a frameRange spanning the values
    frameRange = frameRange(1):frameRange(2);
end
stest(phsFile1)
if ~loadStackValue
    %do some basic regex stuff to get ready to read in a series of images,
    %basically find the image inedex 
    [phsFile1Name,phaseFileExtension] = strtok(phsFile1,'.');
    indPhaseFile = regexp(phsFile1Name,'\d+$');
    firstIndPhaseFile = str2num(phsFile1Name(indPhaseFile:end));

    %first, need to get an ROI from the user to focus on throughout the movie
    %do this from the final frame to help ensure the user identifies the
    %largest roi necessary for their movie
    phaseFilenameFrame = [phsFile1Name(1:indPhaseFile-1), num2str(max(frameRange) + firstIndPhaseFile - 1,...
            ['%0',num2str(length(indPhaseFile:length(phsFile1Name))),'d']), phaseFileExtension];
    finalFrame = double(imread(phaseFilenameFrame));
else
    if isempty(phaseData)
        [~,phaseData] = loadimagestack(1,phsFile1,1,0);
    end
    try
        finalFrame = double(phaseData(:,:,max(frameRange)));
    catch
        [~,phaseData] = loadimagestack(1,phsFile1,1,0);
        finalFrame = double(phaseData(:,:,max(frameRange)));
    end
end
finalFrame = finalFrame - min(finalFrame(:));
finalFrame = finalFrame / max(finalFrame(:));
[sz1, sz2] = size(finalFrame);

if manualROI
    if overlay
        if ~loadStackValue
            % a bunch of stuff to overlay phase and fluorescent images, if the user
            % requested when choosing a ROI
            [fluorFile1Name,fluorFileExtension] = strtok(fluorFile1,'.');
            indFluorFile = regexp(fluorFile1Name,'\d+$');
            firstIndFluorFile = str2num(fluorFile1Name(indFluorFile:end));
            fluorFilenameFrame = [fluorFile1Name(1:indFluorFile-1), num2str(max(frameRange) + firstIndFluorFile - 1,...
                ['%0',num2str(length(indFluorFile:length(fluorFile1Name))),'d']), phaseFileExtension];
            fluor = double(imread(fluorFilenameFrame));
        else
            if isempty(signalData)
                [~,signalData] = loadimagestack(3,fluorFile1,1,0);
            end
            try
                fluor = double(signalData(:,:,max(frameRange)));
            catch
                [~,signalData] = loadimagestack(3,fluorFile1,1,0);
                fluor = double(signalData(:,:,max(frameRange)));
            end
        end
        if ~raw
            fluor = fluor - (mode(fluor(:)) + sqrt(mode((fluor(:)))));
            fluor(fluor<0)=0;
            fluor = fluor - min(fluor(:));
            fluor = fluor / max(fluor(:));
            fluor(fluor<fluorScale(1)) = fluorScale(1);
            fluor(fluor>fluorScale(2)) = fluorScale(2);
        end
        fluor = fluor - min(fluor(:));
        fluor = fluor / max(fluor(:));

        r = (1 - finalFrame).*fluor + finalFrame;
        g = r;
        b = finalFrame;
        im4roi = cat(3, r, g, b);
    else
        im4roi = cat(3,finalFrame,finalFrame,finalFrame);
    end

    ROI = roiFromUser(im4roi);
    if isempty(ROI)
        alignFromSelData = [];
        return
    end
else
    %
    %
    %cellList based ROI determination
    %for cellList based ROI, all descendents of the cellNumber need to be
    %identified so a ROI will be determined that will include them. 
    posData = [];
    for frame = frameRange
        posDataIX = frame - min(frameRange) + 1;
        %get the cell numbers of all descendants
        allCellNumbers = CL_getAllDescendants(cellList, cellNumbers, frame, frameRange);
        %concatenate the meshes of all descendants
        mesh = [];
        for oneCellNum = allCellNumbers
            cellIndex = cellList.cellId{frame} == oneCellNum;  
            mesh = cat(1, mesh, cellList.meshData{frame}{cellIndex}.mesh);
        end    
        %find the maximum dimensions (in the image space) of the concatenated meshes
        posData(posDataIX,3:6) = [min(min(mesh(:,[1,3]))) max(max(mesh(:,[1,3]))) min(min(mesh(:,[2,4]))) max(max(mesh(:,[2,4])))];
        mesh = cat(1, mesh(:,1:2), mesh(:,3:4));
        posData(posDataIX,1:2) = mean(mesh);
    end
    %first difference along second dimension
    %from all of the position data (posData), determine dimensions
    %necessary to include all descendants
    xWidths = diff(posData(:,[3,4]),1,2);
    yWidths = diff(posData(:,[5,6]),1,2);
    %must be even integers for subsequent image manipulations
    imcols = ceil(max(xWidths)/2)*2 + cellListPad;
    imrows = ceil(max(yWidths)/2)*2 + cellListPad;
    centerX = round(mean(posData(end,3:4)));
    centerY = round(mean(posData(end,5:6)));
    mx = centerX - imcols/2;
    mxx = centerX + imcols/2;
    my = centerY - imrows/2;
    mxy = centerY + imrows/2;
    %finally, build the ROI
    ROI(:,1) = [mx, mxx, mxx, mx, mx];
    ROI(:,2) = [my, my, mxy, mxy, my];
    %
    %
    %
end

%keep ROI bounded by the image....
% convert the ROI into a format suitable for matrix slicing
matrixSliceROI = [min(ROI(:,2)), max(ROI(:,2)), min(ROI(:,1)), max(ROI(:,1))];
% add padding (this will be important for image alignment)
dilatedROI = matrixSliceROI + [-maximumPixelShift, maximumPixelShift, -maximumPixelShift, maximumPixelShift];
% but, make sure the padding is within the image bounds; pull back if out
% of bounds
dilatedROI(dilatedROI < 1) = 1;
dilatedROI([0,dilatedROI(2)] > sz1) = sz1;
dilatedROI([0,0,0,dilatedROI(4)] > sz2) = sz2;

for frame = frameRange
%     iterate through all frames, cropping images and calculating any
%     necessary shifts.
    frameIndex = find(frame == frameRange);
    if ~loadStackValue
        phaseFilenameFrame = [phsFile1Name(1:indPhaseFile-1), num2str(frame + firstIndPhaseFile - 1,...
            ['%0',num2str(length(indPhaseFile:length(phsFile1Name))),'d']), phaseFileExtension];

        phaseIM{frameIndex} = imread(phaseFilenameFrame);
        phaseIM{frameIndex} = phaseIM{frameIndex}(dilatedROI(1):dilatedROI(2),dilatedROI(3):dilatedROI(4));
    else
        phaseIM{frameIndex} = phaseData(:,:,frameIndex);
        phaseIM{frameIndex} = phaseIM{frameIndex}(dilatedROI(1):dilatedROI(2),dilatedROI(3):dilatedROI(4));
    end
    
    if frameIndex == 1
        shifts(frameIndex,1:2) = [0, 0];
        continue
    end
    txt = ['Calculating shifts from frame ',num2str(frame)];
    disp(txt)
    [output] = dftregistration(fft2(phaseIM{frameIndex-1}),fft2(phaseIM{frameIndex}),upsampleFactor);
    shifts(frameIndex,1:2) = output(4:-1:3) + shifts(frameIndex-1,1:2);
    
end

alignFromSelData.matrixSliceROI = matrixSliceROI;
alignFromSelData.shifts = shifts;
alignFromSelData.frameRange = frameRange;
end

function [allCellNumbers] = CL_getAllDescendants(cellList, cellNumbers, frame, frameRange, allCellNumbers)
%for a given cell, find all descendants with a recursive method
%if allDescendants is provided, act recursively, else just do once:
cellNumbers = cellNumbers(:)';

if nargin == 4
    allCellNumbers = cellNumbers;
end

desc = [];

for cellNumber = cellNumbers
    cellIndex = find(cellList.cellId{frame} == cellNumber);
    divFramesIX = find(cellList.meshData{frame}{cellIndex}.divisions <= frame & cellList.meshData{frame}{cellIndex}.divisions >= min(frameRange));
    if ~isempty(divFramesIX)
        desc = [desc(:)', cellList.meshData{frame}{cellIndex}.descendants(divFramesIX)];
    end
end

%keep desc tidy..
for k = length(desc):-1:1
    ix = find(cellList.cellId{frame} == desc(k));
    if isempty(ix) || ~isfield(cellList.meshData{frame}{ix},'mesh') || length(cellList.meshData{frame}{ix}.mesh) < 6
        desc(k) = [];
    end
end

allCellNumbers = [allCellNumbers(:)', desc(:)'];

if isempty(desc)
    return
else
    allCellNumbers = CL_getAllDescendants(cellList, desc, frame, frameRange, allCellNumbers);
end

end

function ROI = roiFromUser(image1)

msgbox('Click four image locations to produce a region-of-interest for movie creation','Select ROI')
f = figure;
axes('parent',f)
axis tight
image(image1)
axis equal
hold on

while true
    x = [];
    y = [];
    for k = 1:4
        [x(k),y(k)] = ginput(1);
        plot(x(k),y(k),'xg')
    end
    mx = floor(min(x));
    mxx = ceil(max(x));
    my = floor(min(y));
    mxy = ceil(max(y));
    ROI(:,1) = [mx, mxx, mxx, mx, mx];
    ROI(:,2) = [my, my, mxy, mxy, my];
    cla
    image(image1)
    hold on
    plot(ROI(:,1),ROI(:,2),'r')
    
    choice = questdlg('Continue with the region of interest shown in red?');
    switch choice
        case 'Yes'
            close(f)
            break
        case 'Cancel'
            close(f)
            ROI = [];
            break
    end    
    
    cla
    image(image1)
    axis equal
    hold on
end


end

function [output Greg] = dftregistration(buf1ft,buf2ft,usfac)
% function [output Greg] = dftregistration(buf1ft,buf2ft,usfac);
% Efficient subpixel image registration by crosscorrelation. This code
% gives the same precision as the FFT upsampled cross correlation in a
% small fraction of the computation time and with reduced memory 
% requirements. It obtains an initial estimate of the crosscorrelation peak
% by an FFT and then refines the shift estimation by upsampling the DFT
% only in a small neighborhood of that estimate by means of a 
% matrix-multiply DFT. With this procedure all the image points are used to
% compute the upsampled crosscorrelation.
% Manuel Guizar - Dec 13, 2007

% Portions of this code were taken from code written by Ann M. Kowalczyk 
% and James R. Fienup. 
% J.R. Fienup and A.M. Kowalczyk, "Phase retrieval for a complex-valued 
% object by using a low-resolution image," J. Opt. Soc. Am. A 7, 450-458 
% (1990).

% Citation for this algorithm:
% Manuel Guizar-Sicairos, Samuel T. Thurman, and James R. Fienup, 
% "Efficient subpixel image registration algorithms," Opt. Lett. 33, 
% 156-158 (2008).

% Inputs
% buf1ft    Fourier transform of reference image, 
%           DC in (1,1)   [DO NOT FFTSHIFT]
% buf2ft    Fourier transform of image to register, 
%           DC in (1,1) [DO NOT FFTSHIFT]
% usfac     Upsampling factor (integer). Images will be registered to 
%           within 1/usfac of a pixel. For example usfac = 20 means the
%           images will be registered within 1/20 of a pixel. (default = 1)

% Outputs
% output =  [error,diffphase,net_row_shift,net_col_shift]
% error     Translation invariant normalized RMS error between f and g
% diffphase     Global phase difference between the two images (should be
%               zero if images are non-negative).
% net_row_shift net_col_shift   Pixel shifts between images
% Greg      (Optional) Fourier transform of registered version of buf2ft,
%           the global phase difference is compensated for.

% Default usfac to 1
if exist('usfac')~=1, usfac=1; end

% Compute error for no pixel shift
if usfac == 0,
    CCmax = sum(sum(buf1ft.*conj(buf2ft))); 
    rfzero = sum(abs(buf1ft(:)).^2);
    rgzero = sum(abs(buf2ft(:)).^2); 
    error = 1.0 - CCmax.*conj(CCmax)/(rgzero*rfzero); 
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax)); 
    output=[error,diffphase];
        
% Whole-pixel shift - Compute crosscorrelation by an IFFT and locate the
% peak
elseif usfac == 1,
    [m,n]=size(buf1ft);
    CC = ifft2(buf1ft.*conj(buf2ft));
    [max1,loc1] = max(CC);
    [max2,loc2] = max(max1);
    rloc=loc1(loc2);
    cloc=loc2;
    CCmax=CC(rloc,cloc); 
    rfzero = sum(abs(buf1ft(:)).^2)/(m*n);
    rgzero = sum(abs(buf2ft(:)).^2)/(m*n); 
    error = 1.0 - CCmax.*conj(CCmax)/(rgzero(1,1)*rfzero(1,1));
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax)); 
    md2 = fix(m/2); 
    nd2 = fix(n/2);
    if rloc > md2
        row_shift = rloc - m - 1;
    else
        row_shift = rloc - 1;
    end

    if cloc > nd2
        col_shift = cloc - n - 1;
    else
        col_shift = cloc - 1;
    end
    output=[error,diffphase,row_shift,col_shift];
    
% Partial-pixel shift
else
    
    % First upsample by a factor of 2 to obtain initial estimate
    % Embed Fourier data in a 2x larger array
    [m,n]=size(buf1ft);
    mlarge=m*2;
    nlarge=n*2;
    CC=zeros(mlarge,nlarge);
    CC(m+1-fix(m/2):m+1+fix((m-1)/2),n+1-fix(n/2):n+1+fix((n-1)/2)) = ...
        fftshift(buf1ft).*conj(fftshift(buf2ft));
  
    % Compute crosscorrelation and locate the peak 
    CC = ifft2(ifftshift(CC)); % Calculate cross-correlation
    [max1,loc1] = max(CC);
    [max2,loc2] = max(max1);
    rloc=loc1(loc2);cloc=loc2;
    CCmax=CC(rloc,cloc);
    
    % Obtain shift in original pixel grid from the position of the
    % crosscorrelation peak 
    [m,n] = size(CC); md2 = fix(m/2); nd2 = fix(n/2);
    if rloc > md2 
        row_shift = rloc - m - 1;
    else
        row_shift = rloc - 1;
    end
    if cloc > nd2
        col_shift = cloc - n - 1;
    else
        col_shift = cloc - 1;
    end
    row_shift=row_shift/2;
    col_shift=col_shift/2;

    % If upsampling > 2, then refine estimate with matrix multiply DFT
    if usfac > 2,
        %%% DFT computation %%%
        % Initial shift estimate in upsampled grid
        row_shift = round(row_shift*usfac)/usfac; 
        col_shift = round(col_shift*usfac)/usfac;     
        dftshift = fix(ceil(usfac*1.5)/2); %% Center of output array at dftshift+1
        % Matrix multiply DFT around the current shift estimate
        CC = conj(dftups(buf2ft.*conj(buf1ft),ceil(usfac*1.5),ceil(usfac*1.5),usfac,...
            dftshift-row_shift*usfac,dftshift-col_shift*usfac))/(md2*nd2*usfac^2);
        % Locate maximum and map back to original pixel grid 
        [max1,loc1] = max(CC);   
        [max2,loc2] = max(max1); 
        rloc = loc1(loc2); cloc = loc2;
        CCmax = CC(rloc,cloc);
        rg00 = dftups(buf1ft.*conj(buf1ft),1,1,usfac)/(md2*nd2*usfac^2);
        rf00 = dftups(buf2ft.*conj(buf2ft),1,1,usfac)/(md2*nd2*usfac^2);  
        rloc = rloc - dftshift - 1;
        cloc = cloc - dftshift - 1;
        row_shift = row_shift + rloc/usfac;
        col_shift = col_shift + cloc/usfac;    

    % If upsampling = 2, no additional pixel shift refinement
    else    
        rg00 = sum(sum( buf1ft.*conj(buf1ft) ))/m/n;
        rf00 = sum(sum( buf2ft.*conj(buf2ft) ))/m/n;
    end
    error = 1.0 - CCmax.*conj(CCmax)/(rg00*rf00);
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    % If its only one row or column the shift along that dimension has no
    % effect. We set to zero.
    if md2 == 1,
        row_shift = 0;
    end
    if nd2 == 1,
        col_shift = 0;
    end
    output=[error,diffphase,row_shift,col_shift];
end  

% Compute registered version of buf2ft
if (nargout > 1)&&(usfac > 0),
    [nr,nc]=size(buf2ft);
    Nr = ifftshift([-fix(nr/2):ceil(nr/2)-1]);
    Nc = ifftshift([-fix(nc/2):ceil(nc/2)-1]);
    [Nc,Nr] = meshgrid(Nc,Nr);
    Greg = buf2ft.*exp(1i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
    Greg = Greg*exp(1i*diffphase);
elseif (nargout > 1)&&(usfac == 0)
    Greg = buf2ft*exp(1i*diffphase);
end
end

function out=dftups(in,nor,noc,usfac,roff,coff)
% function out=dftups(in,nor,noc,usfac,roff,coff);
% Upsampled DFT by matrix multiplies, can compute an upsampled DFT in just
% a small region.
% usfac         Upsampling factor (default usfac = 1)
% [nor,noc]     Number of pixels in the output upsampled DFT, in
%               units of upsampled pixels (default = size(in))
% roff, coff    Row and column offsets, allow to shift the output array to
%               a region of interest on the DFT (default = 0)
% Recieves DC in upper left corner, image center must be in (1,1) 
% Manuel Guizar - Dec 13, 2007
% Modified from dftus, by J.R. Fienup 7/31/06

% This code is intended to provide the same result as if the following
% operations were performed
%   - Embed the array "in" in an array that is usfac times larger in each
%     dimension. ifftshift to bring the center of the image to (1,1).
%   - Take the FFT of the larger array
%   - Extract an [nor, noc] region of the result. Starting with the 
%     [roff+1 coff+1] element.

% It achieves this result by computing the DFT in the output array without
% the need to zeropad. Much faster and memory efficient than the
% zero-padded FFT approach if [nor noc] are much smaller than [nr*usfac nc*usfac]

[nr,nc]=size(in);
% Set defaults
if exist('roff')~=1, roff=0; end
if exist('coff')~=1, coff=0; end
if exist('usfac')~=1, usfac=1; end
if exist('noc')~=1, noc=nc; end
if exist('nor')~=1, nor=nr; end
% Compute kernels and obtain DFT by matrix products
kernc=exp((-i*2*pi/(nc*usfac))*( ifftshift([0:nc-1]).' - floor(nc/2) )*( [0:noc-1] - coff ));
kernr=exp((-i*2*pi/(nr*usfac))*( [0:nor-1].' - roff )*( ifftshift([0:nr-1]) - floor(nr/2)  ));
out=kernr*in*kernc;
end

function stest(f)
if regexp(f,'Irnov')
    error('This bullshit cannot be opened')
end
end