function lst = forcesplitcellSetsu(frame,celln,splitpos)
    % this function attempts to split the selected cell (it will add the
    % daughter cell to the cellList if successful, returns the numbers of
    % the two cells)
    
    global imageForce cellList cellListN p rawPhaseData se maskdx maskdy coefPCA mCell
    cellListN = cellfun(@length,cellList.meshData);
    lst = [];
    if checkparam(p,'invertimage','algorithm','erodeNum')
        disp('Splitting cells failed: one or more required parameters not provided.');
        return
    end
    if length(celln) ~= 1 || ~oufti_doesCellExist(celln, frame, cellList), return; end
    if frame>size(rawPhaseData,3), disp('Splitting cells failed: no image for this frame'); return; end
    if p.invertimage
        img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
    else
        img = rawPhaseData(:,:,frame);
    end
    imge = img2imge(img,p.erodeNum,se);%
    imge16 = img2imge16(img,p.erodeNum,se);
     if gpuDeviceCount == 1
        try
            thres = graythreshreg(gpuArray(imge),p.threshminlevel);
           [extDx,extDy,imageForce(frame)] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(maskdx),gpuArray(maskdy),p,imageForce(frame));
           extDx = gather(extDx);
           extDy = gather(extDy);
           imageForce(frame).forceX = gather(imageForce(frame).forceX);
           imageForce(frame).forceY = gather(imageForce(frame).forceY);
        catch
            thres = graythreshreg(imge,p.threshminlevel);
            [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
        end
    else
        thres = graythreshreg(imge,p.threshminlevel);
        [extDx,extDy,imageForce(frame)] = getExtForces(imge,imge16,maskdx,maskdy,p,imageForce(frame));
    end
    bgr = phasebgr(imge,thres,se,p.bgrErodeNum);
    if isempty(extDx), disp('Force splitting cells failed: unable to get energy'); return; end
    prevStruct = oufti_getCellStructure(celln, frame, cellList);
    roiBox = prevStruct.box;%
    roiImg = imcrop(imge,roiBox);%
    roiExtDx = imcrop(extDx,roiBox);
    roiExtDy = imcrop(extDy,roiBox);
    
    % Now split the cell - copied from ProcessFrameI
    if ismember(p.algorithm,[2 3 4]) && isfield(prevStruct,'mesh') && size(prevStruct.mesh,1)>1
        cellMesh = prevStruct.mesh;
        if isempty(splitpos)
            res=isDivided(cellMesh-repmat(roiBox(1:2),size(cellMesh,1),2),roiImg,0,bgr,p.sgnResize);
            if isempty(res || res<0), lst = celln; error('Cell division failed: no division at zero threshold'); end
        else
            res = splitpos;
        end
        mesh1 = flipud(cellMesh(res+1:end,:)); % daughter cell
        mesh2 = cellMesh(1:res-1,:); % mother cell
        if ismember(p.algorithm,[2 3])
            pcCell1 = splitted2model(mesh1,p,se,maskdx,maskdy);
            pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
            pcCell1 = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell1,p,false,roiBox,thres,[frame celln]);
            pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
            cCell1 = model2geom(pcCell1,p.algorithm,coefPCA,mCell);
            pcCell2 = splitted2model(mesh2,p,se,maskdx,maskdy);
            pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
            pcCell2 = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell2,p,false,roiBox,thres,[frame celln]);
            pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
            cCell2 = model2geom(pcCell2,p.algorithm,coefPCA,mCell);
        elseif p.algorithm==4
            pcCell1 = align4IM(mesh1,p);
            pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
            cCell1 = align4(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell1,p,roiBox,thres,[frame celln]);
            cCell1 = box2model(cCell1,roiBox,p.algorithm); % Corrected pcCell->cCell 2008/08/02
            pcCell2 = align4IM(mesh2,p);
            pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
            cCell2 = align4(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell2,p,roiBox,thres,[frame celln]);
            cCell2 = box2model(cCell2,roiBox,p.algorithm); % Corrected pcCell->cCell 2008/08/02
        end
        if isempty(cCell1) || isempty(cCell2), lst = celln; error('Splitting cells failed: error fitting shape'); end

        % algorithm-specific portion of constructing the cell structures
        if size(pcCell1,2)==1, model=cCell1'; else model=cCell1; end
        cellStructDaughter.model = single(model);
        if size(pcCell2,2)==1, model=cCell2'; else model=cCell2; end
        cellStructMother.model = single(model);
        
    elseif p.algorithm==1
        getmesh = isfield(prevStruct,'mesh') && size(prevStruct.mesh,1)>1;
        if getmesh
            cellMesh = double(prevStruct.mesh);
            mask = poly2mask([cellMesh(:,1);flipud(cellMesh(:,3))]-roiBox(1),[cellMesh(:,2);flipud(cellMesh(:,4))]-roiBox(2),roiBox(4)+1,roiBox(3)+1);
        else
            contour = double(prevStruct.contour);
            mask = poly2mask(contour(:,1)-roiBox(1),contour(:,2)-roiBox(2),roiBox(4)+1,roiBox(3)+1);
        end
        [mask1,mask2]=splitonereg(roiImg.*mask);
        if isempty(mask1), disp(['Splitting cells failed: unable to split ' num2str(celln)]); return; end
        
        % Get and smooth the boundary of the region
        [ii,jj]=find(bwperim(mask1),1,'first');
        pp = bwtraceboundary(mask1,[ii,jj],'n',8,inf,'counterclockwise');
        fpp = frdescp(pp);
        cCell1 = ifdescp(fpp,p.fsmooth)+1; % +1?
        cCell1 = [cCell1;cCell1(1,:)]; % make the last point the same as the first one
        cCell1 = rot90(cCell1,2);
        cCell1(:,1) = cCell1(:,1)+roiBox(1)-1;
        cCell1(:,2) = cCell1(:,2)+roiBox(2)-1;
        [ii,jj]=find(bwperim(mask2),1,'first');
        pp=bwtraceboundary(mask2,[ii,jj],'n',8,inf,'counterclockwise');
        fpp = frdescp(pp);
        cCell2 = ifdescp(fpp,p.fsmooth)+1; 
        cCell2 = [cCell2;cCell2(1,:)]; % make the last point the same as the first one
        cCell2 = rot90(cCell2,2);
        cCell2(:,1) = cCell2(:,1)+roiBox(1)-1;
        cCell2(:,2) = cCell2(:,2)+roiBox(2)-1;
        
        % algorithm-specific posrtion of constructiong the cell structures
        cellStructDaughter.contour = cCell1;
        cellStructMother.contour = cCell2;
    end
    
   % finish constructiong the cell structures (same for all algorithms)
    cellStructDaughter.algorithm = p.algorithm;
    cellStructMother.algorithm = p.algorithm;
    cellStructDaughter.birthframe = frame;
    if isfield(prevStruct,'birthframe')
        cellStructMother.birthframe = prevStruct.birthframe;
    else
        cellStructMother.birthframe = frame;
    end
    if isfield(prevStruct,'mesh') && size(prevStruct.mesh,1)>1
        mesh1 = model2mesh(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
        mesh2 = model2mesh(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
        if isempty(mesh1) || isempty(mesh2) || ((length(mesh1)==1 && mesh1==-1) || (length(mesh2)==1 && mesh2==-1))
            lst = celln;
            error('Splitting cells failed: error getting mesh');
            
        end
        cellStructDaughter.mesh = single(mesh1);
        cellStructMother.mesh = single(mesh2);
    end
    cellStructDaughter.stage = 1;
    cellStructMother.stage = 1;
    if ~isfield(prevStruct,'timelapse')
        if ismember(0,cellListN(1)==cellListN) || length(cellListN)<=1
            prevStruct.timelapse = 0;
        else
            prevStruct.timelapse = 1;
        end
    end
    cellStructDaughter.polarity = prevStruct.timelapse;
    cellStructMother.polarity = prevStruct.timelapse;
    cellStructDaughter.timelapse = prevStruct.timelapse;
    cellStructMother.timelapse = prevStruct.timelapse;
    cellStructDaughter.box = roiBox;
    cellStructMother.box = roiBox;
    %cellStructDaughter -----> daughter
    %cellStructMother -----> mother
if ~p.forceindframes && prevStruct.timelapse
    if frame>1
         daughter = getDaughterNum();
         cellStructMother.divisions = [prevStruct.divisions frame];
         cellStructDaughter.divisions = [];
         cellStructMother.birthframe = prevStruct.birthframe;
         cellStructDaughter.ancestors = [prevStruct.ancestors(prevStruct.ancestors~=celln) celln];
         cellStructMother.ancestors = prevStruct.ancestors;
         cellStructDaughter.descendants = [];
         cellStructMother.descendants = [prevStruct.descendants(prevStruct.descendants~=daughter) daughter];
         cellStructDaughter.polarity = 1;
         cellStructMother.polarity = 1;
    else % case of frame==1
         daughter = getDaughterNum();
         cellStructDaughter.divisions = [];
         cellStructMother.divisions = [];
         cellStructDaughter.birthframe = 1;
         cellStructMother.birthframe = 1;
         cellStructDaughter.ancestors = [];
         cellStructMother.ancestors = [];
         cellStructDaughter.descendants = [];
         cellStructMother.descendants = [];
         cellStructDaughter.polarity = 0; % polarity is not set when the cells on the 1st frame are splitted
         cellStructMother.polarity = 0;
    end
else
    % independent frames regime: keep the attributess of the mother
    % cell, set the attributes of the daughter cell as newly appeared
    daughter = getDaughterNum();
    cellListN = cellfun(@length,cellList.meshData);
    cellStructDaughter.divisions = [];
    cellStructMother.divisions = prevStruct.divisions;
    cellStructDaughter.ancestors = [];
    cellStructMother.ancestors = prevStruct.ancestors;
    cellStructDaughter.descendants = [];
    cellStructMother.descendants = prevStruct.descendants;
    cellStructDaughter.birthframe = frame;
    cellStructMother.birthframe = prevStruct.birthframe;
    cellStructDaughter.polarity = 0;
    cellStructMother.polarity = 0;
end
    

% Now save the data to cellList
%%%cellList.meshData{frame}{daughter} = cellStructDaughter;
%%%cellList.meshData{frame}{cell} = cellStructMother;
%%%cellList.meshData{frame}{cell}=getextradata(cellList.meshData{frame}{cell});
%%%cellList.meshData{frame}{daughter}=getextradata(cellList.meshData{frame}{daughter});
cellList = oufti_addCell(celln, frame, cellStructMother, cellList);
cellList = oufti_addCell(daughter, frame, cellStructDaughter, cellList);
lst = [celln daughter];
% % % if ~p.forceindframes && prevStruct.timelapse
% % %    updatelineage(lst,frame)
% % % end
    
% display the result message
if ~p.forceindframes && prevStruct.timelapse
        disp(['Splitting cell ' num2str(celln) ' succeeded, saved as cells ' num2str(celln) ' and ' num2str(daughter) ', marked as independent.'])
else
        disp(['Splitting cell ' num2str(celln) ' succeeded, saved as cells ' num2str(celln) ' and ' num2str(daughter) ', marked as mother & daughter.'])
end
    
end