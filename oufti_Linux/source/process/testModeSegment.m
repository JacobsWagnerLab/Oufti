function p = testModeSegment(frame,processregion,p)


global rawPhaseData se imageForce 

if ~isempty(imageForce(frame).forceX)
    for ii = 1:size(rawPhaseData,3)
        imageForce(ii).forceX = [];
        imageForce(ii).forceY = [];
    end
end
if frame>size(rawPhaseData,3), disp('Segmentation failed: no phase images loaded'); return; end

maxRawPhaseDataValue = max(max(max(rawPhaseData)));

p = segmentation(maxRawPhaseDataValue,rawPhaseData(:,:,frame),se,processregion,p);
% % % if ~isempty(processregion)
% % %    crp = regions0(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3)));
% % %    regions0 = regions0*0;
% % %    regions0(processregion(2)+(0:processregion(4)),processregion(1)+(0:processregion(3))) = crp;
% % %    regions0 = bwlabel(regions0>0,4);
% % %    handles.segmentationImagePanel = imshow(imcrop(regions0,processregion)>0,[]);
% % % end 
% % figure
% % if ~isempty(processregion)
% %    imshow(regions0>0,[]);set(gca,'pos',[0 0 1 1])
% % else
% %    imshow(imcrop(regions0,processregion)>0,[]);set(gca,'pos',[0 0 1 1])
% % end



end
    
    





