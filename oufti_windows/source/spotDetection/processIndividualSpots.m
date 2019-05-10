function [spotStructure, newImage,dispStructure] = processIndividualSpots(cellData,Cell,params,image,adjustMode)
%--------------------------------------------------------------------------------------
%--------------------------------------------------------------------------------------
%function spotStructure = processIndividualSpots(cellData,Cell,params,image,adjustMode)
%oufti.v0.3.0
%@author:   Brad parry Nov. 2012
%@modified: Ahmad J Paintdakhi Nov. 26, 2012
%@modified: Ahmad J Paintdakhi March 5, 2013
%@modified: Ahmad J Paintdakhi April 18, 2013
%@copyright 2012-2013 Yale University
%=================================================================================
%**********output********:
%spotStructure: A structure containing n-elements, where n is the number of
%spots in a given cell.  The structure has fields l(length), magnitude(volume of
%spot intensity), w(width), h(peak intensity), b(background), d(distance
%from centerline), x(x-coordinate), y(y-coordinate), positions(segment where spot
%is located), rmse(root-mean squared error), and confidenceInterval_b_h_w_x_y.
%**********Input********:
%cellData:  cell structure
%Cell:  not used
%params:    parameter values.
%image: given input image.
%adjustMode:    not used.
%--------------------------------------------------------------------------------------
%Note:  No global variables are allowed in this function
%--------------------------------------------------------------------------------------


%diamond = strel('square',5);
try
 spotStructure.l                            = [];
 spotStructure.d                            = [];
 spotStructure.x                            = [];
 spotStructure.y                            = [];
 spotStructure.positions                    = [];
 spotStructure.adj_Rsquared                     = [];
 dispStructure.adj_Rsquared                     = [];
 dispStructure.w                            = [];
 dispStructure.h                            = [];
if (isempty(cellData) || length(cellData.mesh) < 4),return; end
newImage = [];

scale             = params.scale; %Maximum radius from a peak to consider for fitting
sigmaPsf          = params.spotRadius; %Radius that other spots should be blocked from a spot currently being fitted
minThresh         = params.int_threshold;     
lowPass           = params.lowPass;
rawImage = imcrop(image,cellData.box);
bgr = mean(mean(image));
[rows,columns] = size(rawImage);
cellContour = cat(1,cellData.mesh(:,1:2),flipud(cellData.mesh(:,3:4))) + 1;
%subtract off box, one dimension at a time to avoid using repmat
cellContour(:,1) = cellContour(:,1) - cellData.box(1);
cellContour(:,2) = cellContour(:,2) - cellData.box(2);
cellMask = single(poly2mask(double(cellContour(:,1)),double(cellContour(:,2)),rows,columns));
% % % backgroundRawImage = max(mean(mean(rawImage)),0);
%pad the cell mask with ones -- this method is WAY (~100x) faster than the
%built in f'n imdilate for this purpose
dilatedCellMask = conv2(cellMask,ones(3),'same');
% the convolution will have summed a bunch of neighboors together, bring it
% back to 0's and 1's
dilatedCellMask(dilatedCellMask>0)=1;
[dilatedCellContourX,dilatedCellContourY] = find(bwperim(dilatedCellMask),1,'first');
dilatedCellContour = bwtraceboundary(dilatedCellMask,[dilatedCellContourX,dilatedCellContourY],'n',8,inf,'counterclockwise');
dilatedCellContour = frdescp(dilatedCellContour);
dilatedCellContour = ifdescp(dilatedCellContour,20);
dilatedCellContour = [dilatedCellContour(:,2),dilatedCellContour(:,1)];
  if scale == 0
        newImage = bandPassFilter(rawImage,1,sigmaPsf,minThresh);
  else
      newImage1 = atrouswave(rawImage,scale,lowPass,7,sigmaPsf);
      newImage = bandPassFilter(newImage1,1,sigmaPsf,minThresh);
  end
  maskOfNewImage = ones(size(newImage),'single');
  maskOfNewImage = newImage.*maskOfNewImage;
% % %   maskOfNewImage = imopen(maskOfNewImage,ones(3));
  maskOfNewImage = maskOfNewImage > 0;
  newRawImage = im2uint16(maskOfNewImage.*im2double(rawImage));
%identify background pixels as pixels inside the convoloved (dilated) cell,
%masked out by bandpass filtering
% % % newImageResultant = newImage-newImage1;
backgroundPixels = ~(logical(conv2(newImage,ones(3),'same')))+~dilatedCellMask;
backgroundPixels1 = backgroundPixels(:) == 2;
backgroundPixels2 = backgroundPixels(:) == 1;
backgroundPixels = mode(single([backgroundPixels1 backgroundPixels2]));
backgroundPixelsValues = rawImage(logical(backgroundPixels));
numberOfSpots = bwconncomp(newRawImage,8);

if isempty(numberOfSpots), return; end

[spotStructure,dispStructure] = fitGaussians(cellData,numberOfSpots,rawImage,newRawImage,bgr,params,dilatedCellContour);
% % % % spotStructure = fitGaussiansFinal(cellData,spotStructure,rawImage,params,dilatedCellContour);

catch err
     disp(['Error in ' err.stack(2).file ' in line ' num2str(err.stack(2).line)]);
     disp(err.message);
     return;
end

end















