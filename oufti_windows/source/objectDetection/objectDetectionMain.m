function [nucleoiddata] = objectDetectionMain(image, cellStructure, parameters,objectDetectionManualValue)
image = double(image);
nucleoiddata = [];
cellStructure.model = double(cellStructure.model);
if (cellStructure.model(end,1) ~= cellStructure.model(1,1)) || (cellStructure.model(end,2) ~= cellStructure.model(1,2))
    cellStructure.model(end+1,1:2) = cellStructure.model(1,1:2);
end

orig_image_size = size(image);
orig_image = image;

%size the LoG kernel will take on
N = ceil(parameters.logSigma*3) * 2 + 1;
%use later to make sure bounding box is within image
bxlim = [1 size(image,1) 1 size(image,2)];
bx = [floor(min(cellStructure.model(:,2))), ceil(max(cellStructure.model(:,2))), floor(min(cellStructure.model(:,1))), ceil(max(cellStructure.model(:,1)))];
bx([1 3]) = bx([1 3]) - ceil(N/2) - 10; %******cellPad******
bx([2 4]) = bx([2 4]) + ceil(N/2) + 10; %******cellPad******
%if the box is outside of the image, bring it back
ck = (bx - bxlim).*[1 -1 1 -1];
bx(ck < 0) = bxlim(ck < 0);
%get the cell delimited image
image = image(bx(1):bx(2),bx(3):bx(4));
cm = poly2mask((cellStructure.model(:,1)-bx(3)+1),(cellStructure.model(:,2)-bx(1)+1),bx(2)-bx(1)+1,bx(4)-bx(3)+1);
BGmask = false(size(image));
if objectDetectionManualValue == 0
    if parameters.BGMethod == 1 || parameters.BGMethod == 3
        BGmask = BGmask + cm;
        BG1 = mean(image(BGmask ~= 1));
        image = image - BG1;
        image(image < 0) = 0;
    end
    
    if parameters.BGMethod == 2 || parameters.BGMethod == 3
        %Begin background determination with manual thresholding of a filtered
        %image
        hhh = (filterIM(image,'sl',parameters.BGFilterSize,'ithresh',parameters.BGFilterThresh));
        hhh(hhh > 0) = 1;
        hhh(hhh < 0) = 0;

        minspotarea = floor((parameters.BGFilterSize-1)/2)^2*pi;
        bw = bwconncomp(hhh,4);
        sbw = false(size(image));
        for k = 1:length(bw.PixelIdxList)
            if sum(BGmask(bw.PixelIdxList{k})) >= parameters.inCellPercent*length(bw.PixelIdxList{k}) &&...
                    minspotarea < length(bw.PixelIdxList{k})
                sbw(bw.PixelIdxList{k}) = 1;
            end
        end
        BG2 = mean(image(~sbw));
        %Now subtract off the average background inside the cell
        image = image - BG2;
        image(image < 0) = 0;
    end
    
    if parameters.BGMethod == 4
        %a potentially idiotic to subtract BG
        %Use Otsu's method to split the pixels in the cell into 2 intensity
        %groups. Call the low group background.
        %
        %Works very well for DAPI stained cells
        cmask1 = double(poly2mask(cellStructure.model(:,1), cellStructure.model(:,2), orig_image_size(1), orig_image_size(2)));
        pxval = double(orig_image(cmask1 == 1));
        l = graythresh(pxval-min(pxval));
        value = range(pxval)*parameters.ModValue*l + min(pxval);
        if isempty(value),value=0;end
        image = image - double(value);
        image(image < 0) = 0;
    end
else
    image = image - ((max(image(:)) - min(image(:)))*parameters.ManualBGSel + min(image(:)));
    image(image<0) = 0;
end

[threshim]= subpixelLoGFilter(image, parameters.logSigma, 0, parameters.magnitudeLog, parameters.subPixelRes);

%get a mask of the cell, will be used later to disregard information x %
%outside of the cell

bw = bwconncomp(threshim);
%redraw thresholded image based on fractional location in the cell; new
%thresholded image is savebw
savebw = false(size(threshim));

for k = 1:length(bw.PixelIdxList)
        %for optics where 1 pixel = .0642 um, likely represents a
        %diffraction limited spot. This line refuses to analze such
        %features
        if length(bw.PixelIdxList{k}) < 2*pi*sqrt((parameters.minObjectArea*((1/parameters.subPixelRes)-1)^2)/(2*pi))
            continue
        end
        
        [r, c] = ind2sub(bw.ImageSize,bw.PixelIdxList{k});
        ix = sub2ind([bx(2)-bx(1)+1,bx(4)-bx(3)+1],round(r*parameters.subPixelRes),round(c*parameters.subPixelRes));
        if sum(cm(ix)) >= parameters.inCellPercent*length(ix)
            savebw(bw.PixelIdxList{k}) = 1;
        end
end

po = pixelOutline(savebw);
% shifts nucleoid polygons to correct image coordinates
nucleoiddata.outlines = cellfun(@(x) x*parameters.subPixelRes + 1 + repmat([bx(3) bx(1)]-1,[size(x,1),1]), po,'UniformOutput',0);
nucleoiddata.masks = cellfun(@(x) poly2mask(x(:,1),x(:,2), orig_image_size(1), orig_image_size(2)),nucleoiddata.outlines,'UniformOutput',0);
nucleoiddata.pixels = cellfun(@(x) find(x == 1),nucleoiddata.masks,'UniformOutput',0);
nucleoiddata.pixelvals = cellfun(@(x) orig_image(x), nucleoiddata.pixels,'UniformOutput',0);
nucleoiddata.area = cellfun(@(x) polyarea(x(:,1),x(:,2)), nucleoiddata.outlines,'UniformOutput',0);

if parameters.reSampleOutline
    nucleoiddata.outlines = cellfun(@sampleOutline, nucleoiddata.outlines,'UniformOutput',0);
end

del = cellfun(@(x) x < parameters.minObjectArea, nucleoiddata.area);
nucleoiddata.outlines(del) = [];
nucleoiddata.masks(del) = [];
nucleoiddata.pixels(del) = [];
nucleoiddata.pixelvals(del) = [];
nucleoiddata.area(del) = [];


end