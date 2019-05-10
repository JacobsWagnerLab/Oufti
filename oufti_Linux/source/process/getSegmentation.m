function result = getSegmentation(im,se)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function result = getSegmentation(im,se)
%oufti.v0.2.9
%@author:  Ahmad J Paintdakhi
%@date:    March 05 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%result:  segmented image
%**********Input********:
%im:    a single image that need to be filtered
%se:    strobel constant
%=========================================================================
% PURPOSE:
% This function determines and labels regions on an image (im) using edge
% detection and thresholding (tractor - factor compared to automatic
% threshols, larger values - smaller regions)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

global handles
% % % thresh = graythreshreg(im);
% % % im = im2uint8(1./(1+exp(8*(thresh - im2double(im)))));
%im = imadjust(im,stretchlim(im),[]);
imge = img2imge(im,str2double(get(handles.SegErodeNum,'string')),se);
im16 = img2imge16(im,str2double(get(handles.SegErodeNum,'string')),se);
thres = graythreshreg(imge,get(handles.SegThreshMinLevel,'value'));
thres2 = max(0,min(1,thres*get(handles.SegThreshFactorM,'value')));
if thres * get(handles.SegThreshFactorM,'value')>=1, ...
   disp('Warning: threshold exceeds 1, no thresholding performed. thresFactorM may be too high.'); end
mask = im2bw(imge,thres2);
edg = findEdges(im16);
edg = bwmorph(edg,'clean');
edg = bwmorph(edg,'bridge');
imgProc = (1-edg).*mask;
imgProc = imfill(imgProc,'holes');
seo = strel('disk',max(floor(str2double(get(handles.SegOpenNum,'string')))),4);
% % % se = strel('disk',2,4);
% % % % % % seo = strel('rectangle',[max(floor(str2double(get(handles.SegOpenNum,'string')))) max(floor(str2double(get(handles.SegOpenNum,'string'))))]);
% % % % % % se = strel('rectangle',[2 2]);
imgProc = imopen(imgProc,seo);
% % % imgProc = imclose(imgProc,se);
imgProc(:,[1 end])=0;
imgProc([1 end],:)=0;
imgProc = bwmorph(imgProc,'open');
result = bwlabel(imgProc,4);
end
