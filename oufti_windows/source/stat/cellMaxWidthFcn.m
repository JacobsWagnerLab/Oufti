function cellMaxWidthFcn
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
%#function [meanwidthhist]
global cellList
input = inputdlg({'pix2mu'});
try
    %figure('name','length histogram','NumberTitle','off');
    meanwidthhist(cellList,str2double(input{1}));
catch

end

end