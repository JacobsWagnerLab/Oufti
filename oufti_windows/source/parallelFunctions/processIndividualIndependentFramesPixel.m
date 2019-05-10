function [individualFrameStruct,imageForce_] = processIndividualIndependentFramesPixel(img,frame,l_p,...
                                                      l_args,processRegion,cellStructure,imageForce_)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function processIndividualIndependentFramesPixel(img,frame,...
%                                            l_p,l_args,processRegion)
%oufti.v0.0.5
%@author:   Ahmad J Paintdakhi
%@date:     July 2, 2015
%@copyright Yale University

%==========================================================================
%**********output********:
%frameParts:  CellList array containing single frame data

%**********Input*********:
%img:           image matrix for a given frame
%frame:         current frame number
%l_p:           p-parameter structure with not global variables
%l-args:        some extra parameters
%processRegion: the region to be processed if any
%==========================================================================
warning('off','MATLAB:triangulation:PtsNotInTriWarnId');
individualFrameStruct.meshData = [];
individualFrameStruct.cellId   = [];
cellStructure.meshData{frame} = []; cellStructure.cellId{frame} = [];
maxRawPhaseDataValue = max(max(max(img)));
if l_p.invertimage == 1
    img = maxRawPhaseDataValue - img;
end
disp(['Processing Frame ' num2str(frame)])
imge = img2imge(img,l_p.erodeNum,l_args.se);
imge16 = img2imge16(img,l_p.erodeNum,l_args.se);
if gpuDeviceCount == 1
    try
        thres = graythreshreg(gpuArray(imge),l_p.threshminlevel,l_args.regionSelectionRect);
    catch
        thres = graythreshreg(imge,l_p.threshminlevel,l_args.regionSelectionRect);
    end
else
    thres = graythreshreg(imge,l_p.threshminlevel,l_args.regionSelectionRect);
end
regions0 = getRegions(imge,thres,imge16,l_p);
if gpuDeviceCount == 1
            try
                thres = graythreshreg(gpuArray(imge),l_p.threshminlevel);
            catch
                thres = graythreshreg(imge,l_p.threshminlevel);
            end
 else
     thres = graythreshreg(imge,l_p.threshminlevel);
end     
bgr = phasebgr(imge,thres,l_args.se,l_p.bgrErodeNum);


if ~isempty(processRegion)
    crp = regions0(processRegion(2)+(0:processRegion(4)),...
                   processRegion(1)+(0:processRegion(3)));
    regions0 = regions0*0;
    regions0(processRegion(2)+(0:processRegion(4)),...
             processRegion(1)+(0:processRegion(3))) = crp;
    regions0 = bwlabel(regions0>0,4);
end
regions0 = bwmorph(regions0,'erode');
regions0 = bwmorph(regions0,'dilate');

if l_p.splitregions == 1
    bw2 = ~bwareaopen(~regions0,10);
    D = -bwdist(~bw2);
    mask = imextendedmin(D,4);
    D2 = imimposemin(D,mask);
    Ld2 = watershed(D2);
    bw3 = regions0;
    bw3(Ld2 == 0) = 0;
    regions0 = bwlabel(bw3>0,8);
end
stat0 = regionprops(regions0,'area','boundingbox');
regions0 = bwlabel(regions0>0,8);
reg=1;
celln = 0;
regmax = length(stat0);
regold = 0;
area1CountCheck = 4;
area1Counter = 0;
roiMaskHistory = [];
roiMaskHistoryCounter = 0;

while reg<=regmax && reg<=l_p.maxRegNumber
if reg>regold, repcount=0; else repcount=repcount+1; end
if repcount>5, reg=reg+1; continue; end
regold = reg;
%%%if regmindisp, disp(['processing region ' num2str(reg)]); end
if reg>length(stat0), stat0=regionprops(regions0,'area','boundingbox'); end
if reg>length(stat0), break; end
statC = stat0(reg);
    
% if the region is to small or too big- discard it

if isempty(statC.Area) || statC.Area < l_p.areaMin || isempty(statC.BoundingBox) || statC.Area > l_p.areaMax
%regions0(regions0==reg)=0; 
disp(['region ' num2str(reg) ' discarded, area = ' num2str(statC.Area)]);
reg=reg+1; 
continue; 
end
    
%otherwise compute the properties for proper splitting
% coordinates of the ROI box

roiBox(1:2) = ceil(max(statC.BoundingBox(1:2)-l_p.roiBorder,1)); 
roiBox(3:4) = floor(min(statC.BoundingBox(1:2)+statC.BoundingBox(3:4)+...
                  l_p.roiBorder,[size(img,2) size(img,1)])-roiBox(1:2));
