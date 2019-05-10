function [spotStructure,dispStructure] = fitGaussians(cellData,numberOfSpots,rawImage,newRawImage,bgr,params,dilatedCellContour)


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
maxRadius       = params.fitRadius;
multGauss       = params.multGauss;
I = NaN;
 spotStructure.l                            = [];
 spotStructure.d                            = [];
 spotStructure.x                            = [];
 spotStructure.y                            = [];
 spotStructure.positions                    = [];
 spotStructure.adj_Rsquared                 = [];
 spotStructure.confidenceInterval_x_y       = [];
 dispStructure.adj_Rrsquared                = [];
 dispStructure.w                            = [];
 dispStructure.h                            = [];
% % % minThresh         = params.minThresh;
% % % intensityThrehold = params.intensityThresh;
% % % minArea           = params.minArea;
% % % maxArea           = params.maxArea;
% % % lowPass           = params.lowPass;
% % % spot_x = [];
% % % spot_y = [];
% % % sigma = [];
% % % rsquared = [];
% % % circStrel = strel('disk',11);
% % % % 
% % % % hLocalMax = vision.LocalMaximaFinder;
% % % % hLocalMax.MaximumNumLocalMaxima = 4;
% % % % hLocalMax.NeighborhoodSize = [3 3];
[rows,columns] = size(rawImage);
[newRows, newColumns] = meshgrid(1:columns,1:rows);

counter = 0;
tempRawImage = bwlabel(newRawImage);
pixelNumbers = cellfun(@numel,numberOfSpots.PixelIdxList);
indexToGoodSpots = pixelNumbers > 2;
meanIndex = mean(pixelNumbers(indexToGoodSpots));
pixelNumMeanStd = meanIndex+std(pixelNumbers(indexToGoodSpots))/2;
% % % centerLoc = regionprops(numberOfSpots,'centroid');
% % % backgroundRawImage = mean(backgroundPixelsValues);
backgroundRawImage = mean(mean(rawImage));

for k = 1:numberOfSpots.NumObjects
    if numel(numberOfSpots.PixelIdxList{k}) < params.minRegionSize
        continue;
    end
try
% % %     tempMask = zeros(size(newImage),'single');
    tempNewRawImage = k == tempRawImage;
    tempNewRawImage = im2uint16(tempNewRawImage.*im2double(rawImage));
    indexToSpots = numberOfSpots.PixelIdxList{k};
    if  pixelNumbers(k) > pixelNumMeanStd || numberOfSpots.NumObjects == 1
        [~,id] = max(rawImage(indexToSpots));
        peakValueOfSpots = indexToSpots(id);
       
