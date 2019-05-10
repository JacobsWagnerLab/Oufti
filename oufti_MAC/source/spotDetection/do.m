function cellList = convertAutoSelectionToCellList(ssb1,sizeOfImage)
count = 1;
cellList.meshData = cell(1,max(cat(2,ssb1.frames)));
cellList.cellId = cell(1,max(cat(2,ssb1.frames)));
ids = cat(1,ssb1.id);

for frame = 1:length(cellList.meshData)
    for ii = 1:length(ids)
   
        dd = cat(1,ssb1(ii).frames);
        xx = frame == dd;
        if sum(xx) == 0,  continue;end
        cellList.meshData{frame}{count}.mesh = ssb1(ii).meshes{xx};
        cellList.meshData{frame}{count}.ancestors = ssb1(ii).ancestor;
        cellList.meshData{frame}{count}.descendants = ssb1(ii).progeny;
        cellList.meshData{frame}{count}.model = [cellList.meshData{frame}{count}.mesh(:,1:2);flipud(cellList.meshData{frame}{count}.mesh(2:end-1,3:4))];
        roiBox(1:2) = round(max(min(cellList.meshData{frame}{count}.model(:,1:2))-25,1));
        roiBox(3:4) = min(round(max(cellList.meshData{frame}{count}.model(:,1:2))+25),...
                     [sizeOfImage(2) sizeOfImage(1)])-roiBox(1:2);
        cellList.meshData{frame}{count}.box = roiBox;
        cellList.cellId{frame} = [cellList.cellId{frame} ids(ii)];
        count = count + 1;
    end   
    count = 1;    
end

end