roiRegs = imcrop(regions0,roiBox); % ROI with all regions labeled
roiMask = bwmorph(roiRegs==reg,'close'); % ROI with region #reg labeled
roiImg = imcrop(imge,roiBox);    
% if the region is of the allowed size - try to fit the model
if statC.Area < l_p.areaMax && celln<l_p.maxCellNumber
     
% Making first variant of the model       
% adjustment of the model to the external energy map

pcCell = align4Initial(roiMask,l_p);

% converting from box to global coordinates
pcCell = box2model(pcCell,roiBox,l_p.algorithm);
% obtaining the shape of the cell in geometrical representation
cCell = model2geom(pcCell,l_p.algorithm,l_args.coefPCA,l_args.mCell);
res = 0;
mesh = 0;
%try splitting
cellarea = statC.Area;
if l_p.getmesh
    mesh = model2MeshForRefine(cCell,l_p.meshStep,l_p.meshTolerance,l_p.meshWidth);
    if length(mesh)>1
       cellarea = polyarea([mesh(:,1);flipud(mesh(:,3))],...
                            [mesh(:,2);flipud(mesh(:,4))]);
       roiMesh = mesh - repmat(roiBox([1 2 1 2])-1,size(mesh,1),1);
       res=isDivided(roiMesh,roiImg,l_p.splitThreshold,bgr,l_p.sgnResize);
       if res==-1, mesh=0; end
    end
end
% checking quality and storing the cell
if ~isempty(pcCell) && ...
     min(min(cCell))>1+l_p.noCellBorder &&...
     max(cCell(:,1))<l_args.imsizes(1,2)-l_p.noCellBorder && ...
     max(cCell(:,2))<l_args.imsizes(1,1)-l_p.noCellBorder && ...
    l_p.areaMin<cellarea && l_p.areaMax>cellarea
     resplitcount = 0;
% if the cell passed the quality test and it is not on the
% boundary of the image - store it
     if l_p.split1 && res>0 % Splitting the cell
        mesh1 = flipud(mesh(res+1:end,:)); % daughter1
        mesh2 = mesh(1:res-1,:); % daughter2
           pcCell1 = align4IM(mesh1,l_p);
           pcCell1 = model2box(pcCell1,roiBox,l_p.algorithm);
           pcCell2 = align4IM(mesh2,l_p);
           pcCell2 = model2box(pcCell2,roiBox,l_p.algorithm);
           cCell1 = box2model(pcCell1,roiBox,l_p.algorithm);
           cCell2 = box2model(pcCell2,roiBox,l_p.algorithm);
           cellStruct1.algorithm = l_p.algorithm;
           cellStruct2.algorithm = l_p.algorithm;
           cellStruct1.birthframe = frame;
           cellStruct2.birthframe = frame;
           if size(pcCell1,2)==1, model=cCell1'; else model=cCell1; end
           cellStruct1.model = model;
           if size(pcCell2,2)==1, model=cCell2'; else model=cCell2; end
           cellStruct2.model = model;
           cellStruct1.mesh = mesh1;
           cellStruct2.mesh = mesh2;
           cellStruct1.polarity = 1;
           cellStruct2.polarity = 2;
           cellStruct1.stage = 1;
           cellStruct2.stage = 1;
           cellStruct1.timelapse = 0;
           cellStruct2.timelapse = 0;
           cellStruct1.divisions = [];
           cellStruct2.divisions = [];
           cellStruct1.box = roiBox;
           cellStruct2.box = roiBox;
           cellStruct1.ancestors = [];
           cellStruct2.ancestors = [];
           cellStruct1.descendants = [];
           cellStruct2.descendants = [];
           celln = celln+2;
           %%%cellStructure{celln-1} = cellStruct1;%#ok<AGROW>
           %%%cellStructure{celln}   = cellStruct2;%#ok<AGROW>
           cellStructure  = oufti_addCell(single(celln-1), frame, cellStruct1, cellStructure);
           cellStructure  = oufti_addCell(single(celln),   frame, cellStruct2, cellStructure);
            reg=reg+1;
            continue;
     end
            