% % %         %use g2d to get a position estimate
        rowPosition = (rem(peakValueOfSpots-1,rows)+1);
        columnPosition = ceil(peakValueOfSpots./rows);
        positionXY = positionEstimate(rawImage(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
% % %         tempMask2 = ((double(newRows)-positionXY(1)).^2 + (double(newColumns)-positionXY(2)).^2).^(1/2) <= meanIndex-2;
% % %         tempMask(round(rowPosition),ceil(columnPosition)) = 1;
% % %         tempMask = imdilate(tempMask,circStrel);
% % %         tempMask = tempMask1 + tempMask2;
        rowPosition = positionXY(2);
        columnPosition = positionXY(1);
        tempMask = conv2(double(tempNewRawImage),ones(5),'same');
        tempMask = logical(tempMask);
        indexToMask = find(tempMask ==1);

% % %         tempNewRawImage = im2uint16(tempMask.*im2double(rawImage));
        tempNewRawImage =rawImage(tempMask);
    else
        [~,id] = max(newRawImage(indexToSpots));
        peakValueOfSpots = indexToSpots(id);
        %use g2d to get a position estimate
        rowPosition = (rem(peakValueOfSpots-1,rows)+1);
        columnPosition = ceil(peakValueOfSpots./rows);
        positionXY = positionEstimate(rawImage(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
        %pxy = g2d(img(rp-1:rp+1,cp-1:cp+1)) + [cp-1,rp-1] -1;
        %peakdxy = ((rows - positionXY(2)).^2 + (columns - positionXY(1)).^2).^(1/2);
        rowPosition = positionXY(2);
        columnPosition = positionXY(1);
        tempMask = ((newRows-columnPosition).^2 + (newColumns-rowPosition).^2).^(1/2) <= maxRadius;
% % %         tempMask = conv2(double(tempNewRawImage),ones(3),'same');
% % %         tempMask(round(rowPosition),ceil(columnPosition)) = 1;
% % %         tempMask = imdilate(tempMask,circStrel);
% % %         tempMask = logical(tempMask);
        indexToMask = find(tempMask ==1);
% % %         [i,j] = find(tempMask == 1);
% % %         indexToMask = indexToMask((((j-columnPosition).^2 + (i-rowPosition).^2).^1/2)<=4);
% % %         tempNewRawImage = uint16(tempMask.*double(rawImage));
        tempNewRawImage =rawImage(tempMask);
% % %     hLocalMax.Threshold = mean(mean(tempNewRawImage(tempNewRawImage > 0)));

    end
    tempNewRawImage1 = uint16(tempMask.*double(rawImage));
    [yy,xx] = find(tempNewRawImage1);
    points = [xx yy];
    [d,~]  = pdist2(points,points,'euclidean','largest',1);
    maxWidthEstimate = ceil(max(d));
    indexPeakDistanceXY = indexToMask;
    positionXY = positionEstimate(rawImage(rowPosition-1:rowPosition+1,columnPosition-1:columnPosition+1)) + [columnPosition-1,rowPosition-1] -1;
    positionX = positionXY(1);
    positionY = positionXY(2);
    positionX1 = positionX;
    positionY1 = positionY;
    positionX2 = positionX;
    positionY2 = positionY;
    positionX3 = positionX;
    positionY3 = positionY;
    
% % %     w = ones(1,numel(indexPeakDistanceXY));
% % %     indexToGreaterThanMean = find(double(rawImage(indexPeakDistanceXY)) > (std(double(rawImage(indexPeakDistanceXY))) + mean(double(rawImage(indexPeakDistanceXY)))));
% % %     indexToLessThanMean    = find(double(rawImage(indexPeakDistanceXY)) < mean(double(rawImage(indexPeakDistanceXY))));
% % %     w(indexToLessThanMean) = w(indexToLessThanMean)*1;
% % %     w(indexToGreaterThanMean) = w(indexToGreaterThanMean)*mean(double(rawImage(indexPeakDistanceXY)));
    if ~inpolygon(positionX,positionY,...
            dilatedCellContour(:,1),dilatedCellContour(:,2))
        continue;
    end
  
% % %     peakDistanceXY = ((newColumns - positionY).^2 + (newRows - positionX).^2).^(1/2);
% % %     indexPeakDistanceXY = find((peakDistanceXY.*maskOfNewImage));
     heightEstimate = (max(rawImage(indexPeakDistanceXY))-mean(mean(rawImage)));
% % %      heightEstimate = (max(im2double(rawImage(indexPeakDistanceXY)))-mean(mean(im2double(rawImage))));

     widthEstimate  = 1.5;
     rowPosition = (rem(indexPeakDistanceXY-1,rows)+1);
     columnPosition = ceil(indexPeakDistanceXY./rows);
   
    backgroundRawImage1 = backgroundRawImage;
    backgroundRawImage2 = backgroundRawImage;
    backgroundRawImage3 = backgroundRawImage;
    heightEstimate1 = heightEstimate;
    widthEstimate1 = widthEstimate;
    heightEstimate2 = heightEstimate;
    widthEstimate2 = widthEstimate;
    heightEstimate3 = heightEstimate;
    widthEstimate3  = widthEstimate;
% % %     distanceXY = ((rowPosition - positionXY(2)).^2 + (columnPosition - positionXY(1)).^2).^(1/2);
catch err
    continue;
end
% % %  mask = true(size(rawImage));
% % %  bgr = mean(mean(im2double(rawImage)));
% % % spotlist = [positionY,positionX,9,heightEstimate,backgroundRawImage];
% % % spotlist2 = getSpotStats(spotlist,tempNewRawImage,mask,50,ceil(maxRadius),0.1,bgr);
% % %  if params.GAU == 1
    gauss2dFitOptions1 = fitoptions('Method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt',...
                               'Lower',[0,0,0],...
                               'Upper',[Inf,Inf,maxWidthEstimate],'MaxIter', 600,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate1,positionX,positionY]);
    gauss2dFitOptions2 = fitoptions('Method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt',...
                               'Lower',[0,0,0,-Inf,-Inf,0,0,0,-Inf,-Inf],...
                               'Upper',[Inf,Inf,maxWidthEstimate,Inf,Inf,Inf,Inf,maxWidthEstimate,Inf,Inf],'MaxIter',600,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate,positionX,positionY,...
                                             backgroundRawImage1,heightEstimate1,...
                                             widthEstimate1,positionX1,positionY1]);
                                         
    gauss2dFitOptions3 = fitoptions('Method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt',...
                               'Lower',[0,0,0,-Inf,-Inf,0,0,0,-Inf,-Inf,0,0,0,-Inf,-Inf],...
                               'Upper',[Inf,Inf,maxWidthEstimate,Inf,Inf,Inf,Inf,maxWidthEstimate,Inf,Inf,...
                                        Inf,Inf,maxWidthEstimate,Inf,Inf],'MaxIter',600,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate,positionX,positionY,...
                                             backgroundRawImage1,heightEstimate1,...
                                             widthEstimate1,positionX1,positionY1,...
                                             backgroundRawImage2,heightEstimate2,...
                                             widthEstimate2,positionX2,positionY2]);
     
    gauss2dFitOptions4 = fitoptions('Method','NonlinearLeastSquares','Algorithm','Levenberg-Marquardt',...
                               'Lower',[0,0,0,-Inf,-Inf,0,0,0,-Inf,-Inf,0,0,0,-Inf,-Inf,0,0,0,-Inf,-Inf],...
                               'Upper',[Inf,Inf,maxWidthEstimate,Inf,Inf,Inf,Inf,maxWidthEstimate,Inf,Inf,...
                                        Inf,Inf,maxWidthEstimate,Inf,Inf,Inf,Inf,maxWidthEstimate,Inf,Inf],'MaxIter',600,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate,positionX,positionY,...
                                             backgroundRawImage1,heightEstimate1,...
                                             widthEstimate1,positionX1,positionY1,...
                                             backgroundRawImage2,heightEstimate2,...
                                             widthEstimate2,positionX2,positionY2,...
                                             backgroundRawImage3,heightEstimate3,...
                                             widthEstimate3,positionX3,positionY3]);
                                         
    gauss2d1 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,x,y) ...
                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions1);
                
    gauss2d2 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,x,y) ...
                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions2);
    
    gauss2d3 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                         backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,...
                         backgroundRawImage2,heightEstimate2,widthEstimate2,positionX2,positionY2,x,y) ...
                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)) + ...
                backgroundRawImage2+heightEstimate2*exp(-(x-positionX2).^2 ...
                    /(2*widthEstimate2^2)-(y-positionY2).^2/(2*widthEstimate2^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions3);
                
    gauss2d4 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                         backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,...
                         backgroundRawImage2,heightEstimate2,widthEstimate2,positionX2,positionY2,...
                         backgroundRawImage3,heightEstimate3,widthEstimate3,positionX3,positionY3,x,y) ...      
                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)) + ...
                backgroundRawImage2+heightEstimate2*exp(-(x-positionX2).^2 ...
                    /(2*widthEstimate2^2)-(y-positionY2).^2/(2*widthEstimate2^2)) + ...
                backgroundRawImage3+heightEstimate3*exp(-(x-positionX3).^2 ...
                    /(2*widthEstimate3^2)-(y-positionY3).^2/(2*widthEstimate3^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions4);
     try
                MultipleGauss = {gauss2d1,gauss2d2,gauss2d3,gauss2d4};
     catch
     end
  try
     sfit = cell(1,4);
     gof  = cell(1,4);
     try
         if multGauss ~= 0
              for ii = 1:4
                  [sfit{ii},gof{ii}] = fit([columnPosition,rowPosition],double(tempNewRawImage),MultipleGauss{ii});

              end
         else
             for ii = 1:1
                  [sfit{ii},gof{ii}] = fit([columnPosition,rowPosition],double(tempNewRawImage),MultipleGauss{ii});

             end
         end
     catch
     end
% % %       gofTemp = cell2mat(gof);
% % %       gofTemp = cat(1,gofTemp.rsquare);
% % %       [~,maxIndex] = max(gofTemp);
      if (pixelNumbers(k) >= maxRadius^2*pi) && (multGauss == 1)
% % %           if maxIndex == 1 || maxIndex == 3 || maxIndex == 4
              try
% % %                     tempImage = imregionalmax(tempNewRawImage);
% % %                     [tempImage,num] = bwlabel(tempImage);
% % %                     num = min(num,4);
                   maxValues = findLocalMaximas(tempNewRawImage1);
                   maxValues = unique(maxValues,'rows');
% % %                     location = step(hLocalMax, tempNewRawImage);
% % %                     num = length(location);
                    num = size(maxValues,1);
                    switch num
                        case 1
                          
                        case 2  
% % %                              loc = find(tempImage > 0, 2, 'first' );
% % %                              positionY = (rem(loc(1)-1,rows)+1);
% % %                              positionX = ceil(loc(1)./rows);
% % %                              positionY1 = (rem(loc(2)-1,rows)+1);
% % %                              positionX1 = ceil(loc(2)./rows);
                             positionX = maxValues(1,1);
                             positionY = maxValues(1,2);
                             positionX1 = maxValues(2,1);
                             positionY1 = maxValues(2,2);
                             gauss2dFitOptions2.StartPoint(4) = positionX;
                             gauss2dFitOptions2.StartPoint(5) = positionY;
                             gauss2dFitOptions2.StartPoint(9) = positionX1;
                             gauss2dFitOptions2.StartPoint(10) = positionY1;
% % %                              gauss2dFitOptions2.StartPoint(2) = maxValues(1,3);
% % %                              gauss2dFitOptions2.StartPoint(7) = maxValues(2,3);
                             gauss2d2 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                            backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,x,y) ...
                                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                                    backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)),...
                                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions2);
                        case 3
