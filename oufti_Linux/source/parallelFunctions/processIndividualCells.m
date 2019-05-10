function cellStructure = processIndividualCells(previousStruct,cellNumber,listParameter,l_args,...
         imageMatrix,imageMatrixErodded,extDx,extDy,allMap,thres,frame,isShiftFrame,l_shiftframes,isIndependentFrame)

% I now change the meaning of the argument cellLength. It used to be the
% full cell length matrix, but to reduce memory usage (and to avoid an
% error in createJob) it will henceforth contain only the cell length
% of the current cell and only <= 20 frames back from the current frame.

%if isstruct(currentCell) && isfield(currentCell, 'model')
if isempty(previousStruct),cellStructure = []; return; end
try
%currentCellModel=currentCell.model;
% unpack structure with some parameters. A bit ugly.
 %load('C:\projects\oufti\divisionFunctions\cell_div_templates6.mat');
l_se  = l_args.se;
l_coefPCA = l_args.coefPCA;
l_mCell   = l_args.mCell;
l_coefS   = l_args.coefS;
l_N       = l_args.N;
l_weights = l_args.weights;
l_dMax    = l_args.dMax;
l_maskdx  = l_args.maskdx;
l_maskdy  = l_args.maskdy;
bgr = phaseBackground(im2double(imageMatrixErodded),thres,l_se,listParameter.bgrErodeNum);

% get previous frame data
if size(previousStruct.model,2)==1 || size(previousStruct.model,2)==1
   previousCellModel = reshape(previousStruct.model,[],1);
else
    previousCellModel = previousStruct.model;
end

if isIndependentFrame
       %creates mesh for the cellContour.
        mesh = model2MeshForRefine(previousCellModel,listParameter.meshStep,listParameter.meshTolerance,listParameter.meshWidth);
        if  size(mesh,2)==4
           previousCellModel = [mesh(:,1:2);flipud(mesh(:,3:4))];
        else
           previousCellModel = [];
        end
        currentCellMesh = [];
        %make cell contour counterclockwise.
        previousCellModel = makeccw(previousCellModel);
        previousCellModel = box2model(previousCellModel,previousStruct.box,listParameter.algorithm);
else
    currentCellMesh = previousStruct.mesh;
end

% find cell poles and adjust currentCellMesh
previousCellGeometry = model2geom(previousCellModel,listParameter.algorithm,l_coefPCA,l_mCell);
%currentCellMesh = previousStruct.mesh;
% % % strelBox = strel('rectangle',[20 20]);
%previousRoiBox = previousStruct.box;
if ~isempty(previousCellGeometry)
   roiBox(1:2) = round(max(min(previousCellGeometry(:,1:2))-listParameter.roiBorder,1));
   roiBox(3:4) = min(round(max(previousCellGeometry(:,1:2))+listParameter.roiBorder),...
                     [size(imageMatrix,2) size(imageMatrix,1)])-roiBox(1:2);
   if min(roiBox(3:4))<=0, previousCellGeometry=[]; end
end

if ~isempty(previousCellGeometry)
    if ~isIndependentFrame
       previousCellModel = align4IM(previousStruct.mesh,listParameter);
    end
       previousCellModelRoi = model2box(previousCellModel,roiBox,listParameter.algorithm);

    
