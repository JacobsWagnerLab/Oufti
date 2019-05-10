%function proccells = processFrame(frame,processCells,currentFrameCells,previousFrameCells)
function proccells = processFrame(frame,proccells,cellParameters,rawPhaseData,...
                                  cellList,cellListN,imsizes,maskdx,maskdy,se,...
                                  coefPCA,mCell,coefS,N,weights,dMax)
% This function is for processing all frames except the first one
% 
% It is only looking for the cells that existed before and splits them if
% necessary.
mutexCleanup = onCleanup(@()unlockProcessMutex());
signals.processMutex = 1;

tic;
p = cellParameters;
cellListN(frame) = cellListN(frame-1);
if p.invertimage
    if frame>size(rawPhaseData,3), return; end 
    img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
else
    if frame>size(rawPhaseData,3), return; end
    img = rawPhaseData(:,:,frame);
end
imge = img2imge(img,p.erodeNum,se);
imge16 = img2imge16(img,p.erodeNum,se);
thres = graythreshreg(imge,p.threshminlevel);
bgr = phasebgr(imge,thres,se,p.bgrErodeNum);

allMap = zeros(size(img));
for cell = 1:length(cellList.meshData{frame-1})
    if isempty(cellList.meshData{frame-1}{cell}), continue; end
    mesh = cellList.meshData{frame-1}{cell}.mesh;
    if size(mesh,2)==4
        allMap = allMap +... 
          imerode(roipoly(allMap,[mesh(:,1);flipud(mesh(:,3))],[mesh(:,2);flipud(mesh(:,4))]),se);
    end
end
allMap = min(allMap,1);

[extDx,extDy] = getExtForces(imge,imge16,p,maskdx,maskdy,[],frame);
if isempty(extDx), disp('Processing timelapse frame failed: unable to get energy'); return; end

%cell = 1;
%cellmax = length(cellList{frame-1});
if isempty(proccells)
    for i=1:length(cellList.meshData{frame-1})
        if ~isempty(cellList.meshData{frame-1}{i})
            proccells = [proccells i];
        end
    end
end
%cellmaxCell = cellmax+1;