% % %                              loc = find(tempImage > 0, 3, 'last' );
% % %                              positionY = (rem(loc(1)-1,rows)+1);
% % %                              positionX = ceil(loc(1)./rows);
% % %                              positionY1 = (rem(loc(2)-1,rows)+1);
% % %                              positionX1 = ceil(loc(2)./rows);
% % %                              positionY2 = (rem(loc(3)-1,rows)+1);
% % %                              positionX2 = ceil(loc(3)./rows);
                             positionX = maxValues(1,1);
                             positionY = maxValues(1,2);
                             positionX1 = maxValues(2,1);
                             positionY1 = maxValues(2,2);
                             positionX2 = maxValues(3,1);
                             positionY2 = maxValues(3,2);
                             gauss2dFitOptions3.StartPoint(4) = positionX;
                             gauss2dFitOptions3.StartPoint(5) = positionY;
                             gauss2dFitOptions3.StartPoint(9) = positionX1;
                             gauss2dFitOptions3.StartPoint(10) = positionY1;
                             gauss2dFitOptions3.StartPoint(14) = positionX2;
                             gauss2dFitOptions3.StartPoint(15) = positionY2;
% % %                              gauss2dFitOptions3.StartPoint(2) = maxValues(1,3);
% % %                              gauss2dFitOptions3.StartPoint(7) = maxValues(2,3);
% % %                              gauss2dFitOptions3.StartPoint(12) = maxValues(3,3);

                             gauss2d3 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                                 backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,...
                                                 backgroundRawImage2,heightEstimate2,widthEstimate2,positionX2,positionY2,x,y) ...
                                            backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                            /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                                        backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                                            /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)) + ...
                                        backgroundRawImage2+heightEstimate2*exp(-(x-positionX2).^2 ...
                                            /(2*widthEstimate2^2)-(y-positionY2).^2/(2*widthEstimate2^2)),...
                                            'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions3);
                             gauss2dFitOptions2.StartPoint(4) = maxValues(1,1);
                             gauss2dFitOptions2.StartPoint(5) = maxValues(1,2);
                             gauss2dFitOptions2.StartPoint(9) = maxValues(2,1);
                             gauss2dFitOptions2.StartPoint(10) = maxValues(2,2);
