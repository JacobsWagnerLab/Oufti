function [lst,cellList] = forcesplitcell(frame,celln,splitpos,cellList)
    % this function attempts to split the selected cell (it will add the
    % daughter cell to the cellList if successful, returns the numbers of
    % the two cells)
    
   global imageForce cellListN p rawPhaseData se maskdx maskdy coefPCA mCell
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
    cellStructure = oufti_getCellStructure(celln, frame, cellList);
    roiBox = cellStructure.box;%
    roiImg = imcrop(imge,roiBox);%
    roiExtDx = imcrop(extDx,roiBox);
    roiExtDy = imcrop(extDy,roiBox);
    
    % Now split the cell - copied from ProcessFrameI
    if ismember(p.algorithm,[2 3 4]) && isfield(cellStructure,'mesh') && size(cellStructure.mesh,1)>1
        mesh = cellStructure.mesh;
        if isempty(splitpos)
            res=isDivided(mesh-repmat(roiBox(1:2),size(mesh,1),2),roiImg,0,bgr,p.sgnResize);
            if isempty(res || res<0), lst = celln; disp('Cell division failed: decrease splitThreshold value in parameter window'); return; end
        else
            res = splitpos;
        end
        mesh1 = flipud(mesh(res+1:end,:)); % daughter cell
        mesh2 = mesh(1:res-1,:); % mother cell
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
            cCell1 = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell1,p,roiBox,thres,[frame celln]);
            cCell1 = box2model(cCell1,roiBox,p.algorithm); % Corrected pcCell->cCell 2008/08/02
            pcCell2 = align4IM(mesh2,p);
            pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
            cCell2 = align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell2,p,roiBox,thres,[frame celln]);
            cCell2 = box2model(cCell2,roiBox,p.algorithm); % Corrected pcCell->cCell 2008/08/02
        end
        if isempty(cCell1) || isempty(cCell2), lst = celln; disp('Splitting cells failed: error fitting shape'); return; end

        % algorithm-specific portion of constructing the cell structures
        if size(pcCell1,2)==1, model=cCell1'; else model=cCell1; end
        cellStructDaughter1.model = single(model);
        if size(pcCell2,2)==1, model=cCell2'; else model=cCell2; end
        cellStructDaughter2.model = single(model);
        
    elseif p.algorithm==1
        getmesh = isfield(cellStructure,'mesh') && size(cellStructure.mesh,1)>1;
        if getmesh
            mesh = cellStructure.mesh;
            if isempty(splitpos)
                res=isDivided(mesh-repmat(roiBox(1:2),size(mesh,1),2),roiImg,0,bgr,p.sgnResize);
                if isempty(res) || res<0 || res == 0, lst = celln; disp('Cell division failed: decrease splitThreshold value in parameter window'); return; end
            else
                res = splitpos;
            end
            mesh1 = flipud(mesh(res+1:end,:)); % daughter cell
            cCell1 = [mesh1(:,1:2);flipud(mesh1(:,3:4))];
            mesh2 = mesh(1:res-1,:); % mother cell
            cCell2 = [mesh2(:,1:2);flipud(mesh2(:,3:4))];
            cellStructDaughter1.model = cCell1;
            cellStructDaughter2.model = cCell2;
        else
            model = double(cellStructure.model);
            mask = poly2mask(model(:,1)-roiBox(1),model(:,2)-roiBox(2),roiBox(4)+1,roiBox(3)+1);
            [mask1,mask2]=splitonereg(roiImg.*mask,[],1,p);
            if isempty(mask2), disp(['Splitting cells failed: unable to split ' num2str(celln)]); return; end
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
            cellStructDaughter1.model = cCell1;
            cellStructDaughter2.model = cCell2;
            cellStructDaughter1.mesh = model2MeshForRefine(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
            cellStructDaughter2.mesh = model2MeshForRefine(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
        end
    elseif p.algorithm == 4 && isfield(cellStructure,'model')
        try
            model = double(cellStructure.model);
            mask = poly2mask(model(:,1)-roiBox(1),model(:,2)-roiBox(2),roiBox(4)+1,roiBox(3)+1);
            [mask1,mask2]=splitonereg(roiImg.*mask,[],1,p);
            if isempty(mask2), disp(['Splitting cells failed: unable to split ' num2str(celln)]); return; end
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
            cellStructDaughter1.model = cCell1;
            cellStructDaughter2.model = cCell2;
            cellStructDaughter1.mesh = model2MeshForRefine(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
            cellStructDaughter2.mesh = model2MeshForRefine(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
        catch
            warndlg('could not split a cell');
            return;
        end
    end
    
   % finish constructiong the cell structures (same for all algorithms)
    cellStructDaughter1.algorithm = p.algorithm;
    cellStructDaughter2.algorithm = p.algorithm;
    cellStructDaughter2.birthframe = frame;
    cellStructDaughter1.birthframe = frame;
    if isfield(cellStructure,'mesh') && size(cellStructure.mesh,1)>1
        mesh1 = model2MeshForRefine(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
        mesh2 = model2MeshForRefine(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
        if isempty(mesh1) || isempty(mesh2) || ((length(mesh1)==1 && mesh1==-1) || (length(mesh2)==1 && mesh2==-1))
            lst = celln;
            disp('Splitting cells failed: error getting mesh');
            return;
        end
        cellStructDaughter1.mesh = single(mesh1);
        cellStructDaughter2.mesh = single(mesh2);
    end
    cellStructDaughter1.stage = 1;
    cellStructDaughter2.stage = 1;
    if ~isfield(cellStructure,'timelapse')
        if ismember(0,cellListN(1)==cellListN) || length(cellListN)<=1
            cellStructure.timelapse = 0;
        else
            cellStructure.timelapse = 1;
        end
    end
    cellStructDaughter1.polarity = 1;
    cellStructDaughter2.polarity = 2;
    cellStructDaughter1.timelapse = cellStructure.timelapse;
    cellStructDaughter2.timelapse = cellStructure.timelapse;
    cellStructDaughter1.box = roiBox;
    cellStructDaughter2.box = roiBox;
    %cellStructDaughter2 ------> mother
    %cellStructDaughter1 ------> daughter
if ~p.forceindframes && cellStructure.timelapse
    if frame>1
        for ii = frame:length(cellList.meshData)
            cellList = oufti_removeCellStructureFromCellList(celln,ii,cellList);
        end
         daughter = getDaughterNum();%getdaughter(cell,sum(mdivisions~=birthframe),max(cellList.cellId{frame})+1);
         cellStructDaughter2.divisions = [];
         cellStructDaughter1.divisions = [];
         cellStructDaughter1.birthframe = frame;
         cellStructDaughter2.birthframe = frame;
         try
            cellStructDaughter1.ancestors = [cellStructure.ancestors(cellStructure.ancestors~=celln) celln];
            cellStructDaughter2.ancestors = [cellStructure.ancestors(cellStructure.ancestors~=celln) celln];
         catch
            cellStructDaughter1.ancestors = [cellStructure.ancestors(cellStructure.ancestors~=celln)' celln];
            cellStructDaughter2.ancestors = [cellStructure.ancestors(cellStructure.ancestors~=celln)' celln];
         end
         cellStructDaughter1.descendants = [];
         cellStructDaughter2.descendants = [];
         cellStructDaughter1.polarity = 1;
         try
            cellStructDaughter2.polarity = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.polarity + 1;
         catch
             cellStructDaughter2.polarity = 2;
         end
         try
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants = [cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants daughter];
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants = [cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants daughter+1];
             cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.divisions = frame;
         catch
             try
                 cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants = [cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants' daughter];
                 cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants = [cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(celln,frame-1,cellList)}.descendants' daughter+1];
             catch
                 disp('Descendant array in previous frame could not be updated');
             end
         end
         %remove the mother cell from current cell since new approach of
         %cell division is in effect, where two cells are labelled as two
         %daughter cells.
         
    else % case of frame==1
         for ii = frame:length(cellList.meshData)
            cellList = oufti_removeCellStructureFromCellList(celln,ii,cellList);
        end
         daughter = getDaughterNum();
         cellStructDaughter1.divisions = [];
         cellStructDaughter2.divisions = [];
         cellStructDaughter1.birthframe = 1;
         cellStructDaughter2.birthframe = 1;
         cellStructDaughter1.ancestors = celln;
         cellStructDaughter2.ancestors = celln;
         cellStructDaughter1.descendants = [];
         cellStructDaughter2.descendants = [];
         cellStructDaughter1.polarity = 1; % polarity is not set when the cells on the 1st frame are splitted
         cellStructDaughter2.polarity = 2;
         
    end
else
    % independent frames regime: keep the attributess of the mother
    % cell, set the attributes of the daughter cell as newly appeared
    cellList = oufti_removeCellStructureFromCellList(celln,frame,cellList);
    daughter = getDaughterNum(); %max(cellList.cellId{frame})+1;
    cellListN = cellfun(@length,cellList.meshData);
    cellStructDaughter1.divisions = [];
    cellStructDaughter2.divisions = [];
    cellStructDaughter1.ancestors = cellStructure.ancestors;
    cellStructDaughter2.ancestors = cellStructure.ancestors;
    cellStructDaughter1.descendants = [];
    cellStructDaughter2.descendants = [];
    cellStructDaughter1.birthframe = frame;
    cellStructDaughter2.birthframe = frame;
    cellStructDaughter1.polarity = 1;
    cellStructDaughter2.polarity = 2;
    
end
    


cellList = oufti_addCell(daughter+1, frame, cellStructDaughter2, cellList);
cellList = oufti_addCell(daughter, frame, cellStructDaughter1, cellList);
lst = [daughter daughter+1];

    
% display the result message
if ~p.forceindframes && cellStructure.timelapse
        disp(['Splitting cell ' num2str(celln) ' succeeded, saved as cells ' num2str(daughter+1) ' and ' num2str(daughter) ', marked as independent.'])
else
        disp(['Splitting cell ' num2str(celln) ' succeeded, saved as cells ' num2str(daughter+1) ' and ' num2str(daughter) ', marked as two daughters.'])
end
    
end