function [cell,cell2] = model2geom(pcc,alg,coefPCA,mCell)
% cell - cell geometry
% cell2 - unbent & unrotated cell geometry
%global coefPCA mCell

% This function switches paramertic representation of the model to
% geometrical one
    if length(pcc)<=1, cell=[];cell2=[]; return; end
    if (alg==2 || alg==3) && (isempty(coefPCA) || isempty(mCell)), cell=[];cell2=[]; return; end
    if alg==2
        % pcc structure: [theta, x, y, size, Nkeep parameters from PCA]
        cell2 = mCell+reshape(coefPCA*[0;0;reshape(pcc(4:end),[],1)],[],2);
        cell = M(cell2,pcc(1));
        cell(:,1) = cell(:,1)+pcc(2);
        cell(:,2) = cell(:,2)+pcc(3);
    elseif alg==3
        % pcc structure: [x, y, theta, curvature, length, Nkeep parameters from PCA]
        cell2 = mCell+reshape(coefPCA*reshape(pcc(5:end),[],1),[],2); % ???
        cellT = B(cell2,pcc(4)); % cellT = B(cell2,pcc(4));
        cell = M(cellT,pcc(3));
        cell(:,1) = cell(:,1)+pcc(1);
        cell(:,2) = cell(:,2)+pcc(2);
    elseif alg==4 || alg == 1
        cell = pcc;
        cell2 = pcc;
    end
end