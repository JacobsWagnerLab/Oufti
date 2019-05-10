function [mask1,mask2] = splitonereg(inputImage,imageHistory,imageCounter,p)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function [mask1,mask2] = splitonereg(img,imageHistory,imageCounter,p)
%oufti.v0.3.2
%@author:  oleksii sliusarenko
%modified: July 26, 2013  --- Ahmad J. Paintdakhi
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%mask1: first region after split
%mask2: second region after split(this could be more than one cell).
%**********Input********:
%img:   current roiImage that is used for splitting
%imageHistory:  not used.
%imageCounter:  the number of times this routine is called for splitting.
%p: parameter structure.
%=========================================================================
% PURPOSE:
% this function splits a region along the inverse drainage divide 
% containing the lowest pass between any two peaks inside of a region 
% find watersheds of the inverted image
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

se = strel('diamond',2);

minLevelDecrease = 0;
if p.wShedNum > 6000, levelDecrease = 1000; else levelDecrease = 500; end
if imageCounter >=1, minLevelDecrease = levelDecrease*imageCounter; end
%%%if imageCounter >=1, img = imopen(img,se);end
img = im2uint16(inputImage);
img = imfill(img,'holes');
% % % PSF = fspecial('gaussian',3,3);
% % % img = imfilter(img,PSF,'symmetric','conv');
mask1 = [];
mask2 = [];
mask = img~=0;
img = imcomplement(img);
img = imhmin(img,p.wShedNum - minLevelDecrease);
wshed = mask.*double(watershed(img));
%---------------------------------------------------------------------
if p.displayW == 1
    f = figure('Position',[500+imageCounter+50 350 600 400]);
    h = uicontrol('Position',[5 20 100 40],'String','Continue',...
                  'Callback','uiresume(gcbf)');
    imshow(wshed,[]);
    uiwait(gcf);
    close(f);
    java.lang.Thread.sleep(1000);  %wait one second   
end
nwsheds = max(wshed(:));
if nwsheds == 1, mask1 = wshed==1; mask2 = []; return;end
if nwsheds > 1 
    mask1 = wshed==1;
    mask2 = wshed - mask1;
end

if ~isempty(mask1), mask1 = imfill(mask1,'holes');end
if ~isempty(mask2),mask2 = imfill(mask2,'holes');end
mask1 = imclose(mask1,se);
mask2 = imclose(mask2,se);
end



% % % % % % % % se1 = strel('disk',2);
% % % % % % % % se2 = strel('diamond',2);
% % % % % % % % % % % minLevelDecrease = 0;
% % % % % % % % % % % if p.wShedNum > 6000, levelDecrease = 1000; else levelDecrease = 500; end
% % % % % % % % % % % if imageCounter >=1, minLevelDecrease = levelDecrease*imageCounter; end
% % % % % % % % %%%if imageCounter >=1, img = imopen(img,se);end
% % % % % % % % % % % img = im2uint16(img);
% % % % % % % % % % % img = imfill(img,'holes');
% % % % % % % % % % % PSF = fspecial('gaussian',3,3);
% % % % % % % % % % % img = imfilter(img,PSF,'symmetric','conv');
% % % % % % % % %%%thres = graythreshreg(img);
% % % % % % % % 
% % % % % % % % img = inputImage;
% % % % % % % % bw2 = ~bwareaopen(~img,10);
% % % % % % % % bw2 = imfill(bw2,'holes');
% % % % % % % % bw2 = imerode(bw2,se2);
% % % % % % % % bw2 = imdilate(bw2,se2);
% % % % % % % % % % % D = -bwdist(~bw2);
% % % % % % % % % % % mask = imextendedmin(D,4-imageCounter);
% % % % % % % % % % % %mask = imdilate(mask,se2);
% % % % % % % % % % % D2 = imimposemin(D,mask);
% % % % % % % % % % % Ld2 = watershed(D2);
% % % % % % % % % % % mask1 = [];
% % % % % % % % % % % mask2 = [];
% % % % % % % % % % % mask = img~=0;
% % % % % % % % % % % % % % img = imcomplement(img);
% % % % % % % % % % % % % % img = imhmin(img,p.wShedNum - minLevelDecrease);
% % % % % % % % % % % % % % wshed = mask.*im2double(watershed(img));
% % % % % % % % % % % wshed = bwlabel(mask.*im2double(Ld2),4);
% % % % % % % % % % % %---------------------------------------------------------------------
% % % % % % % % % % % if p.displayW == 1
% % % % % % % % % % %     f = figure('Position',[500+imageCounter+50 350 600 400]);
% % % % % % % % % % %     h = uicontrol('Position',[5 20 100 40],'String','Continue',...
% % % % % % % % % % %                   'Callback','uiresume(gcbf)');
% % % % % % % % % % %     imshow(wshed,[]);
% % % % % % % % % % %     uiwait(gcf);
% % % % % % % % % % %     close(f);
% % % % % % % % % % %     java.lang.Thread.sleep(1000);  %wait one second   
% % % % % % % % % % % end
% % % % % % % % regions = splitOverlappedRegions(img);
% % % % % % % % nwsheds = max(regions(:));
% % % % % % % % if nwsheds == 1, mask1 = regions==1; mask2 = []; return;end
% % % % % % % % if nwsheds > 1 
% % % % % % % %     mask1 = regions==1;
% % % % % % % %     mask2 = regions - mask1;
% % % % % % % %     
% % % % % % % % end

% % % if ~isempty(mask1), mask1 = imfill(mask1,'holes');end
% % % if ~isempty(mask2),mask2 = imfill(mask2,'holes');end
% % % mask1 = imclose(mask1,se);
% % % mask2 = imclose(mask2,se);
% % % end

