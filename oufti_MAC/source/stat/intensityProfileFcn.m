function intensityProfileFcn
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
%#function [intprofile]
global cellList
defaultParams = {'1','1','integrate','0.064','signal1'};
input = inputdlg({'frame','cell','normalization (integrate, area, volume)','pixel to micron conversion factor (if not known leave blank)','signal (signal1, signal2, or signaln)'},'',1,defaultParams);
try
    cellList.meshData{str2double(input{1})}{str2double(input{2})} = getextradata(cellList.meshData{str2double(input{1})}{str2double(input{2})});
    figure('name','intensity profile','NumberTitle','off');
    if isempty(input{4})
       intprofile(cellList,str2double(input{1}),str2double(input{2}),input{3},input{5});
    else
        intprofile(cellList,str2double(input{1}),str2double(input{2}),input{3},str2double(input{4}),input{5});
    end

catch
end


end