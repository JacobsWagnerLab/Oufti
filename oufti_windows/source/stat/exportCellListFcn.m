
function exportCellListFcn
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
%#function [cell2csv]
global cellList  

if sum(cellfun(@numel,cellList.meshData)) == 0,disp('First load cell meshes'),return;end

try
    [file,path] = uiputfile({'*.csv' '*.csv'},'Enter the name of a new file');
    cell2csv([path,file],cellList,',');

catch
    disp('Exporting cellList (.mat) format to csv format did not succeed');
    return;


end