function tempIndividualFrameStruct = joincellsParallel(img,frame,tempIndividualFrameStruct,p,l_args,imageForce_)
%this function looks for the cells close enough according to
%parameters and tries to join all such pairs
%global cellList p se rawPhaseData maskdx maskdy ----Ahmad.P May09 2012
%global cellList p se rawPhaseData maskdx maskdy coefPCA coefS N weights dMax

if checkparam(p,'invertimage','algorithm','erodeNum','joindist','joinangle','roiBorder',...
             'meshStep','meshTolerance','meshWidth','splitThreshold')
   disp('Joining cells failed: one or more required parameters are not provided.');
   return
end

imge = img2imge(img,p.erodeNum,l_args.se);
sz = size(img);
    % p.joindist = 5;
    % p.joinangle = 0.2;
%     if length(cellList)<frame || isempty(cellList{frame}), return; end
%     if isempty(lst), lst=1:length(cellList{frame}); end
if ~oufti_isFrameNonEmpty(frame, tempIndividualFrameStruct), return; end

[~, lst] = oufti_getFrame(frame, tempIndividualFrameStruct);
joindist = p.joindist^2;    
imge16 = img2imge16(img,p.erodeNum,l_args.se);
thres = graythreshregParallel(imge,p.threshminlevel,l_args.regionSelectionRect);
bgr = phasebgr(imge,thres,l_args.se,p.bgrErodeNum);
if gpuDeviceCount == 1
    try
        [extDx,extDy,~] = getExtForces(gpuArray(imge),gpuArray(imge16),gpuArray(l_args.maskdx),gpuArray(l_args.maskdy),p,imageForce_);
        extDx = gather(extDx);
        extDy = gather(extDy);
    catch
        [extDx,extDy,~] = getExtForces(imge,imge16,l_args.maskdx,l_args.maskdy,p,imageForce_);
    end
else
    [extDx,extDy,~] = getExtForces(imge,imge16,l_args.maskdx,l_args.maskdy,p,imageForce_);
end
if isempty(extDx), disp('Joining cells failed: unable to get energy'); return; end
    
for cell1 = lst
    cell = oufti_getCellStructure(cell1, frame, tempIndividualFrameStruct);
    if ~isfield(cell,'mesh'),continue;end
    mesh1 = double(cell.mesh);
    if length(mesh1)<=4, continue; end
    for ori1 = [1 size(mesh1,1)]
            %if isempty(cellList{frame}{cell1}), continue; end
        for cell2 = lst
            if cell2<cell1
                    %if isempty(cellList{frame}{cell2}), continue; end
