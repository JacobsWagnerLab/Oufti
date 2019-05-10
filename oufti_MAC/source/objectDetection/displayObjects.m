function displayObjects(currentFrame)
global cellList handles 

dispMeshColor = [0 1 0];
if handles.color1.Value == 1, dispMeshColor= [1 1 1]; end
if handles.color2.Value == 1, dispMeshColor= [0 0 0]; end
if handles.color3.Value == 1, dispMeshColor=[0 1 0]; end
if handles.color4.Value == 1, dispMeshColor=[1 1 0]; end


ax = get(get(handles.impanel,'children'),'children');
ax(2) = get(handles.himage,'parent');
set(ax(1),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add');
set(ax(2),'TickLength',[0 0],'XTickLabel',{},'YTickLabel',{},'nextplot','add');

for ii = 1:length(ax(2).Children)
    try
        ax(1).Children(ii).XData = [];
        ax(1).Children(ii).YData = [];
        ax(2).Children(ii).XData = [];
        ax(2).Children(ii).YData = [];
    catch
    end
end
for ii = 1:length(cellList.meshData{currentFrame})
    try
        if isfield(cellList.meshData{currentFrame}{ii},'objects') && ~isempty(cellList.meshData{currentFrame}{ii}.objects) && ...
                isfield(cellList.meshData{currentFrame}{ii}.objects,'outlines') && ~isempty(cellList.meshData{currentFrame}{ii}.objects.outlines) 
            for jj = 1:length(cellList.meshData{currentFrame}{ii}.objects.outlines)
               plot(ax(1),cellList.meshData{currentFrame}{ii}.objects.outlines{jj}(:,1),cellList.meshData{currentFrame}{ii}.objects.outlines{jj}(:,2),'color','m');
               plot(ax(2),cellList.meshData{currentFrame}{ii}.objects.outlines{jj}(:,1),cellList.meshData{currentFrame}{ii}.objects.outlines{jj}(:,2),'color','m');
               
            end
        end
    catch err
    end
    plot(ax(1),cellList.meshData{currentFrame}{ii}.model(:,1),cellList.meshData{currentFrame}{ii}.model(:,2),'color',dispMeshColor);
    plot(ax(2),cellList.meshData{currentFrame}{ii}.model(:,1),cellList.meshData{currentFrame}{ii}.model(:,2),'color',dispMeshColor);
end


end