%Check 2
for cell = proccells % parfor
    if cell>length(cellList{frame-1}) || isempty(cellList.meshData{frame-1}{cell}), continue; end
    %gdisp(['processing cell ' num2str(cell)])
    
    % get previous frame data
    prevStruct = cellList.meshData{frame-1}{cell};
    if size(prevStruct.model,2)==1 || size(prevStruct.model,2)==1 
        pcCell = reshape(prevStruct.model,[],1);
    else
        pcCell = prevStruct.model;
    end
    cCell = model2geom(pcCell,p.algorithm,coefPCA,mCell);
    
    if ~isempty(cCell)
        roiBox(1:2) = round(max(min(cCell(:,1:2))-p.roiBorder,1));
        roiBox(3:4) = min(round(max(cCell(:,1:2))+p.roiBorder),[size(img,2) size(img,1)])-roiBox(1:2);
        if min(roiBox(3:4))<=0, cCell=[]; end
    end
    if ~isempty(cCell)
        pcCellRoi = model2box(pcCell,roiBox,p.algorithm);

        % crop the image and the energy/force maps
        roiImg = imcrop(imge,roiBox);
        roiExtDx = imcrop(extDx,roiBox);
        roiExtDy = imcrop(extDy,roiBox);
        roiAmap = imcrop(allMap,roiBox);

        % build pmap (for cell repulsion)
        mesh = cellList{frame-1}{cell}.mesh;
        if size(mesh,2)==4
            roiAmap = max(0,roiAmap - ... 
              imdilate(roipoly(roiAmap,[mesh(:,1);flipud(mesh(:,3))]-roiBox(1),...
                                       [mesh(:,2);flipud(mesh(:,4))]-roiBox(2)),se));
        end
        pmap = roiAmap;
        f1=true;
        while f1
            pmap1 = roiAmap + imerode(pmap,se);
            f1 = max(max(pmap1-pmap))>0;
            pmap = pmap1;
        end;
        pmapDx = imfilter(pmap,maskdx,'replicate'); % distance forces
        pmapDy = imfilter(pmap,maskdy,'replicate'); 
        roiExtDx = roiExtDx + p.neighRep*pmapDx;
        roiExtDy = roiExtDy + p.neighRep*pmapDy;

        if ismember(p.algorithm,[2 3])
            [pcCellRoi,fitquality] = align(roiImg,roiExtDx,roiExtDy,...
                                     roiAmap,pcCellRoi,p,false,roiBox,...
                                     thres,[frame cell],coefPCA...
                                     ,coefS,N,weights,dMax);
        elseif p.algorithm == 4
            [pcCellRoi,fitquality] = align4(roiImg,roiExtDx,roiExtDy,...
                                     roiAmap,pcCellRoi,p,roiBox,...
                                     thres,[frame cell]);
        end
        % TEST HERE
        %gdisp(['fitquality aligning = ' num2str(fitquality)])

        % obtaining the shape of the cell in geometrical representation
        pcCell = box2model(pcCellRoi,roiBox,p.algorithm);
        cCell = model2geom(pcCell,p.algorithm);

        %try splitting
        if p.algorithm==4, isct=0; else isct = intersections(cCell); end
        cellarea = 0;
        if ~isempty(isct) && ~isct
            mesh = model2mesh(cCell,p.meshStep,p.meshTolerance,p.meshWidth);
            if length(mesh)>1
                cellarea = polyarea([mesh(:,1);flipud(mesh(:,3))],[mesh(:,2);flipud(mesh(:,4))]);
                roiMesh = mesh - repmat(roiBox([1 2 1 2])-1,size(mesh,1),1);
                res=isDivided(roiMesh,roiImg,p.splitThreshold,bgr);
                if res==-1, mesh=0; end
            end
        end
    end
    
    % delete all descendants of the cell if already present
    if ~isfield(p,'delchildrenonredetect') || ~p.delchildrenonredetect
        fmax = length(cellList.meshData);
    else
        fmax = frame;
    end
    for frm = frame:fmax
        dlst = selNewFrame(cell,frame-1,frm);
        for cl = dlst;
            if cl<=length(cellList.meshData{frm}) && ~isempty(cellList.meshData{frm}{cl})
                cellList.meshData{frm}{cl} = [];
            end
        end
    end

    % checking quality and storing the cell
    if ~isempty(cCell) && ~isempty(isct) && ~isct && fitquality<p.fitqualitymax && min(min(cCell))>1+p.noCellBorder &&...
            max(cCell(:,1))<imsizes(1,2)-p.noCellBorder && max(cCell(:,2))<imsizes(1,1)-p.noCellBorder &&...
            length(mesh)>1 && p.areaMin<cellarea && p.areaMax>cellarea
        % if the cell passed the quality test and it is not on the
        % boundary of the image - store it
        if res>0 % Splitting the cell
            % mesh1 = flipud(mesh(1:res-1,:)); % daughter cell
            % mesh2 = mesh(res+1:end,:);
            % select the cells so that the mesh always goes from the stalk pole
            mesh1 = flipud(mesh(res+1:end,:)); % daughter cell
            mesh2 = mesh(1:res-1,:); % mother cell

            if ismember(p.algorithm,[2 3])
                pcCell1 = splitted2model(mesh1,p);
                pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
                pcCell1 = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,p,false,roiBox,thres,[frame cell]);
                pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
                cCell1 = model2geom(pcCell1,p.algorithm);
                pcCell2 = splitted2model(mesh2,p);
                pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
                pcCell2 = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,p,false,roiBox,thres,[frame cell]);
                pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
                cCell2 = model2geom(pcCell2,p.algorithm);
            else
                pcCell1 = align4IM(mesh1,p);
                pcCell1 = model2box(pcCell1,roiBox,p.algorithm);
                pcCell1 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,p,roiBox,thres,[frame cell]);
                pcCell1 = box2model(pcCell1,roiBox,p.algorithm);
                cCell1 = pcCell1;
                pcCell2 = align4IM(mesh2,p);
                pcCell2 = model2box(pcCell2,roiBox,p.algorithm);
                pcCell2 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,p,roiBox,thres,[frame cell]);
                pcCell2 = box2model(pcCell2,roiBox,p.algorithm);
                cCell2 = pcCell2;
            end
            
            mesh1 = model2mesh(cCell1,p.meshStep,p.meshTolerance,p.meshWidth);
            mesh2 = model2mesh(cCell2,p.meshStep,p.meshTolerance,p.meshWidth);
            cellStruct1.algorithm = p.algorithm;
            cellStruct2.algorithm = p.algorithm;
            cellStruct1.birthframe = frame;
            cellStruct2.birthframe = prevStruct.birthframe;
            if size(pcCell1,2)==1, model=pcCell1'; else model=pcCell1; end
            cellStruct1.model = model;
            if size(pcCell2,2)==1, model=pcCell2'; else model=pcCell2; end
            cellStruct2.model = model;
            cellStruct1.polarity = 1;
            cellStruct2.polarity = 1;
            cellStruct1.mesh = mesh1;
            cellStruct2.mesh = mesh2;
            cellStruct1.stage = 1;
            cellStruct2.stage = 1;
            cellStruct1.timelapse = 1;
            cellStruct2.timelapse = 1;
            cellStruct1.divisions = []; % frame?
            cellStruct2.divisions = [prevStruct.divisions frame];
            cellStruct1.box = roiBox;
            cellStruct2.box = roiBox;
            daughter = getDaughterNum();%getdaughter(cell,length(cellStruct2.divisions),cellListN(frame));
            cellStruct1.ancestors = [prevStruct.ancestors cell];
            cellStruct2.ancestors = prevStruct.ancestors;
            cellStruct1.descendants = [];
            cellStruct2.descendants = [prevStruct.descendants daughter];
            %%%cellList{frame}{cell} = cellStruct2; % mother cell keeps the number
			cellList = oufti_addCell(cell, frame, cellStruct2, cellList);
            if (frame>1)&&(length(cellList.meshData{frame-1})>=cell)&&~isempty(cellList.meshData{frame-1}{cell}), cellList.meshData{frame-1}{cell}.timelapse=1; end
