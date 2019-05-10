function proccells2 = processFrameOld(frame,proccells,cont,processregion)
% This function is for processing the first frame only
% 
% It searches for the cells on the frame and then does refinement

global imsizes se cellList cellListN rawPhaseData p;

% In ~cont mode the output array proccells2 stays empty.
% In the cont mode, proccells2 will stay empty if the input array is empty
% (but all cells will be processed), otherwise it will hold the progeny of 
% the proccells. In the cont mode, regardless of the proccells, the progeny
% is determined by positioning of the center of the new cell inside of the
% outline of the old cell. The first cell matched this way is mother, the
% second is daughter, the rest are discarded.
proccells2 = [];
if ~isempty(proccells), lst = proccells; elseif frame>1, lst = 1:length(cellList.meshData{frame-1}); else lst = []; end

if p.invertimage
    if isempty(rawPhaseData)||frame>size(rawPhaseData,3), disp(['The frame ' num2str(frame) ' will not be processed: no image']); return; end
    img = max(max(max(rawPhaseData)))-rawPhaseData(:,:,frame);
else
    if isempty(rawPhaseData)||frame>size(rawPhaseData,3), disp(['The frame ' num2str(frame) ' will not be processed: no image']); return; end
    img = rawPhaseData(:,:,frame);
end

imge = img2imge(img,p.erodeNum,se);
imge16 = img2imge16(img,p.erodeNum,se);
imgemax = max(max(imge));
img = img2imge(img,0,se);