% % %                              gauss2dFitOptions2.StartPoint(2) = maxValues(1,3);
% % %                              gauss2dFitOptions2.StartPoint(7) = maxValues(2,3);
                             gauss2d2 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                            backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,x,y) ...
                                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                                    backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)),...
                                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions2);
                                        
                        case 4
% % %                              loc = find(tempImage > 0, 4, 'last' );
% % %                              positionY = (rem(loc(1)-1,rows)+1);
% % %                              positionX = ceil(loc(1)./rows);
% % %                              positionY1 = (rem(loc(2)-1,rows)+1);
% % %                              positionX1 = ceil(loc(2)./rows);
% % %                              positionY2 = (rem(loc(3)-1,rows)+1);
% % %                              positionX2 = ceil(loc(3)./rows);
% % %                              positionY3 = (rem(loc(4)-1,rows)+1);
% % %                              positionX3 = ceil(loc(4)./rows);
                             gauss2dFitOptions2.StartPoint(4) = maxValues(1,1);
                             gauss2dFitOptions2.StartPoint(5) = maxValues(1,2);
                             gauss2dFitOptions2.StartPoint(9) = maxValues(2,1);
                             gauss2dFitOptions2.StartPoint(10) = maxValues(2,2);
% % %                              gauss2dFitOptions2.StartPoint(2) = maxValues(1,3);
% % %                              gauss2dFitOptions2.StartPoint(7) = maxValues(2,3);
                             gauss2d2 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                            backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,x,y) ...
                                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                                    backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)),...
                                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions2);
                             positionX = maxValues(1,1);
                             positionY = maxValues(1,2);
                             positionX1 = maxValues(2,1);
                             positionY1 = maxValues(2,2);
                             positionX2 = maxValues(3,1);
                             positionY2 = maxValues(3,2);
                             positionX3 = maxValues(4,1);
                             positionY3 = maxValues(4,2);
                             gauss2dFitOptions3.StartPoint(4) = positionX;
                             gauss2dFitOptions3.StartPoint(5) = positionY;
                             gauss2dFitOptions3.StartPoint(9) = positionX1;
                             gauss2dFitOptions3.StartPoint(10) = positionY1;
                             gauss2dFitOptions3.StartPoint(14) = positionX2;
                             gauss2dFitOptions3.StartPoint(15) = positionY2;