%                     cell = oufti_getCellStructure(cell2, frame, cellList);
               cell = oufti_getCellStructure(cell2, frame, tempIndividualFrameStruct);
                    %mesh2 = cellList{frame}{cell2}.mesh;
                if ~isfield(cell,'mesh'),continue;end
                mesh2 = double(cell.mesh);
                if length(mesh2)<=4, continue; end
                for ori2=[1 size(mesh2,1)]
                    d2 = (mesh1(ori1,1)-mesh2(ori2,1))^2+(mesh1(ori1,2)-mesh2(ori2,2))^2;
                    if d2<joindist
                    a1 = angle(2*mesh1(ori1,1)-mesh1(abs(ori1-3)+1,1)-mesh1(abs(ori1-3)+1,3) + 1i*(2*mesh1(ori1,2)-mesh1(abs(ori1-3)+1,2)-mesh1(abs(ori1-3)+1,4)));
                    a2 = angle(2*mesh2(ori2,1)-mesh2(abs(ori2-3)+1,1)-mesh2(abs(ori2-3)+1,3) + 1i*(2*mesh2(ori2,2)-mesh2(abs(ori2-3)+1,2)-mesh2(abs(ori2-3)+1,4)));
                    a = pi/2-abs(mod(a1-a2,pi)-pi/2);
                        if abs(a)<p.joinangle
                                % Now actuallty do the joining procedire
                            border = p.roiBorder;
                                % roiBox = round([min(min([mesh1(:,[1 3]);mesh2(:,[1 3])]))-border min(min([mesh1(:,[2 4]);mesh2(:,[2 4])]))-border...
                                %                 max(max([mesh1(:,[1 3]);mesh2(:,[1 3])]))-min(min([mesh1(:,[1 3]);mesh2(:,[1 3])]))+2*border...
                                %                 max(max([mesh1(:,[2 4]);mesh2(:,[2 4])]))-min(min([mesh1(:,[2 4]);mesh2(:,[2 4])]))+2*border]);
                            roiBox = [max(round(min(min([mesh1(:,[1 3]);mesh2(:,[1 3])]))-border),1) max(round(min(min([mesh1(:,[2 4]);mesh2(:,[2 4])]))-border),1)];
                            roiBox(3) = min(round(max(max([mesh1(:,[1 3]);mesh2(:,[1 3])]))+border),sz(2)-1)-roiBox(1);
                            roiBox(4) = min(round(max(max([mesh1(:,[2 4]);mesh2(:,[2 4])]))+border),sz(1)-1)-roiBox(2);
                            mask1 = poly2mask([mesh1(:,1);flipud(mesh1(:,3))]-roiBox(1)+1,[mesh1(:,2);flipud(mesh1(:,4))]-roiBox(2)+1,roiBox(4)+1,roiBox(3)+1);
                            mask2 = poly2mask([mesh2(:,1);flipud(mesh2(:,3))]-roiBox(1)+1,[mesh2(:,2);flipud(mesh2(:,4))]-roiBox(2)+1,roiBox(4)+1,roiBox(3)+1);
                            mask3 = poly2mask([mesh1(abs(ori1-2)+1,1) mesh2(abs(ori2-2)+1,1) mesh2(abs(ori2-2)+1,3) mesh1(abs(ori1-2)+1,3)]-roiBox(1)+1,...
                                    [mesh1(abs(ori1-3)+1,2) mesh2(abs(ori2-3)+1,2) mesh2(abs(ori2-3)+1,4) mesh1(abs(ori1-3)+1,4)]-roiBox(2)+1,roiBox(4)+1,roiBox(3)+1);
                            mask4 = poly2mask([mesh1(abs(ori1-2)+1,1) mesh2(abs(ori2-2)+1,3) mesh2(abs(ori2-2)+1,1) mesh1(abs(ori1-2)+1,3)]-roiBox(1)+1,...
                                    [mesh1(abs(ori1-3)+1,2) mesh2(abs(ori2-3)+1,4) mesh2(abs(ori2-3)+1,2) mesh1(abs(ori1-3)+1,4)]-roiBox(2)+1,roiBox(4)+1,roiBox(3)+1);
                            mask = imdilate(min(1,mask1+mask2+mask3+mask4),l_args.se);
                            edg = bwperim(mask);

                            pmap = 1 - edg;
                            f1=true;
                            while f1
                            pmap1 = 1 - edg + imerode(pmap,l_args.se);
                            f1 = max(max(pmap1-pmap))>0;
                            pmap = pmap1;
                            end;
                            pmapEnergy = pmap + 0.1*pmap.^2;
                            pmapDx = imfilter(pmapEnergy,l_args.maskdx); % distance forces
                            pmapDy = imfilter(pmapEnergy,l_args.maskdy); 
                            pmapDxyMax = 10;
                            pmapDx = pmapDx/pmapDxyMax; % normalize to make the max force equal to 1
                            pmapDy = pmapDy/pmapDxyMax;
                                
                                % roiBox2 = roiBox+[1 1 0 0];%[roiBox(2) roiBox(1) roiBox(4)-1 roiBox(3)-1]; % standard format
                            roiImg = imcrop(imge,roiBox);
                            roiExtDx = imcrop(extDx,roiBox);
                            roiExtDy = imcrop(extDy,roiBox);
                            roiBox(3:4) = [size(roiExtDx,2) size(roiExtDx,1)]-1; % !
                            prop = regionprops(bwlabel(mask),'orientation','centroid');
                            theta = prop(1).Orientation*pi/180;
                            x0 = prop(1).Centroid(1);
                            y0 = prop(1).Centroid(2);
                            if p.algorithm==2
                            pcCell0 = [theta;x0;y0;zeros(p.Nkeep+1,1)];
                            elseif p.algorithm==3
                            pcCell0 = [x0;y0;theta;0;zeros(p.Nkeep+1,1)];
                            end

                            if ismember(p.algorithm,[2 3])
                               [pcCell,fitquality] = alignParallel(mask,pmapDx,pmapDy,pmapDx*0,pcCell0,p,true,roiBox,...
                                                                0.5,[frame cell2],l_args.coefPCA,l_args.coefS,l_args.N,...
                                                                l_args.weights,l_args.dMax);
                               [pcCell,fitquality] = alignParallel(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,false,roiBox,...
                                                                thres,[frame cell2],l_args.coefPCA,l_args.coefS,...
                                                                l_args.N,l_args.weights,l_args.dMax);
                            elseif p.algorithm == 1
                                pcCell = align4Initial(roiImg,p);
                             elseif p.algorithm == 4
                                    pcCell = align4I(mask,p);
                                    [pcCell,fitquality] = align4(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,roiBox,...
                                                                 thres,[frame cell2]);
                             end
                             pcCell = box2model(pcCell,roiBox,p.algorithm);
                                % if p.algorithm==2
                                %     pcCell(2) = pcCell(2) + roiBox(1);
                                %     pcCell(3) = pcCell(3) + roiBox(2);
                                % elseif  p.algorithm==3
                                %     pcCell(1) = pcCell(1) + roiBox(1);
                                %     pcCell(2) = pcCell(2) + roiBox(2);
                                % end
                              cCell = model2geom(pcCell,p.algorithm);
                              mesh = model2mesh(cCell,p.meshStep,p.meshTolerance,p.meshWidth);  
                              res=isDivided(mesh-repmat(roiBox(1:2),size(mesh,1),2),roiImg,p.splitThreshold,bgr,p.sgnResize);
                              if length(mesh)<5 || res || isempty(res)
                                 disp(['Tried to join cells ' num2str(cell1) ' and ' num2str(cell2) ' - failed, resplit again'])
                                 continue
                              else
                                  tempIndividualFrameStruct = oufti_addFieldToCellList(cell2, frame, 'mesh', single(mesh), tempIndividualFrameStruct);
                                  if size(pcCell,2)==1, model=reshape(pcCell,[],1); else model=pcCell;end
                                  tempIndividualFrameStruct = oufti_addFieldToCellList(cell2, frame, 'model', single(model), tempIndividualFrameStruct); % TODO: check if works for alg. 2-3
                                  tempIndividualFrameStruct = oufti_addFieldToCellList(cell2, frame, 'box', single(roiBox), tempIndividualFrameStruct);
                                  tempIndividualFrameStruct = oufti_removeCellStructureFromCellList(cell1, frame, tempIndividualFrameStruct);
                                  disp(['Tried to join cells ' num2str(cell1) ' and '...
                                        num2str(cell2) ' - success, cell ' num2str(cell1) ' removed'])

%                                     cellList{frame}{cell2}.mesh = mesh;
%                                     if size(pcCell,2)==1, model=reshape(pcCell,[],1); else model=pcCell; end
%                                     cellList{frame}{cell2}.model = model; % TODO: check if works for alg. 2-3
%                                     cellList{frame}{cell2}.box = roiBox;
%                                     cellList{frame}{cell1} = [];
%                                        oufti_addFieldToCellList(cell2, frame, 'mesh', single(mesh), cellList);
%                                         if size(pcCell,2)==1, model=reshape(pcCell,[],1); else model=pcCell; end
%                                         oufti_addFieldToCellList(cell2, frame, 'model', single(model), cellList); % TODO: check if works for alg. 2-3
%                                         oufti_addFieldToCellList(cell2, frame, 'box', single(roiBox), cellList);
%                                         oufti_removeCellStructureFromCellList(cell1, frame, cellList);  
%                                         gdisp(['Tried to join cells ' num2str(cell1) ' and ' num2str(cell2) ' - success, cell ' num2str(cell1) ' removed'])
                              end
                        end
                    end
                end
            end
        end
    end
end
end