% if the cell passed the quality test and it is not on the
% boundary of the image - store it
         pcCell = cCell;
         cellStruct.algorithm = l_p.algorithm;
         cellStruct.birthframe = frame;
         if size(pcCell,2)==1, model=pcCell'; else model=pcCell; end
         cellStruct.model = single(model);
         cellStruct.mesh = single(mesh);
         cellStruct.polarity = 0;
         cellStruct.ancestors = [];
         cellStruct.descendants = [];
         cellStruct.stage = 1;
         %cellStruct.stage = getStage(roiImg,cellStruc.model);
         cellStruct.timelapse = 0;
         cellStruct.divisions = [];
         cellStruct.box = roiBox;
         celln = celln+1;
         %cellStructure{celln} = cellStruct;%#ok<AGROW>
         %cellList{frame}{celln} = cellStruct;
         cellStructure = oufti_addCell(single(celln), frame, cellStruct, cellStructure);
         reg=reg+1;
         continue;
end
        % if the cell is not on the image border OR it did not pass the
        % quality test - split it
        reason = 'unknown';
        if isempty(pcCell), reason = 'no cell found'; 
        elseif min(cCell(:,1))<=1+l_p.noCellBorder, disp('cell on x=0 boundary'); reg = reg+1; continue; 
        elseif min(cCell(:,2))<=1+l_p.noCellBorder, disp('cell on y=0 boundary'); reg = reg+1; continue;
        elseif max(cCell(:,1))>=l_args.imsizes(1,2)-l_p.noCellBorder, disp('cell on x=max boundary');reg = reg+1; continue; 
        elseif max(cCell(:,2))>=l_args.imsizes(1,1)-l_p.noCellBorder, disp('cell on y=max boundary');reg = reg+1; continue;
        elseif length(mesh)<=1, reason = 'problem getting mesh'; 
        elseif l_p.areaMin>=cellarea, reason = 'cell too small'; 
        elseif l_p.areaMax<=cellarea, reason = 'cell too big'; 
        end
        if isempty(who('resplitcount')), resplitcount=0; end
        if (l_p.areaMin>cellarea) || (resplitcount>=4) % Discarding cells
            disp(['fitting region ' num2str(reg) ' - quality check failed - ' reason])
            reg=reg+1;
            resplitcount = 0;
            continue;
        elseif isfield(l_p,'splitbndcells') && ~l_p.splitbndcells && ...
               (min(cCell(:,1))<=1+l_p.noCellBorder || min(cCell(:,2))<=1+l_p.noCellBorder || ...
               max(cCell(:,1))>=l_args.imsizes(1,2)-l_p.noCellBorder || ...
               max(cCell(:,2))>=l_args.imsizes(1,1)-l_p.noCellBorder)
               disp(['fitting region ' num2str(reg) ' - ' reason ' - splitting not allowed'])
               reg=reg+1;
               resplitcount = 0;
               continue;
        else
            resplitcount = resplitcount+1;
            disp(['fitting region ' num2str(reg) ' - quality check failed - try resplitting (' ...
                  num2str(resplitcount) ')'])
        end
end
        
if ~l_p.splitregions % do not split, just discard
    reg=reg+1;
    disp(['region ' num2str(reg) ' discarded - splitting not allowed'])
    continue;
end

[roiLabeled,roiResidual] = splitonereg(roiMask.*roiImg,roiMaskHistory,roiMaskHistoryCounter,l_p);
try
    if min(cCell(:,1))<=1+l_p.noCellBorder || min(cCell(:,2))<=1+l_p.noCellBorder ...
            ||max(cCell(:,1))>=imsizes(1,2)-l_p.noCellBorder || max(cCell(:,2))>=imsizes(1,2)-l_p.noCellBorder 
        disp('cell close to boundary');
        reg = reg+1;continue;
    end
catch
end
if isempty(roiLabeled), reg=reg+1; 
   disp(['region ' num2str(reg) ' discarded - unable to split (1)']); 
   continue; 
end
statL=regionprops(logical(roiLabeled),'area');
statM=regionprops(logical(roiResidual),'area');
if isempty(statL), area1 = -1; 
elseif statL(1).Area<l_p.areaMin, area1 = 0;
elseif statL(1).Area<l_p.areaMax, area1 = 1;
else area1 = 2;
end
if isempty(statM), area2 = -1;
elseif statM(1).Area<l_p.areaMin, area2 = 0;
elseif statM(1).Area<l_p.areaMax, area2 = 1;
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
% % % if area1>0
% % %    statF = regionprops(logical(roiRegs==reg),'Area');
% % %    stat0(reg).Area=statF(1).Area;
% % % end
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
individualFrameStruct.meshData = cellStructure.meshData{frame};
individualFrameStruct.cellId   = cellStructure.cellId{frame};

end % processIndividualIndependentFramesPixel function




  
 









