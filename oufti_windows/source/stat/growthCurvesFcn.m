
function growthCurvesFcn
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function 
%PURPOSE:
%@author:  
%@date:    
%@copyright 2012-2015 Yale University
%==========================================================================
%**********output********:
%out1
%.
%.
%outN
%**********Input********:
%in1
%.
%.
%inN
%=========================================================================
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%pragma function needed to include files for deployment
%#function [getLLoCurves]
global cellList  

if sum(cellfun(@numel,cellList.meshData)) == 0,disp('First load cell meshes'),return;end
try
[dataStr,hdl] = getLLoCurves(cellList,0,0);
set(gcf,'name','growth curves');
set(gcf,'NumberTitle','off');colormap cc;
colorbar
set(hdl,'colormap',cc);

end