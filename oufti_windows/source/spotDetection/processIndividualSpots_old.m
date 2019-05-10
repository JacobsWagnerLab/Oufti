function [spotStructure, newImage] = processIndividualSpots(cellData,Cell,params,image,adjustMode)
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
 spotStructure.magnitude                    = [];
 spotStructure.w                            = [];
 spotStructure.h                            = [];
 spotStructure.b                            = [];
 spotStructure.d                            = [];
 spotStructure.x                            = [];
 spotStructure.y                            = [];
 spotStructure.positions                    = [];
 spotStructure.rsquared                         = [];
 spotStructure.confidenceInterval_b_h_w_x_y = [];
if (isempty(cellData) || length(cellData.mesh) < 4),return; end
newImage = [];

if isfield(params,'postMinHeight')
    postFitMinHeight = params.postMinHeight; 
    postFitMinWidth  = params.postMinWidth;
    postFitMaxWidth  = params.postMaxWidth;
    postFitError     = params.postError;
else
    postFitMinHeight = 0.0; 
    postFitMinWidth  = 0.5;
    postFitMaxWidth  = 10;
    postFitError     = 0.0;
end

scale             = params.scale; %Maximum radius from a peak to consider for fitting
sigmaPsf          = params.sigmaPsf; %Radius that other spots should be blocked from a spot currently being fitted
minSpotPixels     = params.minSpotPixels; %Minimum number of pixels a spot must have in order to attempt fitting
maxRadius       = params.maxRadius;
minThresh         = params.minThresh;
intensityThrehold = params.intensityThresh;
minArea           = params.minArea;
maxArea           = params.maxArea;
lowPass           = params.lowPass;
spot_x = [];
spot_y = [];
sigma = [];
rsquared = [];
circStrel = strel('disk',11);
%Fitting includes four unknowns, need 4 pixels to produce 4 eq.
rawImage = imcrop(image,cellData.box);
[rows,columns] = size(rawImage);
cellContour = cat(1,cellData.mesh(:,1:2),flipud(cellData.mesh(:,3:4))) + 1;
%subtract off box, one dimension at a time to avoid using repmat
cellContour(:,1) = cellContour(:,1) - cellData.box(1);
cellContour(:,2) = cellContour(:,2) - cellData.box(2);
cellMask = single(poly2mask(double(cellContour(:,1)),double(cellContour(:,2)),rows,columns));
% % % backgroundRawImage = max(mean(mean(rawImage)),0);
%pad the cell mask with ones -- this method is WAY (~100x) faster than the
%built in f'n imdilate for this purpose
dilatedCellMask = conv2(cellMask,ones(5),'same');
% the convolution will have summed a bunch of neighboors together, bring it
% back to 0's and 1's
dilatedCellMask(dilatedCellMask>0)=1;
[dilatedCellContourX,dilatedCellContourY] = find(bwperim(dilatedCellMask),1,'first');
dilatedCellContour = bwtraceboundary(dilatedCellMask,[dilatedCellContourX,dilatedCellContourY],'n',8,inf,'counterclockwise');
dilatedCellContour = frdescp(dilatedCellContour);
dilatedCellContour = ifdescp(dilatedCellContour,20);
dilatedCellContour = [dilatedCellContour(:,2),dilatedCellContour(:,1)];

% % %   newImage1 = atrouswave(rawImage,scale,lowPass,7,sigmaPsf);

  newImage = bandPassFilter(rawImage,minThresh,sigmaPsf,0);

  
  maskOfNewImage = ones(size(newImage),'single');
  maskOfNewImage = newImage.*maskOfNewImage;
  maskOfNewImage = maskOfNewImage > 0;
  newRawImage = im2uint16(maskOfNewImage.*im2double(rawImage));

