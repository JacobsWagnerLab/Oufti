function cellContour = align4Initial(cellMask,parameterList)
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

% Get boundary of a cell mask
[ii,jj]=find(bwperim(cellMask),1,'first');
%trace boundary of a cell mask in counterclockwise direction.
tracedPoints=bwtraceboundary(cellMask,[ii,jj],'n',4,inf,'counterclockwise');
%takes the fourier transform of tracedpoints.
fourierTracedPoints = frdescp(tracedPoints);
%takes the inverse fourier transform of fourierTracedPoints to get real values. 
cellContourTemp = ifdescp(fourierTracedPoints,parameterList.fsmooth);
cellContour(:,1) = cellContourTemp(:,2);
cellContour(:,2) = cellContourTemp(:,1);

% % % %creates mesh for the cellContour.
% % % mesh = model2mesh(cellContour,parameterList.fmeshstep,parameterList.meshTolerance,parameterList.meshWidth);
% % % if length(mesh)>4
% % %    cellContour = fliplr([mesh(:,1:2);flipud(mesh(:,3:4))]);
% % % else
% % %    cellContour = [];
% % % end
% % % 
% % % %make cell contour counterclockwise.
% % % cellContour = makeccw(cellContour);   
end


