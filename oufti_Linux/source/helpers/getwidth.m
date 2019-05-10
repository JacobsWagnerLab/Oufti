dstlist = [];
for frame=1:length(cellList)
    for cell=1:length(cellList{frame})
        if ~isempty(cellList{frame}{cell}) && length(cellList{frame}{cell}.mesh)>4
            mesh = cellList{frame}{cell}.mesh;
            dst = max(sqrt((mesh(:,1)-mesh(:,3)).^2+(mesh(:,2)-mesh(:,4)).^2));
            dstlist = [dstlist dst];
        end
    end
end