%identify background pixels as pixels inside the convoloved (dilated) cell,
%masked out by bandpass filtering
% % % newImageResultant = newImage-newImage1;
backgroundPixels = ~(logical(conv2(newImage1,ones(3),'same')))+~dilatedCellMask;
backgroundPixels1 = backgroundPixels(:) == 2;
backgroundPixels2 = backgroundPixels(:) == 1;
backgroundPixels = mode([backgroundPixels1 backgroundPixels2]);
backgroundPixelsValues = rawImage(backgroundPixels);


numberOfSpots = bwconncomp(newRawImage,8);

if isempty(numberOfSpots), return; end

[newRows, newColumns] = meshgrid(1:columns,1:rows);

counter = 0;
tempRawImage = bwlabel(newRawImage);
pixelNumbers = cellfun(@numel,numberOfSpots.PixelIdxList);
indexToGoodSpots = pixelNumbers > 2;
meanIndex = mean(pixelNumbers(indexToGoodSpots));
pixelNumMeanStd = meanIndex+std(pixelNumbers(indexToGoodSpots));
% % % centerLoc = regionprops(numberOfSpots,'centroid');
backgroundRawImage = mean(backgroundPixelsValues);
dd = [];
for k = 1:numberOfSpots.NumObjects

try
% % %     tempMask = zeros(size(newImage),'single');
    tempNewRawImage = k == tempRawImage;
    tempNewRawImage = im2uint16(tempNewRawImage.*im2double(rawImage));
    indexToSpots = numberOfSpots.PixelIdxList{k};
    if  pixelNumbers(k) >= pixelNumMeanStd
        [~,id] = max(newRawImage(indexToSpots));
        peakValueOfSpots = indexToSpots(id);
        %use g2d to get a position estimate
