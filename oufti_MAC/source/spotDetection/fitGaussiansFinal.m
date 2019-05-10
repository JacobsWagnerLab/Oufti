function spotStructure = fitGaussiansFinal(cellData,spotStructure,rawImage,params,dilatedCellContour)

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

minSpotPixels     = params.minSpotPixels; %Minimum number of pixels a spot must have in order to attempt fitting
maxRadius       = params.maxRadius;
spot_x = [];
spot_y = [];
sigma = [];
rsquared = [];

[rows,columns] = size(rawImage);
[newRows, newColumns] = meshgrid(1:columns,1:rows);

counter = 0;

for k = 1:numel(numel(spotStructure.x))

backgroundRawImage = spotStructure.b(k);
try
tempMask = ((double(newRows)-spotStructure.x1(k)).^2 + (double(newColumns)-spotStructure.y1(k)).^2).^(1/2) <= maxRadius;

indexToMask = find(tempMask ==1);

tempNewRawImage = im2uint16(tempMask.*im2double(rawImage));

indexPeakDistanceXY = indexToMask;
  
% % %     peakDistanceXY = ((newColumns - positionY).^2 + (newRows - positionX).^2).^(1/2);
% % %     indexPeakDistanceXY = find((peakDistanceXY.*maskOfNewImage));
     heightEstimate = spotStructure.h(k);
     widthEstimate  = spotStructure.w(k);
     rowPosition = (rem(indexPeakDistanceXY-1,rows)+1);
     columnPosition = ceil(indexPeakDistanceXY./rows);
     positionX = spotStructure.x1(k);
     positionY = spotStructure.y1(k);
catch err
    continue;
end
% % %  if params.GAU == 1
    gauss2dFitOptions = fitoptions('Method','NonlinearLeastSquares','Algorithm','Trust-Region',...
                               'Lower',[0,0,0.1],...
                               'Upper',[Inf,Inf,widthEstimate*2],'MaxIter', 400,...
                               'Startpoint',[backgroundRawImage,heightEstimate,...
                                             widthEstimate,positionX,positionY]);
     
    gauss2d = fittype(@(backgroundRawImage,heightEstimate,widthEstimate,positionX,positionY,x,y) ...
                    backgroundRawImage+heightEstimate*exp(-(x-positionX).^2 ...
                    /(2*widthEstimate^2)-(y-positionY).^2/(2*widthEstimate^2)),...
                    'independent', {'x', 'y'},'dependent', 'z','options',gauss2dFitOptions);
    
                
   
    
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

            xModelValue = cellData.box(1)+sfit.positionX-1; 
            yModelValue = cellData.box(2)+sfit.positionY-1;
% % %             if ~isfield(cellData,'steplength')
% % %                cellData = getextradata(cellData);
% % %             end
% % %             [l,d] = projectToMesh(cellData.box(1)-1+sfit.positionX,...
% % %                              cellData.box(2)-1+sfit.positionY,cellData.mesh,cellData.steplength);
% % %             I = 0;
            l = 1;
            d = 1;
            
            for kk = 1:size(cellData.mesh,1)-1
                pixelPeakX = [cellData.mesh(kk,[1 3]) cellData.mesh(kk+1,[3 1])] - cellData.box(1)+1;
                pixelPeakY = [cellData.mesh(kk,[2 4]) cellData.mesh(kk+1,[4 2])] - cellData.box(2)+1;
                if inpolygon(sfit.positionX,sfit.positionY,pixelPeakX,pixelPeakY)
                    I = kk;
                    break
                end
            end

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