% crop the image and the energy/force maps
    roiImageMatrix = imcrop(imageMatrixErodded,roiBox);
    %roiimageMatrix2 = double(imcrop(imageMatrix,roiBox));
    %roiExtEnergy = imcrop(extEnergy,roiBox);
    roiExtDx = imcrop(extDx,roiBox);
    roiExtDy = imcrop(extDy,roiBox);
    roiAllMap = imcrop(allMap,roiBox);
    % build pmap (for cell repulsion)
    
    if size(currentCellMesh,2)==4
       roiAllMap = max(0,roiAllMap - ...
       imdilate(roipoly(roiAllMap,[currentCellMesh(:,1);flipud(currentCellMesh(:,3))]-...
       roiBox(1),[currentCellMesh(:,2);flipud(currentCellMesh(:,4))]-roiBox(2)),l_se));
    else
        roiAllMap = max(0,roiAllMap - imdilate(roipoly(roiAllMap,previousCellModel(:,1)-roiBox(1),previousCellModel(:,2)-roiBox(2)),l_se));
    end

    pmap = roiAllMap;
    f1=true;
    while f1
          pmap1 = roiAllMap + imerode(pmap,l_se);
          f1 = max(max(pmap1-pmap))>0;
          pmap = pmap1;
    end;
    pmapDx = imfilter(pmap,l_maskdx,'replicate'); % distance forces
    pmapDy = imfilter(pmap,l_maskdy,'replicate');
    roiExtDx = roiExtDx + listParameter.neighRep*pmapDx;
    roiExtDy = roiExtDy + listParameter.neighRep*pmapDy;
    t_l_p = listParameter; % thread local
    if ismember(listParameter.algorithm,[2 3])
       [previousCellModelRoi,fitquality] = alignParallel(roiImageMatrix,roiExtDx,roiExtDy,...
										   roiAllMap,previousCellModelRoi,listParameter,...
										   false,roiBox,thres,[frame cellNumber],...
                                           l_coefPCA,l_coefS,l_N,l_weights,l_dMax);
    elseif (listParameter.algorithm == 4) && ~isIndependentFrame
%             tic;
% % %            roiImageFilter = fspecial('gaussian',[ 9 9],0.7);
% % %            roiImageMatrix = imfilter(roiImageMatrix,roiImageFilter,'replicate');

% % % % roiImageMatrixGPU= gpuArray(roiImageMatrix);
% % % % roiExtDxGPU= gpuArray(roiExtDx);
% % % % roiExtDyGPU= gpuArray(roiExtDy);
% % % % roiAllMapGPU= gpuArray(roiAllMap);
% % % % previousCellModelRoiGPU= gpuArray(previousCellModelRoi);
% % % % roiBoxGPU= gpuArray(roiBox);
% % % % lastArrayGPU = gpuArray([frame cellNumber]);
% % % % [previousCellModelRoi, fitquality] = align4(roiImageMatrixGPU,roiExtDxGPU,roiExtDyGPU,...
% % % % 												roiAllMapGPU,previousCellModelRoiGPU,...
% % % % 												t_l_p,roiBoxGPU,thres,lastArrayGPU);%toc;
           [previousCellModelRoi, fitquality] = align4(roiImageMatrix,roiExtDx,roiExtDy,...
												roiAllMap,previousCellModelRoi,...
												t_l_p,roiBox,thres,[frame cellNumber]);%toc;
                                            
           
% % %            tic;
% % %            [cellWidth,Tx,Ty,hcorr,rgt,wdt,A,B,previousCellModelRoi] = align4_InitialValues(roiImageMatrix,previousCellModelRoi,t_l_p);
% % %            if isempty(previousCellModelRoi), cellStructure = []; return; end
% % %            [previousCellModelRoi(:,1),previousCellModelRoi(:,2)] = align4_(roiImageMatrix,roiExtDx,roiExtDy,...
% % %                                                 roiAllMap,double(previousCellModelRoi(:,1)),double(previousCellModelRoi(:,2)),...
% % %                                                 roiBox,thres,'linear',0,t_l_p.cellwidth,t_l_p.rigidityRange,...
% % %                                                 t_l_p.rigidityRangeB,t_l_p.scaleFactor,t_l_p.imageforce,t_l_p.fitMaxIter,...
% % %                                                 t_l_p.attrRegion,t_l_p.thresFactorF,t_l_p.attrPower,t_l_p.attrCoeff,t_l_p.repCoeff,...
% % %                                                 t_l_p.repArea,t_l_p.areaMax,t_l_p.neighRepA,t_l_p.wspringconst,t_l_p.rigidity,t_l_p.rigidityB,...
% % %                                                  t_l_p.horalign,t_l_p.eqaldist,t_l_p.fitStep,t_l_p.moveall,t_l_p.fitStepM,cellWidth,Tx,Ty,...
% % %                                                  hcorr,rgt,wdt,A',B');toc;
             
    
    elseif (listParameter.algorithm == 4) && isIndependentFrame
        [previousCellModelRoi, fitquality] = align4Manual(roiImageMatrix,roiExtDx,roiExtDy,...
												roiAllMap,previousCellModelRoi,...
												t_l_p,roiBox,thres,[frame cellNumber]);%toc;
    end
    % TEST HERE

    %disp(['fitting cell ' num2str(cellNumber) ' ' ' --- passed and saved'])
    % obtaining the shape of the cell in geometrical representation
    previousCellModel    = box2model(previousCellModelRoi,roiBox,t_l_p.algorithm);
    previousCellGeometry = model2geom(previousCellModel,t_l_p.algorithm,l_coefPCA,l_mCell);
    %try splitting
    if listParameter.algorithm==4, isct=0; else isct = intersections(previousCellGeometry); end
    cellarea = 0;
    res = 0;