% % %                              gauss2dFitOptions3.StartPoint(2) = maxValues(1,3);
% % %                              gauss2dFitOptions3.StartPoint(7) = maxValues(2,3);
% % %                              gauss2dFitOptions3.StartPoint(12) = maxValues(3,3);
                             gauss2d3 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                                 backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,...
                                                 backgroundRawImage2,heightEstimate2,widthEstimate2,positionX2,positionY2,x,y) ...
                                            backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                            /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                                        backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                                            /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)) + ...
                                        backgroundRawImage2+heightEstimate2*exp(-(x-positionX2).^2 ...
                                            /(2*widthEstimate2^2)-(y-positionY2).^2/(2*widthEstimate2^2)),...
                                            'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions3);
                             gauss2dFitOptions4.StartPoint(4) = positionX;
                             gauss2dFitOptions4.StartPoint(5) = positionY;
                             gauss2dFitOptions4.StartPoint(9) = positionX1;
                             gauss2dFitOptions4.StartPoint(10) = positionY1;
                             gauss2dFitOptions4.StartPoint(14) = positionX2;
                             gauss2dFitOptions4.StartPoint(15) = positionY2;
                             gauss2dFitOptions4.StartPoint(19) = positionX3;
                             gauss2dFitOptions4.StartPoint(20) = positionY3;
