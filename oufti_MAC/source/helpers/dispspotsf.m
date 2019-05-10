function dispspotsf(imgs,slist,frame)
% dispspotsf(images,spotList,frame)
% 
% This functions displays the spots detected with SpotFinderF into a new 
% figure.
%
% images - stack of images, e.g. obtained by loadimageseries command.
% spotList - the output array of spotFinderF
% frame - the frame to output

figure
imshow(imgs(:,:,frame),[])
set(gca,'pos',[0 0 1 1],'box','off')
hold on
for spot=1:length(slist{frame})
    plot(slist{frame}{spot}.x,slist{frame}{spot}.y,'.r')
end