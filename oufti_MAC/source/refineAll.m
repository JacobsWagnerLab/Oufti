function cellStructure = refineAll(cellStructure,cellId,l_p,eroddedImage, externalForceDx,...
                    externalForceDy, frame,tempSe, tempMaskdx, tempMaskdy,tempCellListN,thres)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function refineAll(cellStructure,cellId,l_p,eroddedImage, externalForceDx,...
%externalForceDy, frame,tempSe, tempMaskdx, tempMaskdy,tempCellListN)
%Oufti
%@author:  Ahmad J Paintdakhi
%@date:    June 13 2014
%@copyright 2012-2015 Yale University
%==========================================================================
%**********output********
%cellStructure:  cellStructure contains reinfed mesh and model.
%**********Input********
%
%**********Purpose******
%Purpose:  This function refines all cells in a given cellList with current
%paramters.  The refinement makes sure there is no bias present in
%different frames especially if a study is a time-lapse.
%==========================================================================
    

pcCell = [];
cCell = [];
if ~isfield(cellStructure,'mesh') || length(cellStructure.mesh) < 4,return;end
roiBox = cellStructure.box;
roiImg = imcrop(eroddedImage,roiBox);
roiBox(3:4) = [size(roiImg,2) size(roiImg,1)]-1;
roiExtDx = imcrop(externalForceDx,roiBox);
roiExtDy = imcrop(externalForceDy,roiBox);
%checks if a mesh is present and if its length is greather than 4

mesh = cellStructure.mesh;
if ismember(l_p.algorithm,[2 3])
    pcCell = splitted2model(mesh,l_p,tempSe,tempMaskdx,tempMaskdy);
    pcCell = model2box(pcCell,roiBox,l_p.algorithm);
    pcCell = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,l_p,false,roiBox,thres,[frame cellId]);
    pcCell = box2model(pcCell,roiBox,l_p.algorithm);
    cCell  = double(model2geom(pcCell,l_p.algorithm));
elseif ismember(l_p.algorithm,4)
    pcCell = align4IM(mesh,l_p);
    pcCell = model2box(pcCell,roiBox,l_p.algorithm);
    cCell =  align4Manual(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,l_p,roiBox,thres,[frame cellId]);
    cCell =  double(box2model(cCell,roiBox,l_p.algorithm));
end
if isempty(cCell), return; end
mesh = model2MeshForRefine(cCell,l_p.meshStep,l_p.meshTolerance,l_p.meshWidth);
if (isempty(mesh) || size(mesh,1) == 1), return; end
if size(pcCell,2)==1, model=cCell'; else model=cCell; end
cellStructure.mesh = single(mesh);
cellStructure.model = single(model);
roiBox(1:2) = floor(max([min(min(mesh(:,[1 3]))) min(min(mesh(:,[2 4])))]-l_p.roiBorder,1));
roiBox(3:4) = ceil(min([max(max(mesh(:,[1 3]))) max(max(mesh(:,[2 4])))]+l_p.roiBorder,[size(eroddedImage,2) size(eroddedImage,1)])-roiBox(1:2));
cellStructure.box = roiBox;
if ~isfield(cellStructure,'timelapse')
    if ismember(0,tempCellListN(1)== tempCellListN) || length(tempCellListN)<=1
        cellStructure.timelapse = 0;
    else
        cellStructure.timelapse = 1;
    end
end

end
