function res=intersections(coord)
    % determines if a contour (Nx2 array of x-y pairs of coordinates) is
    % self-intersecting
    if isempty(coord), res = []; return; end
    alpha = 0.01;
    c1 = (coord+circShiftNew(coord,1))/2;
    c2 = alpha*(coord-circShiftNew(coord,1));
    IN = inpolygon(-c1(:,1).*c2(:,2),c1(:,2).*c2(:,1),coord(:,1),coord(:,2));
    if length(IN)~=sum(IN) && sum(IN)~=0, res=true; else res=false; end
    %if find(IN,1), res=true; else res=false; end
end