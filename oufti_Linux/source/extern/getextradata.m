function cellStructure=getextradata(cellStructure)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cellStructure=getextradata(cellStructure)
%oufti.v0.3.0
%@author:  oleksii sliusarenko
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%cellStructure: updated cellStructure with extra added fields
%**********Input********:
%cellStructure: cell structure that needs to be updated with extra fields.
%=========================================================================
% PURPOSE:
% calculates geometrical properties of detected meshes in structure
% "str", corresponding to a single cell in "cellList", recording to the
% same structure. The properties are: "steplength", "steparea",
% "stepvolume" (length, area, and volume of each segment), "length",
% "area", "volume" (foe the whole cell), "lengthvector" - coordinates
% along cell centerline of the centers of each segment.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
   
if isempty(cellStructure), return; end
if isfield(cellStructure,'mesh') && length(cellStructure.mesh)>=4
   mesh = cellStructure.mesh;
   lng = size(mesh,1)-1;
   if ~isfield(cellStructure,'polarity'), cellStructure.polarity=0; end

   %length
   cellStructure.steplength = edist(mesh(2:end,1)+mesh(2:end,3),mesh(2:end,2)+mesh(2:end,4),...
                              mesh(1:end-1,1)+mesh(1:end-1,3),mesh(1:end-1,2)+mesh(1:end-1,4))/2;
   cellStructure.length = sum(cellStructure.steplength);
   cellStructure.lengthvector = cumsum(cellStructure.steplength)-cellStructure.steplength/2;

   % area
   steparea = zeros(lng,1);
   for i=1:lng
       steparea(i,1) = polyarea([mesh(i:i+1,1);mesh(i+1:-1:i,3)],[mesh(i:i+1,2);mesh(i+1:-1:i,4)]); 
   end
   cellStructure.area = sum(steparea);
% % %     cellStructure.area = polyarea([mesh(1:lng+1,1);mesh(lng+1:-1:1,3)],[mesh(1:lng+1,2);mesh(lng+1:-1:1,4)]);
   cellStructure.steparea = steparea;

   % volume
   d = edist(mesh(:,1),mesh(:,2),mesh(:,3),mesh(:,4));
   cellStructure.stepvolume = (d(1:end-1).*d(2:end) + (d(1:end-1)-d(2:end)).^2/3).*cellStructure.steplength*pi/4;
   cellStructure.volume = sum(cellStructure.stepvolume);
elseif isfield(cellStructure,'model') && length(cellStructure.model)>1
       contour = cellStructure.model;
       lng = size(contour,1);
       cellStructure.length = sqrt(max(max( (repmat_(contour(:,1),1,lng)-repmat_(contour(:,1)',lng,1)).^2 + ...
                              (repmat_(contour(:,2),1,lng)-repmat_(contour(:,2)',lng,1)).^2)));
       cellStructure.area = polyarea(contour(:,1),contour(:,2));
end

end

function d=edist(x1,y1,x2,y2)
    % complementary for "getextradata", computes the length between 2 points
    d=sqrt((x2-x1).^2+(y2-y1).^2);
end