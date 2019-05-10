function str=getExtraDataMicroFluidic(str)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function str=getExtraDataMicroFluidic(str)
% calculates geometrical properties of detected meshes in structure
% "str", corresponding to a single cell in "cellList", recording to the
% same structure. The properties are: "steplength", "steparea",
% "stepvolume" (length, area, and volume of each segment), "length",
% "area", "volume" (foe the whole cell), "lengthvector" - coordinates
% along cell centerline of the centers of each segment.
%oufti.v0.2.7
%@author:           Oleksii Sliusarenko
%@authos revision:  Ahmad Paintdakhi
%@revision date:    December 19, 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%str:  cellList structure with additional field names of steplength,
%length,lengthvector,area,steparea,volume,stepvolume
%**********Input********:
%CL:  cellList structure
%==========================================================================
    
    for frame = 1:length(str)
    for cells = 1:length(str{frame})
    if isfield(str{frame}{cells},'mesh') && numel(str{frame}{cells}.mesh)>4
        mesh = str{frame}{cells}.mesh;
        lng = size(mesh,1)-1;
% % %         if ~isfield(str{frame}{cells},'polarity'), str{frame}{cells}.polarity=0; end

        %length
        str{frame}{cells}.steplength = edist(mesh(2:end,1)+mesh(2:end,3),mesh(2:end,2)+mesh(2:end,4),...
            mesh(1:end-1,1)+mesh(1:end-1,3),mesh(1:end-1,2)+mesh(1:end-1,4))/2;
        str{frame}{cells}.length = sum(str{frame}{cells}.steplength);

        str{frame}{cells}.lengthvector = cumsum(str{frame}{cells}.steplength)-str{frame}{cells}.steplength/2;

        % area
        steparea = [];
        parfor i=1:lng, steparea=[steparea;polyarea([mesh(i:i+1,1);mesh(i+1:-1:i,3)],[mesh(i:i+1,2);mesh(i+1:-1:i,4)])]; end
        str{frame}{cells}.area = sum(steparea);
        str{frame}{cells}.steparea = steparea;

        % volume
        d = edist(mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4));
        str{frame}{cells}.stepvolume = (d(1:end-1).*d(2:end) + (d(1:end-1)-d(2:end)).^2/3).*str{frame}{cells}.steplength*pi/4;
        str{frame}{cells}.volume = sum(str{frame}{cells}.stepvolume);
% % %     elseif isfield(str{frame}{cells},'contour') && length(str{frame}{cells}.contour)>1
% % %         contour = str{frame}{cells}.contour;
% % %         lng = size(contour,1);
% % %         str{frame}{cells}.length = sqrt(max(max( (repmat(contour(:,1),1,lng)-repmat(contour(:,1)',lng,1)).^2 + ...
% % %                                    (repmat(contour(:,2),1,lng)-repmat(contour(:,2)',lng,1)).^2)));
% % %         str{frame}{cells}.area = polyarea(contour(:,1),contour(:,2));
    end
    end
    end
end

function d=edist(x1,y1,x2,y2)
    % complementary for "getextradata", computes the length between 2 points
    d=sqrt((x2-x1).^2+(y2-y1).^2);
end