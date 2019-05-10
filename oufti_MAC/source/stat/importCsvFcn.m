
function  importCsvFcn
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
%#function [csv2cell]
global cellList paramString

try
    [file,path] = uigetfile({'*.out;*.csv'},'Select the file to convert to cellList ".mat" format');
    [cellList,paramString] = csv2cell([path file], ',', '#', '"','textual-usewaitbar',[]); 
catch
    disp('Conversion did not work');
    return;
end
disp('conversion to .mat successful');

end