% %             if daughter<p.maxCellNumber
                %%%cellList{frame}{daughter} = cellStruct1;
				cellList = oufti_addCell(daughter, frame, cellStruct1, cellList);
                proccells = [proccells daughter];
% % %             else
% % %                 %gdisp(['cell ' num2str(daughter) ' born still because of overpopulation!'])
% % %                 disp(['cell ' num2str(daughter) ' born still because of overpopulation!'])
% % %             end
           % disp('cell ', num2str(cell),' splitted, cell ', num2str(daughter), ' was born')
            %gdisp(['cell ' num2str(cell) ' splitted, cell ' num2str(daughter) ' was born'])
            continue;
        end
        
        cellStruct.birthframe = prevStruct.birthframe;
        cellStruct.algorithm = p.algorithm;
        if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
        cellStruct.model = model;
        cellStruct.mesh = mesh;
        cellStruct.polarity = prevStruct.polarity;
        cellStruct.ancestors = prevStruct.ancestors;
        cellStruct.descendants = prevStruct.descendants;
        cellStruct.stage = 1;
        cellStruct.timelapse = 1;
        %cellStruct.stage = getStage(roiImg,cellStruc.model);
        cellStruct.divisions = prevStruct.divisions;
        cellStruct.box = roiBox;
        %%%cellList{frame}{cell} = cellStruct;
		cellList = oufti_addCell(cell, frame, cellStruct, cellList);
        if (frame>1)&&(length(cellList.meshData{frame-1})>=cell)&&~isempty(cellList.meshData{frame-1}{cell}), cellList.meshData{frame-1}{cell}.timelapse=1; end
        %gdisp(['fitting cell ' num2str(cell) ' - passed and saved'])
        continue;
    else
        cellStruct = prevStruct;
        if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
        cellStruct.model = model;
        cellStruct.mesh = 0;
        cellStruct.stage = 0;
		cellList = oufti_addCell(cell, frame, cellStruct, cellList);
        %%%cellList{frame}{cell} = cellStruct; % remove this line to not save empty meshes
        % if the cell is not on the image border OR it did not pass the
        % quality test - split it
        reason = 'unknown';
        if isempty(pcCell) || isempty(cCell), reason = 'no cell found';
        elseif fitquality>=p.fitqualitymax, reason = 'bad fit quality';
        elseif min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary';
        elseif min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary';
        elseif min(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary';
        elseif min(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary';
        elseif isct, reason = 'model has intersections';
        elseif length(mesh)<=1 || cellarea==0, reason = 'problem getting mesh';
        elseif p.areaMin>=cellarea, reason = 'cell too small';
        elseif p.areaMax<=cellarea, reason = 'cell too big';
        end
        %gdisp(['fitting cell ' num2str(cell) ' - quality check failed - ' reason])
        disp(['fitting cell ' num2str(cell) ' - quality check failed - ' reason])
    end

end
  proccells = cellList;
  toc;
  munlock processFrameI
  munlock imdilate
  munlock imfilter
  munlock padarray
  %munlock ConstantPad
  munlock model2mesh
  munlock getExtForces
  clear joincells imdilate imfilter ConstantPad padarray model2mesh getExtForces
  clearvars -except proccells 
end % processFrame function





% tempCurrentFrameCells = currentFrameCells;
% tempCellListN = cellListN;
% tempP         = p;
% tempImageSize = imsizes;
% tempSe        = se;
% tempMaskDx    = maskdx;
% tempMaskDy    = maskdy;
% tempPreviousFrameCells  = previousFrameCells;
% numInitCellList = length(tempPreviousFrameCells);
% numTempCellList = length(tempCurrentFrameCells);
% cellStruct1     = [];
% cellStruct2     = [];
% cellStruct      = [];



% parfor cell = 1:30 % parfor
%     if cell>numInitCellList || isempty(tempPreviousFrameCells{cell}), continue; end
%     %gdisp(['processing cell ' num2str(cell)])
%     
%     % get previous frame data
%      prevStruct = tempPreviousFrameCells{cell};
%     if size(prevStruct.model,2)==1 || size(prevStruct.model,2)==1 
%         pcCell = reshape(prevStruct.model,[],1);
%     else
%         pcCell = prevStruct.model;
%     end
%     cCell = model2geom(pcCell,tempP.algorithm);
%     
% %     if ~isempty(cCell)
% %         roiBox(1:2) = round(max(min(cCell(:,1:2))-tempP.roiBorder,1));
% %         roiBox(3:4) = min(round(max(cCell(:,1:2))+tempP.roiBorder),[size(img,2) size(img,1)])-roiBox(1:2);
% %         if min(roiBox(3:4))<=0, cCell=[]; end
% %     end
%       roiBox = round(max(min(cCell(:,1:2))-tempP.roiBorder,1));
%     if ~isempty(cCell)
%         pcCellRoi = model2box(pcCell,roiBox,tempP.algorithm);
% 
%         % crop the image and the energy/force maps
%         roiImg = imcrop(imge,roiBox);
%         roiExtDx = imcrop(extDx,roiBox);
%         roiExtDy = imcrop(extDy,roiBox);
%         roiAmap = imcrop(allMap,roiBox);
% 
%         % build pmap (for cell repulsion)
%         tempMesh = tempPreviousFrameCells{cell}.mesh;
%         if size(tempMesh,2)==4
%             roiAmap = max(0,roiAmap - ... 
%               imdilate(roipoly(roiAmap,[tempMesh(:,1);flipud(tempMesh(:,3))]-roiBox(1),...
%                                        [tempMesh(:,2);flipud(tempMesh(:,4))]-roiBox(2)),tempSe));
%         end
%         pmap = roiAmap;
%         f1=true;
%         while f1
%             pmap1 = roiAmap + imerode(pmap,tempSe);
%             f1 = max(max(pmap1-pmap))>0;
%             pmap = pmap1;
%         end;
%         pmapDx = imfilter(pmap,tempMaskDx,'replicate'); % distance forces
%         pmapDy = imfilter(pmap,tempMaskDy,'replicate'); 
%         roiExtDx = roiExtDx + tempP.neighRep*pmapDx;
%         roiExtDy = roiExtDy + tempP.neighRep*pmapDy;
% 
%         if ismember(tempP.algorithm,[2 3])
%             [pcCellRoi,fitquality] = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCellRoi,...
%                                      tempP,false,roiBox,thres,[frame cell]);
%         elseif tempP.algorithm == 4
%             [pcCellRoi,fitquality] = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCellRoi,...
%                                      tempP,roiBox,thres,[frame cell]);
%         end
% %         % TEST HERE
% %         %gdisp(['fitquality aligning = ' num2str(fitquality)])
% 
%         % obtaining the shape of the cell in geometrical representation
%         pcCell = box2model(pcCellRoi,roiBox,tempP.algorithm);
%         cCell = model2geom(pcCell,tempP.algorithm);
% 
%         %try splitting
%         if tempP.algorithm==4, isct=0; else isct = intersections(cCell); end
%         cellarea = 0;
%         if ~isempty(isct) && ~isct
%             tempMesh2 = model2mesh(cCell,tempP.meshStep,tempP.meshTolerance,tempP.meshWidth);
%             if length(tempMesh2)>1
%                 cellarea = polyarea([tempMesh2(:,1);flipud(tempMesh2(:,3))],[tempMesh2(:,2);flipud(tempMesh2(:,4))]);
%                 roiMesh = tempMesh2 - repmat(roiBox([1 2 1 2])-1,size(tempMesh2,1),1);
%                 res=isDivided(roiMesh,roiImg,tempP.splitThreshold,bgr);
%                 if res==-1, tempMesh2=0; end
%             end
%         end
%     end
%     
%     % delete all descendants of the cell if already present
% %     if ~isfield(tempP,'delchildrenonredetect') || ~tempP.delchildrenonredetect
% %         fmax = numTempCellList;
% %     else
% %         fmax = frame;
% %     end
% %     for frm = frame:fmax
% %         a = frm;
% %         dlst = selNewFrame(cell,frame-1,a);
% %         
% %         for cl = dlst;
% %             b = c1;
% %             if b<=length(tempCellList{a}) && ~isempty(tempCellList{a}{b})
% %                 tempCellList{a}{b} = [];
% %             end
% %         end
% %     end
% 
% %     % checking quality and storing the cell
%     if ~isempty(cCell) && ~isempty(isct) && ~isct && fitquality<tempP.fitqualitymax && ...
%         min(min(cCell))>1+tempP.noCellBorder &&...
%         max(cCell(:,1))<tempImageSize(1,2)-tempP.noCellBorder && max(cCell(:,2))...
%         <tempImageSize(1,1)-tempP.noCellBorder &&...
%         length(tempMesh)>1 && tempP.areaMin<cellarea && tempP.areaMax>cellarea
%         % if the cell passed the quality test and it is not on the
%         % boundary of the image - store it
%         if res>0 % Splitting the cell
%             % mesh1 = flipud(mesh(1:res-1,:)); % daughter cell
%             % mesh2 = mesh(res+1:end,:);
%             % select the cells so that the mesh always goes from the stalk pole
%             mesh1 = flipud(tempMesh(res+1:end,:)); % daughter cell
%             mesh2 = tempMesh(1:res-1,:); % mother cell
% 
%             if ismember(tempP.algorithm,[2 3])
%                 pcCell1 = splitted2model(mesh1,tempP);
%                 pcCell1 = model2box(pcCell1,roiBox,tempP.algorithm);
%                 pcCell1 = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,tempP,false,roiBox,thres,[frame cell]);
%                 pcCell1 = box2model(pcCell1,roiBox,tempP.algorithm);
%                 cCell1 = model2geom(pcCell1,tempP.algorithm);
%                 pcCell2 = splitted2model(mesh2,tempP);
%                 pcCell2 = model2box(pcCell2,roiBox,tempP.algorithm);
%                 pcCell2 = align(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,tempP,false,roiBox,thres,[frame cell]);
%                 pcCell2 = box2model(pcCell2,roiBox,tempP.algorithm);
%                 cCell2 = model2geom(pcCell2,tempP.algorithm);
%             else
%                 pcCell1 = align4IM(mesh1,tempP);
%                 pcCell1 = model2box(pcCell1,roiBox,tempP.algorithm);
%                 pcCell1 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell1,tempP,roiBox,thres,[frame cell]);
%                 pcCell1 = box2model(pcCell1,roiBox,tempP.algorithm);
%                 cCell1 = pcCell1;
%                 pcCell2 = align4IM(mesh2,tempP);
%                 pcCell2 = model2box(pcCell2,roiBox,tempP.algorithm);
%                 pcCell2 = align4(roiImg,roiExtDx,roiExtDy,roiAmap,pcCell2,tempP,roiBox,thres,[frame cell]);
%                 pcCell2 = box2model(pcCell2,roiBox,tempP.algorithm);
%                 cCell2 = pcCell2;
%             end
%             
%             mesh1 = model2mesh(cCell1,tempP.meshStep,tempP.meshTolerance,tempP.meshWidth);
%             mesh2 = model2mesh(cCell2,tempP.meshStep,tempP.meshTolerance,tempP.meshWidth);
%             cellStruct1{cell}.algorithm = tempP.algorithm;
%             cellStruct2{cell}.algorithm = tempP.algorithm;
%             cellStruct1{cell}.birthframe = frame;
%             cellStruct2{cell}.birthframe = prevStruct.birthframe;
%             if size(pcCell1,2)==1, model=pcCell1'; else model=pcCell1; end
%             cellStruct1{cell}.model = model;
%             if size(pcCell2,2)==1, model=pcCell2'; else model=pcCell2; end
%             cellStruct2{cell}.model = model;
%             cellStruct1{cell}.polarity = 1;
%             cellStruct2{cell}.polarity = 1;
%             cellStruct1{cell}.mesh = mesh1;
%             cellStruct2{cell}.mesh = mesh2;
%             cellStruct1{cell}.stage = 1;
%             cellStruct2{cell}.stage = 1;
%             cellStruct1{cell}.timelapse = 1;
%             cellStruct2{cell}.timelapse = 1;
%             cellStruct1{cell}.divisions = []; % frame?
%             cellStruct2{cell}.divisions = [prevStruct.divisions frame];
%             cellStruct1{cell}.box = roiBox;
%             cellStruct2{cell}.box = roiBox;
%             daughter = getdaughter(cell,length(cellStruct2{cell}.divisions),tempCellListN(frame));
%             cellStruct1{cell}.ancestors = [prevStruct.ancestors cell];
%             cellStruct2{cell}.ancestors = prevStruct.ancestors;
%             cellStruct1{cell}.descendants = [];
%             cellStruct2{cell}.descendants = [prevStruct.descendants daughter];
%             tempCurrentFrameCells= [tempCurrentFrameCells,cellStruct2{cell}]; % mother cell keeps the number
%             if (frame>1)&&(numInitCellList>=cell)&&~isempty(tempPreviousFrameCells{cell}),...
%                 tempPreviousFrameCells{cell}.timelapse=1; end
%             if daughter<tempP.maxCellNumber
%                 tempCurrentFrameCells= [tempCurrentFrameCells,cellStruct1{cell}];
%                 processCells = [processCells daughter];
%             else
%                 gdisp(['cell ' num2str(daughter) ' born still because of overpopulation!'])
%             end
%             gdisp(['cell ' num2str(cell) ' splitted, cell ' num2str(daughter) ' was born'])
%             continue;
%         end
%         
%         cellStruct{cell}.birthframe = prevStruct.birthframe;
%         cellStruct{cell}.algorithm = tempP.algorithm;
%         if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
%         cellStruct{cell}.model = model;
%         cellStruct{cell}.mesh = mesh;
%         cellStruct{cell}.polarity = prevStruct.polarity;
%         cellStruct{cell}.ancestors = prevStruct.ancestors;
%         cellStruct{cell}.descendants = prevStruct.descendants;
%         cellStruct{cell}.stage = 1;
%         cellStruct{cell}.timelapse = 1;
%         %cellStruct.stage = getStage(roiImg,cellStruc.model);
%         cellStruct{cell}.divisions = prevStruct.divisions;
%         cellStruct{cell}.box = roiBox;
%         tempCurrentFrameCells= [tempCurrentFrameCells,cellStruct{cell}];
%         if (frame>1)&&((numInitCellList)>=cell)...
%            &&~isempty(tempPreviousFrameCells{cell}), tempPreviousFrameCells{cell}.timelapse=1; end
%         gdisp(['fitting cell ' num2str(cell) ' - passed and saved'])
%         continue;
%     else
%         cellStruct{cell} = prevStruct;
%         if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
%         cellStruct{cell}.model = model;
%         cellStruct{cell}.mesh = 0;
%         cellStruct{cell}.stage = 0;
%         tempCurrentFrameCells= [tempCurrentFrameCells,cellStruct{cell}];% remove this line to not save empty meshes
%         % if the cell is not on the image border OR it did not pass the
%         % quality test - split it
%         reason = 'unknown';
%         if isempty(pcCell) || isempty(cCell), reason = 'no cell found';
%         elseif fitquality>=tempP.fitqualitymax, reason = 'bad fit quality';
%         elseif min(cCell(:,1))<=1+tempP.noCellBorder, reason = 'cell on x=0 boundary';
%         elseif min(cCell(:,2))<=1+tempP.noCellBorder, reason = 'cell on y=0 boundary';
%         elseif min(cCell(:,1))>=tempImageSize(1,2)-tempP.noCellBorder, reason = 'cell on x=max boundary';
%         elseif min(cCell(:,2))>=tempImageSize(1,1)-tempP.noCellBorder, reason = 'cell on y=max boundary';
%         elseif isct, reason = 'model has intersections';
%         elseif length(tempMesh)<=1 || cellarea==0, reason = 'problem getting mesh';
%         elseif tempP.areaMin>=cellarea, reason = 'cell too small';
%         elseif tempP.areaMax<=cellarea, reason = 'cell too big';
%         end
%         gdisp(['fitting cell ' num2str(cell) ' - quality check failed - ' reason]);  
%     end
% end

  