% %     meshWidth = [ 11 15 17 20 21 23 25 27 29 31];
% %     meshTolerance = [ 0.001 0.0001 0.00001 0.000001];
    if ~isempty(isct) && ~isct
       warning('off','MATLAB:TriRep:PtsNotInTriWarnId')
       if ~isIndependentFrame
            currentCellMesh = model2mesh(double(previousCellGeometry),t_l_p.meshStep,...
                                    t_l_p.meshTolerance,t_l_p.meshWidth);
       else
           currentCellMesh = model2MeshForRefine(double(previousCellGeometry),t_l_p.meshStep,...
                                    t_l_p.meshTolerance,t_l_p.meshWidth);
       end

       if length(currentCellMesh)>1
%           cellarea = polyarea([currentCellMesh(:,1);flipud(currentCellMesh(:,3))],...
%                               [currentCellMesh(:,2);flipud(currentCellMesh(:,4))]);
          roiCurrentCellMesh = currentCellMesh - repmat(roiBox([1 2 1 2])-1,...
                               size(currentCellMesh,1),1);
          %thres = grayThreshold(im2double(imageMatrix),listParameter.threshminlevel);
          %res=isDivided(roiCurrentCellMesh,roiImageMatrix,t_l_p.splitThreshold,bgr);
          res=isDivided(roiCurrentCellMesh,roiImageMatrix,t_l_p.splitThreshold,bgr,...
                        listParameter.sgnResize);
% % %           roiImageMatrixNotErodded = imcrop(imageMatrix,roiBox) - (65536*bgr);
% % %           [res lamda_div] = divide_check3b(roiImageMatrix,roiCurrentCellMesh,mC1,mC2,...
% % %                                             w,thres,roiBox,bgr);
% % %           if res > 0 
% % %              corners = harrisMinEigen_(im2single(roiImageMatrix),roiCurrentCellMesh,bgr,'MinQuality',0.12,'FilterSize',7);
% % %           elseif res==-1
% % %               currentCellMesh=0; 
% % %           end
       end
    end
else
    cellStructure = []; return;
end

cellStructure = previousStruct; 
cellStructure.model = cellStructure.model;
cellStructure.res=res;
cellStructure.mesh=currentCellMesh;
cellStructure.pcCell=previousCellModel;
cellStructure.cCell=previousCellGeometry;
cellStructure.isct=isct;
cellStructure.fitquality= fitquality;
cellStructure.roiBox=roiBox;
cellStructure.roiImg=roiImageMatrix;
%cellStructure.roiExtEnergy=roiExtEnergy;
cellStructure.roiExtDx=roiExtDx;
cellStructure.roiExtDy=roiExtDy;
cellStructure.roiAmap=roiAllMap;
%cellStructure.lambda_div=lambda_div;
%cellStructure.cellarea = cellarea; 
catch err
      disp(['Error in ' err.stack(1).file ' in line ' num2str(err.stack(1).line)])
      cellStructure = []; return;
end

end
        