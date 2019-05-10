function processFrameI(currentFrame,timeLapseValue,processRegion)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function processFrameI(currentFrame,timeLapseValue,processRegion)
%oufti.v0.3.0
%@author:  oleksii sliusarenko
%@modified: Ahmad J. Paintdakhi
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%**********Input********:
%currentFrame:  current frame # that needs to be processed.
%timeLapseValue:    value of the timelapse field in cell Structure.
%processRegion: region of image that just need to be processed.
%=========================================================================
% PURPOSE:
% This function is for processing the first frame only 
% It searches for the cells on the frame and then does refinement
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
warning('off','MATLAB:triangulation:PtsNotInTriWarnId');
global imsizes maskdx maskdy cellList  rawPhaseData se p mCell coefPCA imageForce
if imsizes(1,1) < 1600 || imsizes(1,2) < 1600
        if p.invertimage
            if currentFrame>size(rawPhaseData,3), return; end
            img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,currentFrame);
        else
            if currentFrame>size(rawPhaseData,3), return; end
            img = rawPhaseData(:,:,currentFrame);
        end
        try
            imge = img2imge(img,p.erodeNum,se);
        catch
            disp('---- Perform Segmentation First!! ----');
        end
        imge16 = img2imge16(img,p.erodeNum,se);
        imgemax = max(max(imge));

        if gpuDeviceCount == 1
            try
                thres = graythreshreg(gpuArray(imge),p.threshminlevel);
            catch
                thres = graythreshreg(imge,p.threshminlevel);
            end
        else
            thres = graythreshreg(imge,p.threshminlevel);
        end
        %find regions using the input values. 
        regions0 = getRegions(imge,thres,imge16,p);
        if gpuDeviceCount == 1
            try
                thres = graythreshreg(gpuArray(imge),p.threshminlevel);
            catch
                thres = graythreshreg(imge,p.threshminlevel);
            end
        else
            thres = graythreshreg(imge,p.threshminlevel);
        end
        bgr = phasebgr(imge,thres,se,p.bgrErodeNum);%estimated background value in pixels
        %get extrnal energy forces of extdx and extdy.
        if gpuDeviceCount == 1
            try
               [extDx,extDy,imageForce(currentFrame)] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(currentFrame));
               extDx = gather(extDx);
               extDy = gather(extDy);
               imageForce(currentFrame).forceX = gather(imageForce(currentFrame).forceX);
               imageForce(currentFrame).forceY = gather(imageForce(currentFrame).forceY);
            catch
                [extDx,extDy,imageForce(currentFrame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(currentFrame));
            end
        else
            [extDx,extDy,imageForce(currentFrame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(currentFrame));
        end
        if isempty(extDx), disp('Processing independent frame failed: unable to get energy'); return; end
        %if processRegion value is given then crop the image using processRegion
        %values and process only the cropped region.
        if ~isempty(processRegion)
            crp = regions0(processRegion(2)+(0:processRegion(4)),processRegion(1)+(0:processRegion(3)));
            regions0 = regions0*0;
            regions0(processRegion(2)+(0:processRegion(4)),processRegion(1)+(0:processRegion(3))) = crp;
            regions0 = bwlabel(regions0>0,4);
        end
        %get area and boundingbox values of the different regions.
        stat0 = regionprops(regions0,'area','boundingbox');
        reg=1;
        celln = 0;
        regmax = length(stat0);
        regold = 0;

        if regmax>numel(img)/100
            disp('Warning: Too many regions, consider increasing thresFactorM or threshminlevel.')
            disp('Some information will not be displayed ')
            regmindisp = false;
        else
            regmindisp = true;
        end
        %check if cellList is empty, if it is, then create a parse cell array for
        %the first frame of the cellList.
        if ~oufti_doesFrameExist(1, cellList)
            cellList = oufti_makeNewFrameInCellList(1,cellList);
        end
        area1CountCheck = 4;
        area1Counter = 0;
        roiMaskHistory = [];
        roiMaskHistoryCounter = 0;

        while reg<=regmax && reg<=p.maxRegNumber
            if reg>regold, repcount=0; else repcount=repcount+1; end
            if repcount>5, reg=reg+1; continue; end
            regold = reg;
            if regmindisp, disp(['processing region ' num2str(reg)]); end
            if reg>length(stat0), stat0=regionprops(regions0,'area','boundingbox'); end
            if reg>length(stat0), break; end
            statC = stat0(reg);
            % if the region is too small - discard it
            if isempty(statC.Area) || statC.Area < p.areaMin || isempty(statC.BoundingBox) || statC.Area >p.areaMax
               % regions0(regions0==reg)=0; 
               disp(['region ' num2str(reg) ' discarded, area = ' num2str(statC.Area)]); 
               reg=reg+1; 
               continue; 
            end
            % otherwise compute the properties for proper splitting
            roiBox(1:2) = ceil(max(statC.BoundingBox(1:2)-p.roiBorder,1)); % coordinates of the ROI box
            roiBox(3:4) = floor(min(statC.BoundingBox(1:2)+statC.BoundingBox(3:4)+p.roiBorder,[size(img,2) size(img,1)])-roiBox(1:2));
            roiRegs = imcrop(regions0,roiBox); % ROI with all regions labeled
            %roiMask = bwmorph(roiRegs==reg,'close'); % ROI with region #reg labeled
            roiMask = bwmorph(roiRegs==reg,'close'); 
            roiImg = imcrop(imge,roiBox);
            roiImg2 = double(imcrop(img,roiBox)); %#ok
            %roiImg = imadjust(roiImg,[0.74 0.77],[]);
            perim = bwperim(imdilate(roiMask,se));
            pmap = 1 - perim;
            f1=true;
            ind = 0;
            while f1 && ind<100
                ind = ind+1;
                pmap1 = 1 - perim + imerode(pmap,se);
                f1 = max(max(pmap1-pmap))>0;
                pmap = pmap1;
            end;
            regDmap = ((pmap+1) + 5*(1-roiImg/imgemax)).*roiMask;
            maxdmap = max(max(regDmap)); %#ok
            % if the region is of the allowed size - try to fit the model
            if (statC.Area < p.areaMax || roiMaskHistoryCounter >=1) && celln<p.maxCellNumber
                % crop the energy and forces maps to the ROI
                roiExtDx = imcrop(extDx,roiBox);
                roiExtDy = imcrop(extDy,roiBox);
                % energy and forces attracting to the mask in the ROI
                % perim = bwperim(roiMask);
                % pmap = 1 - perim;
                % f1=true;
                % while f1
                %     pmap1 = 1 - perim + imerode(pmap,se);
                %     f1 = max(max(pmap1-pmap))>0;
                %     pmap = pmap1;
                % end;
                pmapEnergy = pmap + 0.1*pmap.^2;
                pmapDx = imfilter(pmapEnergy,maskdx); % distance forces
                pmapDy = imfilter(pmapEnergy,maskdy); 
                %pmapDxyMax = max(max(max(abs(pmapDx))),max(max(abs(pmapDy))));
                pmapDxyMax = 10;
                pmapEnergy = pmapEnergy/pmapDxyMax; %#ok
                pmapDx = pmapDx/pmapDxyMax; % normalize to make the max force equal to 1
                pmapDy = pmapDy/pmapDxyMax;
                % initial cell position
                %-----------------------------------------------------------------
                %%Ahmad.P ---> might only be used for alg. 2 and 3
                if p.algorithm == 2
                    prop = regionprops(logical(roiMask),'orientation','centroid');
                    theta = prop(1).Orientation*pi/180;
                    x0 = prop(1).Centroid(1);
                    y0 = prop(1).Centroid(2);
                    %-----------------------------------------------------------------
                    % initial representation
                    % pcCell, pcCell0 - representation of the current cell as its principal components
                    pcCell0 = [theta;x0;y0;zeros(p.Nkeep+1,1)];
                elseif  p.algorithm==3
                    prop = regionprops(logical(roiMask),'orientation','centroid');
                    theta = prop(1).Orientation*pi/180;
                    x0 = prop(1).Centroid(1);
                    y0 = prop(1).Centroid(2);
                    pcCell0 = [x0;y0;theta;0;zeros(p.Nkeep+1,1)];
                end
                % Making first variant of the model
                if ismember(p.algorithm,[2 3])
                    % first approximation - to the exact shape of the selected region
                    [pcCell,fitquality] = align(roiMask,pmapDx,pmapDy,roiExtDx*0,pcCell0,p,true,roiBox,0.5,[currentFrame celln+1]);%0.5->thres
                    disp(['fitquality pre-aligning = ' num2str(fitquality)])
                    % adjustment of the model to the external energy map
                    [pcCell,fitquality] = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,false,roiBox,thres,[currentFrame celln+1]);
                elseif p.algorithm == 4
                    try
                        pcCell = align4I(roiMask,p);
                    catch 

                        disp(['mesh not created for region ' num2str(reg) ' :consider decreasing fsmooth value'])
                        reg=reg+1;
                        continue;
                    end
                    [pcCell,fitquality] = align4Manual(roiImg,roiExtDx,roiExtDy,(roiExtDx*0),pcCell,p,roiBox,thres,[currentFrame celln+1]);
        % %          [pcCell,fitquality] = alignActiveContour(roiImg,...
        % %                                                 pcCell,0.00035,0.75,...
        % %                                              3,0.55,0.0005,5,3,350,0.55,roiExtDx,roiExtDy,roiBox);
                end
                disp(['fitquality aligning = ' num2str(fitquality)])  
                % converting from box to global coordinates
                pcCell = box2model(pcCell,roiBox,p.algorithm);
                % obtaining the shape of the cell in geometrical representation
                cCell = model2geom(pcCell,p.algorithm,coefPCA,mCell);
                %try splitting
                if p.algorithm == 4, isct = 0; else isct = intersections(cCell); end
                cellarea = statC.Area;
                if ~isempty(isct) && ~isct
                    mesh = model2MeshForRefine(cCell,p.meshStep,p.meshTolerance,p.meshWidth);
                    if length(mesh)>1
                        cellarea = polyarea([mesh(:,1);flipud(mesh(:,3))],[mesh(:,2);flipud(mesh(:,4))]);
                        roiMesh = mesh - repmat(roiBox([1 2 1 2])-1,size(mesh,1),1);
                        res=isDivided(roiMesh,roiImg,p.splitThreshold,bgr,p.sgnResize);
                        if res == -1, mesh = 0; end
                    end
                end
                % checking quality and storing the cell
                if ~isempty(pcCell) && ~isct && fitquality<p.fitqualitymax && min(min(cCell))>1+p.noCellBorder &&...
                        max(cCell(:,1))<imsizes(1,2)-p.noCellBorder && ...
                        max(cCell(:,2))<imsizes(1,1)-p.noCellBorder && ...
                        length(mesh)>1 && p.areaMin<cellarea && p.areaMax>cellarea
                    resplitcount = 0;
                    % if the cell passed the quality test and it is not on the
                    % boundary of the image - store it
                    if p.split1 && res>0 % Splitting the cell
                        mesh1 = flipud(mesh(res+1:end,:)); % daughter1
                        mesh2 = mesh(1:res-1,:); % daughter2
                       if ismember(p.algorithm,[2 3])
                            pcCell1 = splitted2model(mesh1,p,se,maskdx,maskdy);
                            pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
                            pcCell1 = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell1,p,false,roiBox,thres,[currentFrame celln+1]);
                            pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
                            cCell1 = model2geom(pcCell1,p.algorithm,coefPCA,mCell);
                            pcCell2 = splitted2model(mesh2,p,se,maskdx,maskdy);
                            pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
                            pcCell2 = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell2,p,false,roiBox,thres,[currentFrame celln+2]);
                            pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
                            cCell2 = model2geom(pcCell2,p.algorithm,coefPCA,mCell);
                        else
                            pcCell1 = align4IM(mesh1,p);
                            pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
                            cCell1 = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell1,p,roiBox,thres,[currentFrame celln+1]);
                            cCell1 = box2model(cCell1,roiBox,p.algorithm); % Corrected pcCell->cCell 2008/08/02
                            pcCell2 = align4IM(mesh2,p);
                            pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
                            cCell2 = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell2,p,roiBox,thres,[currentFrame celln+2]);
                            cCell2 = box2model(cCell2,roiBox,p.algorithm); % Corrected pcCell->cCell 2008/08/02
                        end

                        mesh1 = model2MeshForRefine(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
                        mesh2 = model2MeshForRefine(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
                        cellStruct1.algorithm = p.algorithm;
                        cellStruct2.algorithm = p.algorithm;
                        cellStruct1.birthframe = currentFrame;
                        cellStruct2.birthframe = currentFrame;
                        if size(pcCell1,2)==1, model=cCell1'; else model=cCell1; end
                        cellStruct1.model = single(model);
                        if size(pcCell2,2)==1, model=cCell2'; else model=cCell2; end
                        cellStruct2.model = single(model);
                        cellStruct1.mesh = single(mesh1);
                        cellStruct2.mesh = single(mesh2);
                        [~,largerDaughter] = max([length(mesh1) length(mesh2)]);
                        if largerDaughter == 1
                            cellStruct1.polarity = 2;
                            cellStruct2.polarity = 1;
                            cellStruct2.stalk    = 0;
                            cellStruct1.stalk    = 1;
                        else   
                            cellStruct1.polarity = 1;
                            cellStruct2.polarity = 2;
                            cellStruct2.stalk    = 1;
                            cellStruct1.stalk    = 0;
                        end
                        cellStruct1.stage = 1;
                        cellStruct2.stage = 1;
                        cellStruct1.timelapse = timeLapseValue;
                        cellStruct2.timelapse = timeLapseValue;
                        cellStruct1.divisions = [];
                        cellStruct2.divisions = [];
                        cellStruct1.box = roiBox;
                        cellStruct2.box = roiBox;
                        cellStruct1.region = reg;
                        cellStruct2.region = reg;
                        cellStruct1.ancestors = [];
                        cellStruct2.ancestors = [];
                        cellStruct1.descendants = [];
                        cellStruct2.descendants = [];
                        celln = single(celln+2);
                        cellList = oufti_addCell(celln-1, currentFrame, cellStruct1, cellList);
                        cellList = oufti_addCell(celln,   currentFrame, cellStruct2, cellList);
                        disp(['fitting region ' num2str(reg) ' - passed and saved as cells ' num2str(celln-1) ' and ' num2str(celln)])
                        reg=reg+1;
                        continue;
                    end %if res > 0
                    % if the cell passed the quality test and it is not on the
                    % boundary of the image - store it
                    cellStruct.algorithm = p.algorithm;
                    cellStruct.birthframe = currentFrame;
                    if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
                    cellStruct.model = single(model);
                    cellStruct.mesh = single(model2MeshForRefine(cCell,p.meshStep,p.meshTolerance,p.meshWidth));
                    cellStruct.polarity = 1;
                    cellStruct.ancestors = [];
                    cellStruct.descendants = [];
                    cellStruct.stage = 1;
                    %cellStruct.stage = getStage(roiImg,cellStruc.model);
                    cellStruct.timelapse = timeLapseValue;
                    cellStruct.divisions = [];
                    cellStruct.box = roiBox;
                    celln = single(celln+1);
                    cellList = oufti_addCell(celln, currentFrame, cellStruct, cellList);
                    disp(['fitting region ' num2str(reg) ' - passed and saved as cell ' num2str(celln)])
                    reg=reg+1;
                    continue;
                end
                % if the cell is not on the image border OR it did not pass the
                % quality test - split it
                reason = 'unknown';
                if isempty(pcCell), reason = 'no cell found'; 
                elseif fitquality>=p.fitqualitymax, reason = 'bad fit quality'; 
                elseif min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary'; 
                elseif min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary';
                elseif max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary'; 
                elseif max(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary';
                elseif isct, reason = 'model has intersections';
                elseif length(mesh)<=1, reason = 'problem getting mesh'; 
                elseif p.areaMin>=cellarea, reason = 'cell too small'; 
                elseif p.areaMax<=cellarea, reason = 'cell too big'; 
                end
                if isempty(who('resplitcount')), resplitcount=0; end
                if (p.areaMin>cellarea) || (resplitcount>=4) % Discarding cells
                    disp(['fitting region ' num2str(reg) ' - quality check failed - ' reason])
                    reg=reg+1;
                    resplitcount = 0;
                    continue;
                elseif isfield(p,'splitbndcells') && ~p.splitbndcells && ...
                       (min(cCell(:,1))<=1+p.noCellBorder || min(cCell(:,2))<=1+p.noCellBorder || ...
                       max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder || max(cCell(:,2))>=imsizes(1,1)-p.noCellBorder)
                    disp(['fitting region ' num2str(reg) ' - ' reason ' - splitting not allowed'])
                    reg=reg+1;
                    resplitcount = 0;
                    continue;
                else
                    resplitcount = resplitcount+1;
                    disp(['fitting region ' num2str(reg) ' - quality check failed - try resplitting (' num2str(resplitcount) ')'])
                end
            end

            if ~p.splitregions % do not split, just discard
                reg=reg+1;
                disp(['region ' num2str(reg) ' discarded - splitting not allowed'])
                continue;
            end

            % If the area is too large or if the adjustment failed - splitting the image

        %    regWshed = roiMask.*watershed(max(max(regDmap))-regDmap,4);
        %     roiLabeled = roiMask;
        %     for i=1:maxdmap
        %         %roiLabeled = bwlabel(imerode(roiLabeled,se));
        %         roiLabeled = roiLabeled.*(regDmap>i);
        %         nsreg = max(max(roiLabeled));
        %         if nsreg<=1, continue; end
        %         if nsreg>=2, break; end
        %     end
        %     [yL,xL]=ind2sub(roiBox([4 3])+1,find(roiLabeled==1,1));
        %     roiLabeled = ~((regWshed==0).*(roiLabeled~=1));
        %     roiLabeled = bwselect(roiLabeled,xL,yL,4)==1;
        %     roiLabeled = imdilate(roiLabeled,se).*roiMask;
        %     
        %     statL=regionprops(bwlabel(roiLabeled,8),'area');
        %     roiResidual = roiMask.*~roiLabeled;
        %     statM=regionprops(bwlabel(roiResidual,8),'area');

            [roiLabeled,roiResidual] = splitonereg(roiMask.*roiImg,roiMaskHistory,roiMaskHistoryCounter,p);
            try
                if min(cCell(:,1))<=1+p.noCellBorder || min(cCell(:,2))<=1+p.noCellBorder ...
                        ||max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder || max(cCell(:,2))>=imsizes(1,2)-p.noCellBorder 
                    disp('cell close to boundary');
                    reg = reg+1;continue;
                end
            catch
            end
            if isempty(roiLabeled), reg=reg+1; disp(['region ' num2str(reg) ' discarded - unable to split (1)']); continue; end
            statL=regionprops(logical(roiLabeled),'area');
            statM=regionprops(logical(roiResidual),'area');
            if isempty(statL), area1 = -1; 
            elseif statL(1).Area<p.areaMin, area1 = 0;
            elseif statL(1).Area<p.areaMax, area1 = 1;
            else area1 = 2;
            end
            if isempty(statM), area2 = -1;
            elseif statM(1).Area<p.areaMin, area2 = 0;
            elseif statM(1).Area<p.areaMax, area2 = 1;
            else area2 = 2;
            end
        %     if i==maxdmap, area1=0; area2=0; end
            if area1==-1 && area2==-1
                % roiRegs = roiRegs.*(~roiMask);
                reg=reg+1;
                disp(['region ' num2str(reg) ' discarded - unable to split (2)'])
                continue;
            end    
            if area1>=1 && area2>=1
                regmax = regmax+1;
               tempRoiResidual = roiResidual;
               tempRoiResidualIndex = find(roiResidual > 0);
               tempRoiResidualValues = roiResidual(tempRoiResidualIndex) + regmax;
               tempRoiResidual(tempRoiResidualIndex) = tempRoiResidualValues;

               roiRegs = roiRegs.*(~roiMask) + reg*roiLabeled + tempRoiResidual;
               roiMask = roiLabeled;
                disp(['region ' num2str(reg) ' splitted and the number of regions increased - return for test'])
            elseif area1==0 && area2>=1
                roiRegs = roiRegs.*(~roiMask) + reg*roiResidual;
                roiMask = roiResidual;
                area1 = area2;
            elseif area1==1
                roiMaskHistory{1} = roiMask;
                area1Counter = area1Counter + 1;
                roiRegs = roiRegs.*(~roiMask) + reg*roiLabeled;
                roiMaskHistoryCounter = roiMaskHistoryCounter +1;
                roiMaskHistory{roiMaskHistoryCounter} = roiMask;%#ok<AGROW>
                roiMask = roiLabeled;
                disp(['region ' num2str(reg) ' splitted - return for test'])
                if length(roiMaskHistory) == 4, roiMaskHistoryCounter = 0; roiMaskHistory = []; end
                if area1Counter == area1CountCheck
                    area1Counter = 0;
                    continue;
                end  
            end
            if area1==0
                roiRegs = roiRegs.*(~roiMask);
                reg=reg+1;
                disp(['region ' num2str(reg) ' discarded'])
            end
        % % %     if area1>0
        % % %         statF = regionprops(logical(roiRegs==reg),'Area');
        % % %         stat0(reg).Area=statF(1).Area;
        % % %     end
            if max(roiResidual(:)) >= 1
                tempVal = union(roiResidual(:)-roiLabeled(:),roiResidual(:)-roiLabeled(:));
                tempVal = tempVal(tempVal>0);
                for ii = 1:length(tempVal)
                    statF = regionprops(logical(roiResidual == tempVal(ii)),'Area');
                    if ~isempty(statF)
                        stat0(tempVal(ii)+regmax).Area = statF(1).Area;
                        stat0(tempVal(ii)+regmax).BoundingBox = stat0(reg).BoundingBox;
                    end
                end
                regmax = length(stat0);
            end
            regions0(roiBox(2):roiBox(2)+roiBox(4),roiBox(1):roiBox(1)+roiBox(3)) = roiRegs;
            continue;
        end
       
elseif imsizes(1,1) >= 1600 || imsizes(1,2) >= 1600
    frame = currentFrame;
    disp(['Processing Frame ' num2str(frame)]);
    if p.invertimage
        if currentFrame>size(rawPhaseData,3), return; end
        img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,currentFrame);
    else
        if currentFrame>size(rawPhaseData,3), return; end
        img = rawPhaseData(:,:,currentFrame);
    end
    allMap = false(size(img));
    ss = [0 1 0; 1 1 1; 0 1 0];

    try
        imge = img2imge(img,p.erodeNum,se);
    catch
        disp('---- Perform Segmentation First!! ----');
    end
    imge16 = img2imge16(img,p.erodeNum,se);
    imgemax = max(max(imge));
    if gpuDeviceCount == 1
        try
            thres = graythreshreg(gpuArray(imge),p.threshminlevel);
        catch
            thres = graythreshreg(imge,p.threshminlevel);
        end
    else
        thres = graythreshreg(imge,p.threshminlevel);
    end
    %find regions using the input values. 
    regions0 = getRegions(imge,thres,imge16,p);
    if gpuDeviceCount == 1
        try
            thres = graythreshreg(gpuArray(imge),p.threshminlevel);
        catch
            thres = graythreshreg(imge,p.threshminlevel);
        end
    else
        thres = graythreshreg(imge,p.threshminlevel);
    end
    bgr = phasebgr(imge,thres,se,p.bgrErodeNum);%estimated background value in pixels
    %get extrnal energy forces of extdx and extdy.
    if gpuDeviceCount == 1
        try
           [extDx,extDy,imageForce(currentFrame)] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(currentFrame));
           extDx = gather(extDx);
           extDy = gather(extDy);
           imageForce(currentFrame).forceX = gather(imageForce(currentFrame).forceX);
           imageForce(currentFrame).forceY = gather(imageForce(currentFrame).forceY);
        catch
            [extDx,extDy,imageForce(currentFrame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(currentFrame));
        end
    else
        [extDx,extDy,imageForce(currentFrame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(currentFrame));
    end
    if isempty(extDx), disp('Processing independent frame failed: unable to get energy'); return; end
    %if processRegion value is given then crop the image using processRegion
    %values and process only the cropped region.
    if ~isempty(processRegion)
        crp = regions0(processRegion(2)+(0:processRegion(4)),processRegion(1)+(0:processRegion(3)));
        regions0 = regions0*0;
        regions0(processRegion(2)+(0:processRegion(4)),processRegion(1)+(0:processRegion(3))) = crp;
        regions0 = bwlabel(regions0>0,4);
    end
    %get area and boundingbox values of the different regions.
    stat0 = regionprops(regions0,'area','boundingbox');
    reg=1;
    celln = 0;
    regmax = length(stat0);
    regold = 0;

    if regmax>numel(img)/100
        disp('Warning: Too many regions, consider increasing thresFactorM or threshminlevel.')
        disp('Some information will not be displayed ')
        regmindisp = false;
    else
        regmindisp = true;
    end
    %check if cellList is empty, if it is, then create a parse cell array for
    %the first frame of the cellList.
    if ~oufti_doesFrameExist(1, cellList)
        cellList = oufti_makeNewFrameInCellList(1,cellList);
    end
    area1CountCheck = 4;
    area1Counter = 0;
    roiMaskHistory = [];
    roiMaskHistoryCounter = 0;

    while reg<=regmax && reg<=p.maxRegNumber
        if reg>regold, repcount=0; else repcount=repcount+1; end
        if repcount>5, reg=reg+1; continue; end
        regold = reg;
        %if regmindisp, disp(['processing region ' num2str(reg)]); end
        if reg>length(stat0), stat0=regionprops(regions0,'area','boundingbox'); end
        if reg>length(stat0), break; end
        statC = stat0(reg);
        % if the region is too small - discard it
        if isempty(statC.Area) || statC.Area < p.areaMin || isempty(statC.BoundingBox)
           % regions0(regions0==reg)=0; 
           if regmindisp, disp(['region ' num2str(reg) ' discarded, area = ' num2str(statC.Area)]); end
           reg=reg+1; 
           continue; 
        end
        % otherwise compute the properties for proper splitting
        roiBox(1:2) = ceil(max(statC.BoundingBox(1:2)-p.roiBorder,1)); % coordinates of the ROI box
        roiBox(3:4) = floor(min(statC.BoundingBox(1:2)+statC.BoundingBox(3:4)+p.roiBorder,[size(img,2) size(img,1)])-roiBox(1:2));
        roiRegs = imcrop(regions0,roiBox); % ROI with all regions labeled
        %roiMask = bwmorph(roiRegs==reg,'close'); % ROI with region #reg labeled
        roiMask = bwmorph(roiRegs==reg,'close'); 
        roiImg = imcrop(imge,roiBox);
        roiImg2 = double(imcrop(img,roiBox)); %#ok
        %roiImg = imadjust(roiImg,[0.74 0.77],[]);
       
        % if the region is of the allowed size - try to fit the model
        if (statC.Area < p.areaMax || roiMaskHistoryCounter >=1) && celln<p.maxCellNumber

            % initial cell position
            %-----------------------------------------------------------------
            %%Ahmad.P ---> might only be used for alg. 2 and 3
            if p.algorithm == 2
                prop = regionprops(logical(roiMask),'orientation','centroid');
                theta = prop(1).Orientation*pi/180;
                x0 = prop(1).Centroid(1);
                y0 = prop(1).Centroid(2);
                %-----------------------------------------------------------------
                % initial representation
                % pcCell, pcCell0 - representation of the current cell as its principal components
                pcCell0 = [theta;x0;y0;zeros(p.Nkeep+1,1)];
            elseif  p.algorithm==3
                prop = regionprops(logical(roiMask),'orientation','centroid');
                theta = prop(1).Orientation*pi/180;
                x0 = prop(1).Centroid(1);
                y0 = prop(1).Centroid(2);
                pcCell0 = [x0;y0;theta;0;zeros(p.Nkeep+1,1)];
            end
            % Making first variant of the model
            if ismember(p.algorithm,[2 3])
                 perim = bwperim(imdilate(roiMask,se));
                pmap = 1 - perim;
                f1=true;
                ind = 0;
                while f1 && ind<100
                    ind = ind+1;
                    pmap1 = 1 - perim + imerode(pmap,se);
                    f1 = max(max(pmap1-pmap))>0;
                    pmap = pmap1;
                end;
                regDmap = ((pmap+1) + 5*(1-roiImg/imgemax)).*roiMask;
                maxdmap = max(max(regDmap)); %#ok
                 % crop the energy and forces maps to the ROI
                roiExtDx = imcrop(extDx,roiBox);
                roiExtDy = imcrop(extDy,roiBox);
                % energy and forces attracting to the mask in the ROI
                % perim = bwperim(roiMask);
                % pmap = 1 - perim;
                % f1=true;
                % while f1
                %     pmap1 = 1 - perim + imerode(pmap,se);
                %     f1 = max(max(pmap1-pmap))>0;
                %     pmap = pmap1;
                % end;
                pmapEnergy = pmap + 0.1*pmap.^2;
                pmapDx = imfilter(pmapEnergy,maskdx); % distance forces
                pmapDy = imfilter(pmapEnergy,maskdy); 
                %pmapDxyMax = max(max(max(abs(pmapDx))),max(max(abs(pmapDy))));
                pmapDxyMax = 10;
                pmapEnergy = pmapEnergy/pmapDxyMax; %#ok
                pmapDx = pmapDx/pmapDxyMax; % normalize to make the max force equal to 1
                pmapDy = pmapDy/pmapDxyMax;
                % first approximation - to the exact shape of the selected region
                [pcCell,fitquality] = align(roiMask,pmapDx,pmapDy,roiExtDx*0,pcCell0,p,true,roiBox,0.5,[currentFrame celln+1]);%0.5->thres
                disp(['fitquality pre-aligning = ' num2str(fitquality)])
                % adjustment of the model to the external energy map
                [pcCell,~] = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,false,roiBox,thres,[currentFrame celln+1]);
            elseif p.algorithm == 4
                try
                    pcCell = align4Initial(roiMask,p);
                catch 

                    disp(['mesh not created for region ' num2str(reg) ' :consider decreasing fsmooth value'])
                    reg=reg+1;
                    continue;
                end
            end
            pcCell1 = pcCell;
            % converting from box to global coordinates
            pcCell = box2model(pcCell,roiBox,p.algorithm);
            % obtaining the shape of the cell in geometrical representation
             cCell = model2geom(pcCell,p.algorithm,coefPCA,mCell);
            %try splitting
            if p.algorithm == 4, isct = 0; else isct = intersections(cCell); end
            cellarea = statC.Area;

            % checking quality and storing the cell
            if ~isempty(pcCell) && ~isct && min(min(cCell))>1+p.noCellBorder &&...
                    max(cCell(:,1))<imsizes(1,2)-p.noCellBorder && ...
                    max(cCell(:,2))<imsizes(1,1)-p.noCellBorder && p.areaMin<cellarea && p.areaMax>cellarea
                resplitcount = 0;
                % if the cell passed the quality test and it is not on the
                % boundary of the image - store it

                % if the cell passed the quality test and it is not on the
                % boundary of the image - store it
                cellStruct.algorithm = p.algorithm;
                cellStruct.birthframe = currentFrame;
                if size(pcCell,2)==1, model=pcCell1'; else model=pcCell1; end
                cellStruct.model = model;
                cellStruct.polarity = 1;
                cellStruct.ancestors = [];
                cellStruct.descendants = [];
                cellStruct.stage = 1;
                %cellStruct.stage = getStage(roiImg,cellStruc.model);
                cellStruct.timelapse = timeLapseValue;
                cellStruct.divisions = [];
                cellStruct.box = roiBox;
                celln = single(celln+1);
                cellList = oufti_addCell(celln, currentFrame, cellStruct, cellList);
                %tic;sampled_outline = sampleOutline(pcCell);
                allMap = allMap | poly2mask(pcCell(:,1),pcCell(:,2),size(allMap,1),size(allMap,2));
                %disp(['fitting region ' num2str(reg) ' - passed and saved as cell ' num2str(celln)])
                reg=reg+1;
                continue;
            end
            % if the cell is not on the image border OR it did not pass the
            % quality test - split it
            reason = 'unknown';
            if isempty(pcCell), reason = 'no cell found'; 
            elseif min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary'; 
            elseif min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary';
            elseif max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary'; 
            elseif max(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary';
            elseif isct, reason = 'model has intersections';
            elseif p.areaMin>=cellarea, reason = 'cell too small'; 
            elseif p.areaMax<=cellarea, reason = 'cell too big'; 
            end
            if isempty(who('resplitcount')), resplitcount=0; end
            if (p.areaMin>cellarea) || (resplitcount>=4) % Discarding cells
                disp(['fitting region ' num2str(reg) ' - quality check failed - ' reason])
                reg=reg+1;
                resplitcount = 0;
                continue;
            elseif isfield(p,'splitbndcells') && ~p.splitbndcells && ...
                   (min(cCell(:,1))<=1+p.noCellBorder || min(cCell(:,2))<=1+p.noCellBorder || ...
                   max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder || max(cCell(:,2))>=imsizes(1,1)-p.noCellBorder)
                disp(['fitting region ' num2str(reg) ' - ' reason ' - splitting not allowed'])
                reg=reg+1;
                resplitcount = 0;
                continue;
            else
                resplitcount = resplitcount+1;
                disp(['fitting region ' num2str(reg) ' - quality check failed - try resplitting (' num2str(resplitcount) ')'])
            end
        end

        if ~p.splitregions % do not split, just discard
            reg=reg+1;
            disp(['region ' num2str(reg) ' discarded - splitting not allowed'])
            continue;
        end

        % If the area is too large or if the adjustment failed - splitting the image

    %    regWshed = roiMask.*watershed(max(max(regDmap))-regDmap,4);
    %     roiLabeled = roiMask;
    %     for i=1:maxdmap
    %         %roiLabeled = bwlabel(imerode(roiLabeled,se));
    %         roiLabeled = roiLabeled.*(regDmap>i);
    %         nsreg = max(max(roiLabeled));
    %         if nsreg<=1, continue; end
    %         if nsreg>=2, break; end
    %     end
    %     [yL,xL]=ind2sub(roiBox([4 3])+1,find(roiLabeled==1,1));
    %     roiLabeled = ~((regWshed==0).*(roiLabeled~=1));
    %     roiLabeled = bwselect(roiLabeled,xL,yL,4)==1;
    %     roiLabeled = imdilate(roiLabeled,se).*roiMask;
    %     
    %     statL=regionprops(bwlabel(roiLabeled,8),'area');
    %     roiResidual = roiMask.*~roiLabeled;
    %     statM=regionprops(bwlabel(roiResidual,8),'area');

        [roiLabeled,roiResidual] = splitonereg(roiMask.*roiImg,roiMaskHistory,roiMaskHistoryCounter,p);
       try
                if min(cCell(:,1))<=1+p.noCellBorder || min(cCell(:,2))<=1+p.noCellBorder ...
                        ||max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder || max(cCell(:,2))>=imsizes(1,2)-p.noCellBorder 
                    disp('cell close to boundary');
                    reg = reg+1;continue;
                end
            catch
        end

        if isempty(roiLabeled), reg=reg+1; disp(['region ' num2str(reg) ' discarded - unable to split (1)']); continue; end
        statL=regionprops(logical(roiLabeled),'area');
        statM=regionprops(logical(roiResidual),'area');
        if isempty(statL), area1 = -1; 
        elseif statL(1).Area<p.areaMin, area1 = 0;
        elseif statL(1).Area<p.areaMax, area1 = 1;
        else area1 = 2;
        end
        if isempty(statM), area2 = -1;
        elseif statM(1).Area<p.areaMin, area2 = 0;
        elseif statM(1).Area<p.areaMax, area2 = 1;
        else area2 = 2;
        end
    %     if i==maxdmap, area1=0; area2=0; end
        if area1==-1 && area2==-1
            % roiRegs = roiRegs.*(~roiMask);
            reg=reg+1;
            disp(['region ' num2str(reg) ' discarded - unable to split (2)'])
            continue;
        end    
        if area1>=1 && area2>=1
            regmax = regmax+1;
           tempRoiResidual = roiResidual;
           tempRoiResidualIndex = find(roiResidual > 0);
           tempRoiResidualValues = roiResidual(tempRoiResidualIndex) + regmax;
           tempRoiResidual(tempRoiResidualIndex) = tempRoiResidualValues;

           roiRegs = roiRegs.*(~roiMask) + reg*roiLabeled + tempRoiResidual;
           roiMask = roiLabeled;
            disp(['region ' num2str(reg) ' splitted and the number of regions increased - return for test'])
        elseif area1==0 && area2>=1
            roiRegs = roiRegs.*(~roiMask) + reg*roiResidual;
            roiMask = roiResidual;
            area1 = area2;
        elseif area1==1
            roiMaskHistory{1} = roiMask;
            area1Counter = area1Counter + 1;
            roiRegs = roiRegs.*(~roiMask) + reg*roiLabeled;
            roiMaskHistoryCounter = roiMaskHistoryCounter +1;
            roiMaskHistory{roiMaskHistoryCounter} = roiMask;%#ok<AGROW>
            roiMask = roiLabeled;
            disp(['region ' num2str(reg) ' splitted - return for test'])
            if length(roiMaskHistory) == 4, roiMaskHistoryCounter = 0; roiMaskHistory = []; end
            if area1Counter == area1CountCheck
                area1Counter = 0;
                continue;
            end  
        end
        if area1==0
            roiRegs = roiRegs.*(~roiMask);
            reg=reg+1;
            disp(['region ' num2str(reg) ' discarded'])
        end
    % % %     if area1>0
    % % %         statF = regionprops(logical(roiRegs==reg),'Area');
    % % %         stat0(reg).Area=statF(1).Area;
    % % %     end
        if max(roiResidual(:)) >= 1
            tempVal = union(roiResidual(:)-roiLabeled(:),roiResidual(:)-roiLabeled(:));
            tempVal = tempVal(tempVal>0);
            for ii = 1:length(tempVal)
                statF = regionprops(logical(roiResidual == tempVal(ii)),'Area');
                if ~isempty(statF)
                    stat0(tempVal(ii)+regmax).Area = statF(1).Area;
                    stat0(tempVal(ii)+regmax).BoundingBox = stat0(reg).BoundingBox;
                end
            end
            regmax = length(stat0);
        end
        regions0(roiBox(2):roiBox(2)+roiBox(4),roiBox(1):roiBox(1)+roiBox(3)) = roiRegs;
        continue;
    end
    [~,proccells] = oufti_getFrame(frame,cellList);
    allMap = imerode(allMap,ss);
    processCellsForFitting(frame, proccells,imge,thres,extDx,extDy,allMap,timeLapseValue);     
    
end % processFrameI function