% % %                              gauss2dFitOptions4.StartPoint(2) = maxValues(1,3);
% % %                              gauss2dFitOptions4.StartPoint(7) = maxValues(2,3);
% % %                              gauss2dFitOptions4.StartPoint(12) = maxValues(3,3);
% % %                              gauss2dFitOptions4.StartPoint(17) = maxValues(4,3);

                             gauss2d4 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,...
                                                 backgroundRawImage1,heightEstimate1,widthEstimate1,positionX1,positionY1,...
                                                 backgroundRawImage2,heightEstimate2,widthEstimate2,positionX2,positionY2,...
                                                 backgroundRawImage3,heightEstimate3,widthEstimate3,positionX3,positionY3,x,y) ...      
                                                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)) + ...
                                                backgroundRawImage1+heightEstimate1*exp(-(x-positionX1).^2 ...
                                                    /(2*widthEstimate1^2)-(y-positionY1).^2/(2*widthEstimate1^2)) + ...
                                                backgroundRawImage2+heightEstimate2*exp(-(x-positionX2).^2 ...
                                                    /(2*widthEstimate2^2)-(y-positionY2).^2/(2*widthEstimate2^2)) + ...
                                                backgroundRawImage3+heightEstimate3*exp(-(x-positionX3).^2 ...
                                                    /(2*widthEstimate3^2)-(y-positionY3).^2/(2*widthEstimate3^2)),...
                                            'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions4);
                    end

                   MultipleGauss = {gauss2d1,gauss2d2,gauss2d3,gauss2d4};
                   sfit = cell(1,4);
                   gof  = cell(1,4);
                   for ii = 1:4
                       [sfit{ii},gof{ii}] = fit([columnPosition,rowPosition],double(tempNewRawImage),MultipleGauss{ii});

                   end
              catch
              end
      end
              if (pixelNumbers(k) <= maxRadius^2*pi) || (multGauss == 0)
                  maxIndex = 1;  
              else
                   gofTemp = cell2mat(gof(~cellfun(@isempty,gof)));
                   gofTemp = cat(1,gofTemp.adjrsquare);