% % %         rowPosition = (rem(peakValueOfSpots-1,rows)+1);
% % %         columnPosition = ceil(peakValueOfSpots./rows);
%         positionXY = positionEstimate(image(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
% % % %         tempMask1 = ((double(newRows)-positionXY(1)).^2 + (double(newColumns)-positionXY(2)).^2).^(1/2) <= meanIndex-2;
% % % % % %         tempMask(round(rowPosition),ceil(columnPosition)) = 1;
% % % % % %         tempMask = imdilate(tempMask,circStrel);
% % % % % %         [i,j] = find(tempMask == 1);
% % % % % %         indexToMask = indexToMask(((j-columnPosition).^2 + (i-rowPosition).^2).^1/2<=meanIndex-2);
% % % 
% % % % % % %         [~,id2] = max(newRawImage(indexToSpots(id+2:end)));
% % %         peakValueOfSpots2 = indexToSpots(end-1);
% % %         %use g2d to get a position estimate
        rowPosition = (rem(peakValueOfSpots-1,rows)+1);
        columnPosition = ceil(peakValueOfSpots./rows);
        positionXY = positionEstimate(image(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
% % %         tempMask2 = ((double(newRows)-positionXY(1)).^2 + (double(newColumns)-positionXY(2)).^2).^(1/2) <= meanIndex-2;
% % %         tempMask(round(rowPosition),ceil(columnPosition)) = 1;
% % %         tempMask = imdilate(tempMask,circStrel);
% % %         tempMask = tempMask1 + tempMask2;
        rowPosition = positionXY(2);
        columnPosition = positionXY(1);
        tempMask = conv2(double(tempNewRawImage),ones(5),'same');
        tempMask = logical(tempMask);
        indexToMask = find(tempMask ==1);

        tempNewRawImage = im2uint16(tempMask.*im2double(rawImage));
    else
        [~,id] = max(newRawImage(indexToSpots));
        peakValueOfSpots = indexToSpots(id);
        %use g2d to get a position estimate
        rowPosition = (rem(peakValueOfSpots-1,rows)+1);
        columnPosition = ceil(peakValueOfSpots./rows);
        positionXY = positionEstimate(image(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
        %pxy = g2d(img(rp-1:rp+1,cp-1:cp+1)) + [cp-1,rp-1] -1;
        %peakdxy = ((rows - positionXY(2)).^2 + (columns - positionXY(1)).^2).^(1/2);
        rowPosition = positionXY(2);
        columnPosition = positionXY(1);
        tempMask = ((double(newRows)-positionXY(1)).^2 + (double(newColumns)-positionXY(2)).^2).^(1/2) <= maxRadius;
% % %         tempMask(round(rowPosition),ceil(columnPosition)) = 1;
% % %         tempMask = imdilate(tempMask,circStrel);
        indexToMask = find(tempMask ==1);
% % %         [i,j] = find(tempMask == 1);
% % %         indexToMask = indexToMask((((j-columnPosition).^2 + (i-rowPosition).^2).^1/2)<=4);
        tempNewRawImage = im2uint16(tempMask.*im2double(rawImage));

    end
    

    positionXY = positionEstimate(rawImage(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
    positionX = positionXY(1);
    positionY = positionXY(2);
    positionX1 = positionX;
    positionY1 = positionY;
    indexPeakDistanceXY = indexToMask;
    if ~inpolygon(positionX,positionY,...
            dilatedCellContour(:,1),dilatedCellContour(:,2))
        continue;
    end
  
% % %     peakDistanceXY = ((newColumns - positionY).^2 + (newRows - positionX).^2).^(1/2);
% % %     indexPeakDistanceXY = find((peakDistanceXY.*maskOfNewImage));
     heightEstimate = (max(double(rawImage(indexPeakDistanceXY)))-mean(mean(double(rawImage))));
     widthEstimate  = 1.5;
     rowPosition = (rem(indexPeakDistanceXY-1,rows)+1);
     columnPosition = ceil(indexPeakDistanceXY./rows);
   
    backgroundRawImage1 = backgroundRawImage;
    heightEstimate1 = heightEstimate;
    widthEstimate1 = widthEstimate;
    distanceXY = ((rowPosition - positionXY(2)).^2 + (columnPosition - positionXY(1)).^2).^(1/2);
catch err
    continue;
end
% % %  if params.GAU == 1
    gauss2dFitOptions = fitoptions('Method','NonlinearLeastSquares','Algorithm','Trust-Region',...
                               'Lower',[0,0,0],...
                               'Upper',[Inf,Inf,maxRadius*1.5],'MaxIter', 400,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate,positionX,positionY]);
     gauss2dFitOptions1 = fitoptions('Method','NonlinearLeastSquares',...
                               'Lower',[0,0,0,0,0,0],...
                               'Upper',[Inf,Inf,maxRadius*1.5,Inf,Inf,maxRadius*1.5],'MaxIter', 600,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate,positionX,positionY,...
                                             backgroundRawImage1,heightEstimate1,...
                                             widthEstimate1,positionX1,positionY1]);
    gauss2d = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,x,y) ...
                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions);
    gauss2dMultiple = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,x,y) ...
                    backgroundRawImage+heightEstimate*exp(-(positionX-x).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions1);
                
    if length(indexPeakDistanceXY) >= minSpotPixels
        if pixelNumMeanStd > pixelNumbers(k)
            try
                [sfit,gof] = fit([columnPosition,rowPosition],double(tempNewRawImage(indexPeakDistanceXY)),...
                                  gauss2d);
            catch
                continue;
            end
            %if sfit.widthEstimate > widthEstimate
            try
                confidenceInterval = confint(sfit);
                confidenceInterval(1:2,1:2,:,:,:) = confidenceInterval(1:2,1:2)./65535;
                confidenceInterval(5:6) = confidenceInterval(5:6)*sqrt(2);
            catch
                confidenceInterval = [];
            end
            %if confidenceInterval(6) - confidenceInterval(5) > 3.5,continue;end
            %------------------------------------------------------------------
            %if sfit.heightEstimate/65535 is less than heightCutoff(2) then do
            %not count spot as true spot and continue
            if (sfit.heightEstimate/65535) < postFitMinHeight || ...
                sfit.widthEstimate*sqrt(2) < postFitMinWidth || sfit.widthEstimate*sqrt(2) > postFitMaxWidth || ...
                gof.rsquare < postFitError || ~inpolygon(sfit.positionX,sfit.positionY,...
                dilatedCellContour(:,1),dilatedCellContour(:,2))
                continue;
            end
            counter = counter + 1;
            %------------------------------------------------------------------

            %------------------------------------
            %used for plotting if adjustmode == 1
            spot_x(counter) = sfit.positionX;
            spot_y(counter) = sfit.positionY;
            sigma(counter) = sfit.widthEstimate;
            rsquared(counter) = gof.rsquare;
            %------------------------------------
    % % %         C = centerOfMass(double(rawImage(indexPeakDistanceXY)));
    % % %         sfit.positionX = columnPosition(ceil(C(1)));
    % % %         sfit.positionY = rowPosition(ceil(C(1)));
            positionXY = positionEstimate(rawImage(sfit.positionY-1:sfit.positionY+1,sfit.positionX-1:sfit.positionX+1)) + [sfit.positionY-1,sfit.positionX-1] -1;
            positionX = positionXY(2);
            positionY = positionXY(1);
            xModelValue = cellData.box(1)+positionX-1; 
            yModelValue = cellData.box(2)+positionY-1;
            if ~isfield(cellData,'steplength')
               cellData = getextradata(cellData);
            end
            [l,d] = projectToMesh(cellData.box(1)-1+sfit.positionX,...
                             cellData.box(2)-1+sfit.positionY,cellData.mesh,cellData.steplength);
            I = 0;
            for kk = 1:size(cellData.mesh,1)-1
                pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                if inpolygon(sfit.positionX,sfit.positionY,pixelPeakX,pixelPeakY)
                    I = kk;
                    break
                end
            end
    % % %         x0 = sfit.positionX - sfit.widthEstimate/2;
    % % %         x1 = sfit.positionX + sfit.widthEstimate/2;
    % % %         y0 = sfit.positionY - sfit.widthEstimate/2;
    % % %         y1 = sfit.positionY + sfit.widthEstimate/2;
    % % %         
    % % %         Q = quad2d(sfit,x0,x1,y0,y1);
    % % %         tempWidth = sfit.widthEstimate;
    % % %         if tempWidth  >params.maxRadius, tempWidth = params.maxRadius;end

            Q = 2*abs(pi*sfit.heightEstimate*sfit.widthEstimate^2);
            spotStructure.l(counter) = l;
            spotStructure.magnitude(counter) = Q/65535;
            spotStructure.w(counter) = sfit.widthEstimate*sqrt(2);
            spotStructure.h(counter) = sfit.heightEstimate/65535;
            spotStructure.b(counter) = sfit.backgroundRawImage/65535;
            spotStructure.d(counter) = d;
            spotStructure.x(counter) = xModelValue;
            spotStructure.y(counter) = yModelValue;
            spotStructure.x1(counter) = sfit.positionX;
            spotStructure.y1(counter) = sfit.positionY;
            spotStructure.positions(counter) = I;
            spotStructure.rsquared(counter) = gof.rsquare;
            spotStructure.confidenceInterval_b_h_w_x_y{counter} = confidenceInterval;
        else
            try
                [sfit,gof] = fit([columnPosition,rowPosition],double(tempNewRawImage(indexPeakDistanceXY)),...
                                  gauss2dMultiple);
                b = [sfit.backgroundRawImage sfit.backgroundRawImage1];
                w = [sfit.widthEstimate sfit.widthEstimate1];
                Q = [2*abs(pi*sfit.heightEstimate*sfit.widthEstimate^2) 2*abs(pi*sfit.heightEstimate1*sfit.widthEstimate1^2)];
                h = [sfit.heightEstimate sfit.heightEstimate1];
                posX = [sfit.positionX sfit.positionX1];
                posY = [sfit.positionY sfit.positionY1];
            catch
                continue;
            end
            try
                confidenceInterval = confint(sfit);
                confidenceInterval(1:2,1:2,:,:,:) = confidenceInterval(1:2,1:2)./65535;
                confidenceInterval(5:6) = confidenceInterval(5:6)*sqrt(2);
            catch
                confidenceInterval = [];
            end
            %if confidenceInterval(6) - confidenceInterval(5) > 3.5,continue;end
            %------------------------------------------------------------------
            %if sfit.heightEstimate/65535 is less than heightCutoff(2) then do
            %not count spot as true spot and continue
            for jj = 1:2
                if (h(jj)/65535) < postFitMinHeight || ...
                    w(jj)*sqrt(2) < postFitMinWidth || w(jj)*sqrt(2) > postFitMaxWidth || ...
                    gof.rsquare < postFitError || ~inpolygon(posX(jj),posY(jj),...
                    dilatedCellContour(:,1),dilatedCellContour(:,2))
                continue;
                end
   
                counter = counter + 1;
                xModelValue = cellData.box(1)-1+posX(jj); 
                yModelValue = cellData.box(2)-1+posY(jj);
                if ~isfield(cellData,'steplength')
                   cellData = getextradata(cellData);
                end
                [l,d] = projectToMesh(cellData.box(1)-1+posX(jj),...
                                 cellData.box(2)-1+posY(jj),cellData.mesh,cellData.steplength); %#ok<AGROW>
                I = 0;
                for kk = 1:size(cellData.mesh,1)-1
                    pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                    pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                    if inpolygon(posX(jj),posY(jj),pixelPeakX,pixelPeakY)
                        I = kk;
                        break
                    end
                end
                spotStructure.l(counter) = l;
                spotStructure.magnitude(counter) = Q(jj)/65535;
                spotStructure.w(counter) = w(jj)*sqrt(2);
                spotStructure.h(counter) = h(jj)/65535;
                spotStructure.b(counter) = b(jj)/65535;
                spotStructure.d(counter) = d;
                spotStructure.x(counter) = xModelValue;
                spotStructure.y(counter) = yModelValue;
                spotStructure.x1(counter) = posX(jj);
                spotStructure.y1(counter) = posY(jj);
                spotStructure.positions(counter) = I;
                spotStructure.rsquared(counter) = gof.rsquare;
                spotStructure.confidenceInterval_b_h_w_x_y{counter} = confidenceInterval;  
                   
                
            end
        end
    end


end

    %--------------------------------------------------------------------------
    %sort all fields of spotStructure according to the sorted "spotStructure.l"
    %array.
    [~,index] = sort(spotStructure.l);
    spotStructure.l = reshape(spotStructure.l(index),1,[]);
    spotStructure.magnitude = reshape(spotStructure.magnitude(index),1,[]);
    spotStructure.w = reshape(spotStructure.w(index),1,[]);
    spotStructure.h = reshape(spotStructure.h(index),1,[]);
    spotStructure.b = reshape(spotStructure.b(index),1,[]);
    spotStructure.d = reshape(spotStructure.d(index),1,[]);
    spotStructure.x = reshape(spotStructure.x(index),1,[]);
    spotStructure.y = reshape(spotStructure.y(index),1,[]);
    spotStructure.positions = reshape(spotStructure.positions,1,[]);
    spotStructure.rsquared = reshape(spotStructure.rsquared,1,[]);
    spotStructure.confidenceInterval_b_h_w_x_y = reshape(spotStructure.confidenceInterval_b_h_w_x_y(index),1,[]);

%--------------------------------------------------------------------------



catch err
     disp(['Error in ' err.stack(2).file ' in line ' num2str(err.stack(2).line)]);
     disp(err.message);
     return;
end

end















