function kymographFcn
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
%#function [kymograph]
global cellList
screenSize = get(0,'ScreenSize');

if sum(cellfun(@numel,cellList.meshData)) == 0,warndlg('First load cell meshes'),return;end

input = inputdlg({'cell number','conversion factor from frame to time','conversion factor from pixels to microns (leave blank if not known)','frame range ([1 10])','signal (signal1 or signal2)'});
if isempty(input),return;end
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
    figure('name','kymograph','NumberTitle','off');
    if isempty(input{3})
        kymograph(cellList,str2double(input{1}),50,str2double(input{2}),[],str2num(input{4}),input{5});
    else
        kymograph(cellList,str2double(input{1}),50,str2double(input{2}),str2double(input{3}),str2num(input{4}),input{5});
    end
catch
end
jObj.stop;
delete(hh)

end