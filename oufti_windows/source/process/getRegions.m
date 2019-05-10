function regions = getRegions(inputImage,thres,inputImage16,parameterStruct)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function regions = getRegions(inputImage,thres,inputImage16,parameterStruct)
%oufti.v0.3.0
%@author:  Oleksii Sliusarenko
%@modified by:  Ahmad J Paintdakhi
%@date:    March 05 2013
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%regions:   segmented regions from an image.
%**********Input********:
%inputImage:    input image.
%thres: threshold factor.
%inputImage16:  erodded 16-bit input Image.
%parameterStruct:   structure containing parameters values.
%=========================================================================
% PURPOSE:
% This function determines and labels regions on an image (im) using edge
% detection and thresholding (tractor - factor compared to automatic
% threshols, larger values - smaller regions)
% 
% p.edgemode 'none' - no edge/valley detection, thresholding only (params: im & tfactor)
% p.edgemode 'log' - thresholding + LoG edge detection (params: edgeSigmaL)
% p.edgemode 'valley' - thresholding + valley detection (params: edgeSigmaV,valleythresh1,valleythresh2)
% p.edgemode 'logvalley' - thresholding + LoG + valley (params: all)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
if ~isfield(parameterStruct,'openNum'), openNum = 1; else openNum = parameterStruct.openNum; end
thres2 = max(0,min(1,thres*parameterStruct.thresFactorM));
if thres*parameterStruct.thresFactorM>=1, disp('Warning: threshold exceeds 1, no thresholding performed. thresFactorM may be too high.'); end
mask = im2bw(inputImage,thres2);
edg = logvalley(inputImage16,parameterStruct);
edg = bwmorph(edg,'clean');
edg = bwmorph(edg,'bridge');
imgProc = (1-edg).*mask;
imgProc = imfill(imgProc,'holes');
seo = strel('disk',max(floor(openNum),0));
imgProc = imopen(imgProc,seo);
imgProc(:,[1 end])=0;
imgProc([1 end],:)=0;
% % % imgProc = bwmorph(imgProc,'erode');
% % % imgProc = bwmorph(imgProc,'dilate');
regions = bwlabel(imgProc,4);
end
