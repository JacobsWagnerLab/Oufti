function imageHandle = dispspots(img0,spotlist,plgx,plgy,lst,imageHandle,frame,spots)
global handles

screenSize = get(0,'ScreenSize');
pos = get(handles.maingui,'position');
pos = [max(pos(1),1) max(1,min(pos(2),...
       screenSize(4)-20-max(pos(4),600))) max(pos(3:4),[1000 600])];
set(imageHandle.fig,'pos',[17 170 pos(3)-1000+700 pos(4)-800+600]) 
g = get(imageHandle.fig,'children');
% %             p = get(h.fig,'pos');
% %             set(h.fig,'Name',['Frame ' num2str(frame) ' cell ' num2str(cell)])
% %             p4old = p(4);
% %             p(4)=ceil(p(3)*size(img0,1)/size(img0,2));
% %             if p(2)+p4old-p(4)<0, scale=(p(2)+p4old)/p(4); p(3:4)=p(3:4)*scale; end
% %             p(2)=p(2)+p4old-p(4);
delete(g);
imageHandle.ax = axes('parent',imageHandle.fig);
imageHandle.himage = imshow(img0,[],'parent',imageHandle.ax);
%                 imshow(img0,[],'parent',h.ax)
set(imageHandle.ax,'pos',[0 0 1 1],'NextPlot','add')
plot(imageHandle.ax,plgx,plgy,'Color',[0 0.7 0])
imageHandle.spots = [];
for q=1:length(lst)
    if lst(q)
       color = [1 0.1 0];
    else
       color = [0 0.8 0];
    end
    spt = plot(imageHandle.ax,spotlist(q,9),spotlist(q,8),'.','Color',color);
    imageHandle.spots = [imageHandle.spots spt];
end
set(imageHandle.ax,'pos',[0 0 1 1],'NextPlot','replace')
set(imageHandle.fig,'pos',[17 170 pos(3)-1000+700 pos(4)-800+600]) 

end %function imageHandle