thres = graythreshreg(imge,p.threshminlevel);
regions0 = getRegions(imge,thres,imge16,p);
if ~isempty(processregion)
    crp = regions0(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
    regions0 = regions0*0;
    regions0(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
    regions0 = bwlabel(regions0>0,4);
end
stat0 = regionprops(regions0,'area','boundingbox');
reg=1;
cell = 0;
regmax = length(stat0);
regold = 0;

if regmax>numel(img)/500
    disp('Too many regions, consider increasing thresFactorM.')
    disp('Some information will not be displayed ')
    regmindisp = false;
else
    regmindisp = true;
end

while reg<=regmax && reg<=p.maxRegNumber
    if reg>regold, repcount=0; else repcount=repcount+1; end
    if repcount>20, reg=reg+1; continue; end
    regold = reg;
    if regmindisp, disp(['processing region ' num2str(reg)]); end
    if reg>length(stat0), stat0=regionprops(regions0,'area','boundingbox'); end
    if reg>length(stat0), break; end
    statC = stat0(reg);
    
    % if the region is to small - discard it
    if statC.Area < p.areaMin
        % regions0(regions0==reg)=0; 
        if regmindisp, disp(['region ' num2str(reg) ' discarded, area = ' num2str(statC.Area)]); end
        reg=reg+1; 
        continue; 
    end
    
    % otherwise compute the properties for proper splitting
    roiBox(1:2) = max(statC.BoundingBox(1:2)-p.roiBorder,1); % coordinates of the ROI box
    roiBox(3:4) = min(statC.BoundingBox(1:2)+statC.BoundingBox(3:4)+p.roiBorder,[size(img,2) size(img,1)])-roiBox(1:2);
    roiRegs = imcrop(regions0,roiBox); % ROI with all regions labeled
    roiMask = roiRegs==reg; % ROI with region #reg labeled
    % for k=1:p.dilMaskNum, roiMask = imdilate(roiMask,se); end
    roiImg = imcrop(imge,roiBox);
    roiImgI = imcrop(img,roiBox);
    
    perim = bwperim(imdilate(roiMask,se));
    pmap = 1 - perim;
    f1=true;
    while f1
        pmap1 = 1 - perim + imerode(pmap,se);
        f1 = max(max(pmap1-pmap))>0;
        pmap = pmap1;
    end;
    regDmap = (3*(pmap+1) + 5*(1-roiImg/imgemax)).*roiMask;
    maxdmap = max(max(regDmap));


    % if the region is of the allowed size - accept it
    if statC.Area < p.areaMax
        
        % Get and smooth the boundary of the region
        [ii,jj]=find(bwperim(roiMask),1,'first');
        cCell=bwtraceboundary(roiMask,[ii,jj],'n',8,inf,'counterclockwise');
        if isfield(p,'interpoutline') && p.interpoutline
            ctrlist = interpoutline(cCell,roiImg,p);
        else
            ctrlist = {cCell};
        end
        if isempty(ctrlist), disp(['fitting region ' num2str(reg) ' - failed, no outline creating during smoothing']); end
        for cind = 1:length(ctrlist)
            cCell = ctrlist{cind};
            if p.fsmooth>0 && p.fsmooth<Inf
                fpp = frdescp(cCell);
                cCell = ifdescp(fpp,p.fsmooth);
                cCell=[cCell;cCell(1,:)]; % make the last point the same as the first one
            end
            cCell = rot90(cCell,2);
            cCell(:,1) = cCell(:,1)+roiBox(1)-1;
            cCell(:,2) = cCell(:,2)+roiBox(2)-1;
            
            % Save the data
            if p.getmesh, mesh = model2mesh(cCell,p.meshStep,p.meshTolerance,p.meshWidth); end
            if (~p.getmesh || length(mesh)>4) && min(min(cCell))>1+p.noCellBorder &&...
                    max(cCell(:,1))<imsizes(1,2)-p.noCellBorder && ...
                    max(cCell(:,2))<imsizes(1,1)-p.noCellBorder
                cellStruct.algorithm = 1;
                if p.getmesh, cellStruct.mesh = mesh; end
                cellStruct.polarity = 0;
                cellStruct.box = roiBox;
                cellStruct.ancestors = [];
                cellStruct.descendants = [];
                cellStruct.divisions = [];
                cellStruct.stage = [];
                cellStruct.model = cCell;
                cellStruct.polarity = 0; % algorithm 1 cannot divide cells unless this is interpoutline
                if cont && frame>1
                    if p.getmesh
                        xcent = sum(mesh(floor(size(mesh,1)/2),[1 3]))/2;
                        ycent = sum(mesh(floor(size(mesh,1)/2),[2 4]))/2;
                    else
                        xcent = mean(cCell(:,1));
                        ycent = mean(cCell(:,2));
                    end
                    mother = [];
                    for mcell=lst % length(cellList{frame})<mcell ||
                        if isempty(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}), continue; end
                        if ~isfield(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)},'model') && (~isfield(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)},'mesh') ...
                                || length(cellList.meshData{frame-1}{mcell}.mesh)<=4), continue; end
                        if length(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}.box)>1
                            box = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}.box;
                            if inpolygon(xcent,ycent,[box(1) box(1) box(1)+box(3) box(1)+box(3)],[box(2) box(2)+box(4) box(2)+box(4) box(2)])
                                if isfield(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)},'mesh')
                                    mesh2 = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}.mesh;
                                    ctrx = [mesh2(:,1);flipud(mesh2(:,3))];
                                    ctry = [mesh2(:,2);flipud(mesh2(:,4))];
                                elseif isfield(cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)},'model')
                                    ctrx = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}.model(:,1);
                                    ctry = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}.model(:,2);
                                end
                                if inpolygon(xcent,ycent,ctrx,ctry)
                                    mother=mcell;
                                    break;
                                end
                            end
                        end
                    end
                    cell = cell+1;
                    if isempty(mother)
                        disp(['fitting region ' num2str(reg) ' - no parent found - discarded'])
                    else
                        cellStruct.birthframe = cellList.meshData{frame-1}{oufti_cellId2PositionInFrame(mcell,frame-1,cellList)}.birthframe;
                        if length(cellList.meshData{frame})<mother || isempty(cellList.meshData{frame}{oufti_cellId2PositionInFrame(mother,frame,cellList)})
                            cellList.meshData{frame}{oufti_cellId2PositionInFrame(mother,frame,cellList)} = cellStruct;
                            if cont && ~isempty(proccells),  proccells2 = [proccells2 mother]; end
                            disp(['fitting region ' num2str(reg) ' - passed and saved'])
                        else
                            cellList.meshData{frame}{oufti_cellId2PositionInFrame(mother,frame,cellList)}.divisions = [cellList.meshData{frame}{oufti_cellId2PositionInFrame(mother,frame,cellList)}.divisions frame];
                            daughter = getDaughterNum();%getdaughter(mother,length(cellList.meshData{frame}{mother}.divisions),cellListN(frame-1));
                            cellList.meshData{frame}{oufti_cellId2PositionInFrame(mother,frame,cellList)}.descendants = daughter;
                            if length(cellList.meshData{frame})<daughter || isempty(cellList.meshData{frame}{oufti_cellId2PositionInFrame(daughter,frame,cellList)})
