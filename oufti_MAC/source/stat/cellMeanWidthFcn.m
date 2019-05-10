function cellMeanWidthFcn
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

global cellList
screenSize = get(0,'ScreenSize');

%pragma function needed to include files for deployment
%#function [meanwidthhist]
input = inputdlg({'Pixel to micron conversion factor.  If value not known leave blank'});
try
    % R2010a and newer
    iconsClassName = 'com.mathworks.widgets.BusyAffordance$AffordanceSize';
    iconsSizeEnums = javaMethod('values',iconsClassName);
    SIZE_32x32 = iconsSizeEnums(2);  % (1) = 16x16,  (2) = 32x32
    jObj = com.mathworks.widgets.BusyAffordance(SIZE_32x32, 'Processing...');  % icon, label
catch
    % R2009b and earlier
    redColor   = java.awt.Color(1,0,0);
    blackColor = java.awt.Color(0,0,0);
    jObj = com.mathworks.widgets.BusyAffordance(redColor, blackColor);
end
jObj.setPaintsWhenStopped(true);  % default = false
jObj.useWhiteDots(false);         % default = false (true is good for dark backgrounds)
hh =  figure('pos',[(screenSize(3)/2)-100 (screenSize(4)/2)-100 100 100],'Toolbar','none',...
             'Menubar','none','NumberTitle','off','DockControls','off');
pause(0.05);drawnow;
pos = hh.Position;
javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
pause(0.01);drawnow;
jObj.start;
    % do some long operation...

try
    converstionFactor = str2double(input{1});
    if isnan(converstionFactor) || isempty(input)
        meanwidthhist(cellList);
    else
    %figure('name','length histogram','NumberTitle','off');
        meanwidthhist(cellList,converstionFactor);
    end
catch

end
jObj.stop;
delete(hh)
end