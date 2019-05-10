function [pcCell,cCell] = splitted2model(mesh,p,se,maskdx,maskdy)
% This function fits the model to a half of a splitted cell defined by mesh
% such that the Nth model point corresponds to the top row of mesh
if size(mesh,1)<4, pcCell = -1; cCell = -1; return; end
mesh = [repmat(([1;2;3]*mesh(1,1:2)+[3;2;1]*mesh(1,3:4))/4,1,2);mesh];
%global se maskdx maskdy;
border = p.roiBorder;
roiBox = round([min(min(mesh(:,[1 3])))-border min(min(mesh(:,[2 4])))-border...
                max(max(mesh(:,[1 3])))-min(min(mesh(:,[1 3])))+2*border...
                max(max(mesh(:,[2 4])))-min(min(mesh(:,[2 4])))+2*border]);
edg = zeros(roiBox(3:4)+1);
edg(sub2ind(roiBox(3:4)+1,round([mesh(:,1);mesh(:,3)]-roiBox(1)),round([mesh(:,2);mesh(:,4)]-roiBox(2)))) = 1;
edg = edg';

pmap = 1 - edg;
f1=true;
while f1
    pmap1 = 1 - edg + imerode(pmap,se);
    f1 = max(max(pmap1-pmap))>0;
    pmap = pmap1;
end;

pmapEnergy = pmap + 0.1*pmap.^2;
pmapDx = imfilter(pmapEnergy,maskdx); % distance forces
pmapDy = imfilter(pmapEnergy,maskdy); 
pmapDxyMax = 10;
pmapDx = pmapDx/pmapDxyMax; % normalize to make the max force equal to 1
pmapDy = pmapDy/pmapDxyMax;

mask = poly2mask([mesh(:,1);flipud(mesh(:,3))]-roiBox(1),[mesh(:,2);flipud(mesh(:,4))]-roiBox(2),roiBox(4)+1,roiBox(3)+1);

for i=1%:2
    theta = pi-angle(mesh(end,1)+mesh(end,3)-mesh(1,1)-mesh(1,3)+...
              j*(mesh(end,2)+mesh(end,4)-mesh(1,2)-mesh(1,4)));
    x0 = mean(mean(mesh(:,[1 3])))-roiBox(1);
    y0 = mean(mean(mesh(:,[2 4])))-roiBox(2);
    
    if p.algorithm==2
        pcCell0 = [theta;x0;y0;zeros(p.Nkeep+1,1)];
    elseif p.algorithm==3
        pcCell0 = [x0;y0;theta;0;zeros(p.Nkeep+1,1)];
    elseif p.algorithm==4
        %pcCell0 = align4I(mask,p);
    end

    % Making first variant of the model
    if ismember(p.algorithm,[2 3])
        % first approximation - to the exact shape of the selected region
        [pcCell,fitquality] = align(mask,pmapDx,pmapDy,pmapDx*0,pcCell0,p,true,roiBox,0.5,[0 0 1]);
        % adjustment of the model to the external energy map
        %[pcCell,fitquality] = align(roiImg,roiExtDx,roiExtDy,roiExtDx*0,pcCell,p,false,roiBox,thres,[0 0]);
    elseif p.algorithm == 4
        pcCell = align4I(mask,p);
        fitquality = 0;
        %[pcCell,fitquality] = align4(roiImg,roiExtDx,roiExtDy,pmap*0,pcCell,p,roiBox,thres,[0 0]);
    end
    %gdisp(['fitquality aligning = ' num2str(fitquality)])
            
    % converting from box to global coordinates
    pcCell = box2model(pcCell,roiBox,p.algorithm);
    % obtaining the shape of the cell in geometrical representation
    cCell = model2geom(pcCell,p.algorithm);
    if isempty(cCell), return; end

    if (cCell(end,1)-mean(mesh(1,[1 3])))^2+(cCell(end,2)-mean(mesh(1,[2 4])))^2 >...
        (cCell(end,1)-mean(mesh(end,[1 3])))^2+(cCell(end,2)-mean(mesh(end,[2 4])))^2
        if p.algorithm==2
            pcCell(1) = pcCell(1) + pi;
        elseif p.algorithm==3
            pcCell(3) = pcCell(3) + pi;
        end
    else
        break;
    end
end
gdisp(['splitting fitquality = ' num2str(fitquality)])
end