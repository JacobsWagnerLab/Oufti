function cellContour = align4I(cellMask,parameterList)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function cellContour = align4I(cellMask,parameterList)
%oufti.v0.3.0
%@author:  oleksii sliusarenko
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%cellContour:  smoothed cell outline.
%**********Input********:
%cellMask:  mask of cell.
%parameterList: list of parameters.
%=========================================================================
% PURPOSE:
%creates an outline of the input cellMask and then smoothes the outline.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

% % % se = strel('diamond',2);
% % % msk = imerode(msk,se);
% % % [B,L] = bwboundaries(msk,'noholes');
% % % for k = 1:length(B)
% % %     boundary = B{k}; 
% % % end
% % %     
% % % boundaryPoints = [boundary(:,2),boundary(:,1)];
% % % fourierBoundaryPoints = frdescp(boundaryPoints);
% % % cCell = ifdescp(fourierBoundaryPoints,p.fsmooth); 

% Get boundary of a cell mask
[ii,jj]=find(bwperim(cellMask),1,'first');
%trace boundary of a cell mask in counterclockwise direction.
tracedPoints=bwtraceboundary(cellMask,[ii,jj],'n',4,inf,'counterclockwise');
%takes the fourier transform of tracedpoints.
fourierTracedPoints = frdescp(tracedPoints);
%takes the inverse fourier transform of fourierTracedPoints to get real values. 
cellContour = ifdescp(fourierTracedPoints,parameterList.fsmooth);
%creates mesh for the cellContour.
mesh = model2MeshForRefine(cellContour,parameterList.fmeshstep,parameterList.meshTolerance,parameterList.meshWidth);
if length(mesh)>4
   cellContour = fliplr([mesh(:,1:2);flipud(mesh(:,3:4))]);
else
   cellContour = [];
end
%make cell contour counterclockwise.
cellContour = makeccw(cellContour);


end