% % %                    maxIndex = find(gofTemp > min(gofTemp(gofTemp>0)),1,'first');
                   [~,maxIndex] = max(gofTemp);
              end
               sfitTemp = sfit{maxIndex};
               switch maxIndex
                   case 1
                        if sfitTemp.backgroundRawImage < 0 || gof{1}.adjrsquare < 0.3
                            
                            gauss2dFitOptions1.weights = [];
                            gauss2d1 = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,x,y) ...
                                                backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                                                /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)),...
                                                'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions1);
                            [sfitTemp,gof{1}] = fit([columnPosition,rowPosition],double(tempNewRawImage1(indexPeakDistanceXY)),gauss2d1);
                            
                        end
                         if (sfitTemp.heightEstimate/65535) < postFitMinHeight || ((sfitTemp.heightEstimate/65535) > 2 ) || ...
                            abs(sfitTemp.widthEstimate)*sqrt(2) < postFitMinWidth || abs(sfitTemp.widthEstimate)*sqrt(2) > postFitMaxWidth || ...
                            gof{1}.adjrsquare < postFitError || ~inpolygon(sfitTemp.positionX,sfitTemp.positionY,...
                            dilatedCellContour(:,1),dilatedCellContour(:,2))
                            continue;
                         end
                        counter = counter + 1;
                        try
                            confidenceInterval = confint(sfitTemp);
                            confidenceInterval = confidenceInterval(:,4:5);
                        catch
                            confidenceInterval = [];
                        end

                        xModelValue = cellData.box(1)+sfitTemp.positionX-1; 
                        yModelValue = cellData.box(2)+sfitTemp.positionY-1;
                        if ~isfield(cellData,'steplength')
                           cellData = getextradata(cellData);
                        end
                        [l,d] = projectToMesh(cellData.box(1)-1+sfitTemp.positionX,...
                                         cellData.box(2)-1+sfitTemp.positionY,cellData.mesh,cellData.steplength);
                        for kk = 1:size(cellData.mesh,1)-1
                            pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                            pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                            if inpolygon(sfitTemp.positionX,sfitTemp.positionY,pixelPeakX,pixelPeakY)
                                I = kk;
                                break
                            end
                        end

                        Q = 2*abs(pi*sfitTemp.heightEstimate*sfitTemp.widthEstimate^2);
                        spotStructure.l(counter) = l;
                        dispStructure.w(counter) = sfitTemp.widthEstimate*sqrt(2);
                        dispStructure.h(counter) = sfitTemp.heightEstimate/65535;
                        spotStructure.d(counter) = d;
                        spotStructure.x(counter) = xModelValue;
                        spotStructure.y(counter) = yModelValue;
                        spotStructure.positions(counter) = I;
                        spotStructure.adj_Rsquared(counter) = gof{1}.adjrsquare;
                        spotStructure.confidenceInterval_x_y{counter} = confidenceInterval;
                   
                   case 2
                        b = [sfitTemp.backgroundRawImage sfitTemp.backgroundRawImage1];
                        w = [abs(sfitTemp.widthEstimate) abs(sfitTemp.widthEstimate1)];
                        Q = [2*abs(pi*sfitTemp.heightEstimate*sfitTemp.widthEstimate^2) 2*abs(pi*sfitTemp.heightEstimate1*sfitTemp.widthEstimate1^2)];
                        h = [sfitTemp.heightEstimate sfitTemp.heightEstimate1];
                        posX = [sfitTemp.positionX sfitTemp.positionX1];
                        posY = [sfitTemp.positionY sfitTemp.positionY1];
                        try
                            confidenceInterval = confint(sfitTemp);
                            confidenceInterval = confidenceInterval(:,4:5);
                        catch
                            confidenceInterval = [];
                        end
                        %------------------------------------------------------------------
                        %if sfit.heightEstimate/65535 is less than heightCutoff(2) then do
                        %not count spot as true spot and continue
                        for jj = 1:2
                            if (h(jj)/65535) < postFitMinHeight || ((h(jj)/65535) > 1 ) || ...
                                w(jj)*sqrt(2) < postFitMinWidth || w(jj)*sqrt(2) > postFitMaxWidth || ...
                                gof{2}.adjrsquare < postFitError || ~inpolygon(posX(jj),posY(jj),...
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

                            for kk = 1:size(cellData.mesh,1)-1
                                pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                                pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                                if inpolygon(posX(jj),posY(jj),pixelPeakX,pixelPeakY)
                                    I = kk;
                                    break
                                end
                            end
                            spotStructure.l(counter) = l;
                            dispStructure.w(counter) = w(jj)*sqrt(2);
                            dispStructure.h(counter) = h(jj)/65535;
                            spotStructure.d(counter) = d;
                            spotStructure.x(counter) = xModelValue;
                            spotStructure.y(counter) = yModelValue;
                            spotStructure.positions(counter) = I;
                            spotStructure.adj_Rsquared(counter) = gof{2}.adjrsquare;
                            spotStructure.confidenceInterval_x_y{counter} = confidenceInterval;  


                        end
                   case 3
                        b = [sfitTemp.backgroundRawImage sfitTemp.backgroundRawImage1 sfitTemp.backgroundRawImage2];
                        w = [abs(sfitTemp.widthEstimate) abs(sfitTemp.widthEstimate1) abs(sfitTemp.widthEstimate2)];
                        Q = [2*abs(pi*sfitTemp.heightEstimate*sfitTemp.widthEstimate^2)  ... 
                             2*abs(pi*sfitTemp.heightEstimate1*sfitTemp.widthEstimate1^2)...
                             2*abs(pi*sfitTemp.heightEstimate2*sfitTemp.widthEstimate2^2)];
                        h = [sfitTemp.heightEstimate sfitTemp.heightEstimate1 sfitTemp.heightEstimate2];
                        posX = [sfitTemp.positionX sfitTemp.positionX1 sfitTemp.positionX2];
                        posY = [sfitTemp.positionY sfitTemp.positionY1 sfitTemp.positionY2];
                        try
                            confidenceInterval = confint(sfitTemp);
                            confidenceInterval = confidenceInterval(:,4:5);
                        catch
                            confidenceInterval = [];
                        end
                        %------------------------------------------------------------------
                        %if sfit.heightEstimate/65535 is less than heightCutoff(2) then do
                        %not count spot as true spot and continue
                        for jj = 1:3
                            if (h(jj)/65535) < postFitMinHeight || ((h(jj)/65535) > 1 ) || ...
                                w(jj)*sqrt(2) < postFitMinWidth || w(jj)*sqrt(2) > postFitMaxWidth || ...
                                gof{3}.adjrsquare < postFitError || ~inpolygon(posX(jj),posY(jj),...
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
                            for kk = 1:size(cellData.mesh,1)-1
                                pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                                pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                                if inpolygon(posX(jj),posY(jj),pixelPeakX,pixelPeakY)
                                    I = kk;
                                    break
                                end
                            end
                            spotStructure.l(counter) = l;
                            dispStructure.w(counter) = w(jj)*sqrt(2);
                            dispStructure.h(counter) = h(jj)/65535;
                            spotStructure.d(counter) = d;
                            spotStructure.x(counter) = xModelValue;
                            spotStructure.y(counter) = yModelValue;
                            spotStructure.positions(counter) = d;
                            spotStructure.adj_Rsquared(counter) = gof{3}.adjrsquare;
                            spotStructure.confidenceInterval_x_y{counter} = confidenceInterval;  


                        end
                   case 4
                        b = [sfitTemp.backgroundRawImage sfitTemp.backgroundRawImage1 sfitTemp.backgroundRawImage2 sfitTemp.backgroundRawImage3];
                        w = [abs(sfitTemp.widthEstimate) abs(sfitTemp.widthEstimate1) abs(sfitTemp.widthEstimate2) abs(sfitTemp.widthEstimate2)];
                        Q = [2*abs(pi*sfitTemp.heightEstimate*sfitTemp.widthEstimate^2)  ... 
                             2*abs(pi*sfitTemp.heightEstimate1*sfitTemp.widthEstimate1^2)...
                             2*abs(pi*sfitTemp.heightEstimate2*sfitTemp.widthEstimate2^2)...
                             2*abs(pi*sfitTemp.heightEstimate3*sfitTemp.widthEstimate3^2)];
                        h = [sfitTemp.heightEstimate sfitTemp.heightEstimate1 sfitTemp.heightEstimate2 sfitTemp.heightEstimate3];
                        posX = [sfitTemp.positionX sfitTemp.positionX1 sfitTemp.positionX2 sfitTemp.positionX3];
                        posY = [sfitTemp.positionY sfitTemp.positionY1 sfitTemp.positionY2 sfitTemp.positionY3];
                        try
                            confidenceInterval = confint(sfitTemp);
                            confidenceInterval = confidenceInterval(:,4:5);
                        catch
                            confidenceInterval = [];
                        end
                        %------------------------------------------------------------------
                        %if sfit.heightEstimate/65535 is less than heightCutoff(2) then do
                        %not count spot as true spot and continue
                        for jj = 1:4
                            if (h(jj)/65535) < postFitMinHeight || ((h(jj)/65535) > 1 ) || ...
                                w(jj)*sqrt(2) < postFitMinWidth || w(jj)*sqrt(2) > postFitMaxWidth || ...
                                gof{4}.adjrsquare < postFitError || ~inpolygon(posX(jj),posY(jj),...
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
                            for kk = 1:size(cellData.mesh,1)-1
                                pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                                pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                                if inpolygon(posX(jj),posY(jj),pixelPeakX,pixelPeakY)
                                    I = kk;
                                    break
                                end
                            end
                            spotStructure.l(counter) = l;
                            dispStructure.w(counter) = w(jj)*sqrt(2);
                            dispStructure.h(counter) = h(jj)/65535;
                            spotStructure.d(counter) = d;
                            spotStructure.x(counter) = xModelValue;
                            spotStructure.y(counter) = yModelValue;
                            spotStructure.positions(counter) = d;
                            spotStructure.adj_Rsquared(counter) = gof{4}.adjrsquare;
                            spotStructure.confidenceInterval_x_y{counter} = confidenceInterval;  


                        end
               end
      
  catch err
      
      
      disp(err);
      
      
  end
                


end

    %--------------------------------------------------------------------------
    %sort all fields of spotStructure according to the sorted "spotStructure.l"
    %array.
    [~,index] = sort(spotStructure.l);
    spotStructure.l = reshape(spotStructure.l(index),1,[]);
    spotStructure.d = reshape(spotStructure.d(index),1,[]);
    spotStructure.x = reshape(spotStructure.x(index),1,[]);
    spotStructure.y = reshape(spotStructure.y(index),1,[]);
    spotStructure.positions = reshape(spotStructure.positions(index),1,[]);
    spotStructure.adj_Rsquared = reshape(spotStructure.adj_Rsquared(index),1,[]);
    dispStructure.adj_Rsquared  = reshape(spotStructure.adj_Rsquared(index),1,[]);
    dispStructure.w        = reshape(dispStructure.w(index),1,[]);
    dispStructure.h        = reshape(dispStructure.h(index),1,[]);
%--------------------------------------------------------------------------