% %                                 if daughter<p.maxCellNumber
                                    cellList.meshData{frame}{oufti_cellId2PositionInFrame(daughter,frame,cellList)} = cellStruct;
                                    if cont && ~isempty(proccells), proccells2 = [proccells2 daughter]; end
% % %                                 else
% % %                                     disp(['fitting region ' num2str(reg) ' - new cell still born - overpopulation'])
% % %                                 end
                            else
                                disp(['fitting region ' num2str(reg) ' - too many children, one discarded'])
                            end
                        end
                    end
                else
                    cellStruct.birthframe = frame;
                    cell = cell+1;
                    cellList = oufti_addCell(cell,frame,cellStruct,cellList);
                    disp(['fitting region ' num2str(reg) ' - passed and saved as cell ' num2str(cell)])
                end
            else
                % if the cell is not on the image border OR it did not pass the
                % quality test - split it
                reason = 'unknown';
                if p.getmesh && length(mesh)<=4, reason = 'bad region shape quality'; end
                if min(cCell(:,1))<=1+p.noCellBorder, reason = 'cell on x=0 boundary'; end
                if min(cCell(:,2))<=1+p.noCellBorder, reason = 'cell on y=0 boundary'; end
                if max(cCell(:,1))>=imsizes(1,2)-p.noCellBorder, reason = 'cell on x=max boundary'; end
                if max(cCell(:,2))>=imsizes(1,1)-p.noCellBorder, reason = 'cell on y=max boundary'; end
                disp(['fitting region ' num2str(reg) ' - quality check failed - ' reason])
            end
        end
        reg=reg+1;
        continue
    elseif ~p.splitregions % do not split, just discard
        reg=reg+1;
        disp(['region ' num2str(reg) ' discarded - splitting not allowed'])
        continue
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

    [roiLabeled,roiResidual] = splitonereg(roiMask.*roiImgI,roiMask,roiMask,p);
    if isempty(roiLabeled), reg=reg+1; disp(['region ' num2str(reg) ' discarded - unable to split (1)']); continue; end
    statL=regionprops(roiLabeled ,'area');
    statM=regionprops(roiResidual,'area');

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
    
    % if i==maxdmap, area1=0; area2=0; end

    if area1==-1 || area2==-1
        reg=reg+1;
        disp(['region ' num2str(reg) ' discarded - unable to split'])
        continue;
    end    
    
    if area1>=1 && area2>=1
        regmax = regmax+1;
        roiRegs = roiRegs.*(~roiMask) + reg*roiLabeled + regmax*roiResidual;
        roiMask = roiLabeled;
        disp(['region ' num2str(reg) ' splitted and the number of regions increased - return for test'])
    elseif area1==0 && area2>=1
        roiRegs = roiRegs.*(~roiMask) + reg*roiResidual;
        roiMask = roiResidual;
        area1 = area2;
    elseif area2==0
        roiRegs = roiRegs.*(~roiMask) + reg*roiLabeled;
        roiMask = roiLabeled;
        disp(['region ' num2str(reg) ' splitted - return for test'])
    end

    if area1==0
        roiRegs = roiRegs.*(~roiMask);
        reg=reg+1;
        disp(['region ' num2str(reg) ' discarded'])
    end
    if area1>0
        statF = regionprops(bwlabel(roiRegs==reg),'Area');
        stat0(reg).Area=statF(1).Area;
    end
    
    regions0(roiBox(2):roiBox(2)+roiBox(4),roiBox(1):roiBox(1)+roiBox(3)) = roiRegs;
end
if cont
    cellListN(frame) = cellListN(frame-1);
else
    cellListN(frame) = length(cellList.meshData{frame});
end



end






