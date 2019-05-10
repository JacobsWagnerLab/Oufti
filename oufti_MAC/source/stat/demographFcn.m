function demographFcn
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
%#function [demograph]
global cellList
screenSize = get(0,'ScreenSize');

if sum(cellfun(@numel,cellList.meshData)) == 0,warndlg('First load cell meshes'),return;end
defaultAnswer = {'2000','200','5','[1 0]','[]','randomN','0.064'};
input = inputdlg({'maximum number of cells to be included in final demograph',...
                'maximum length of cell in pixels','number of pixels for moving average (finds segment where maximum intensity is located)',...
                'signal ([1 0]-->1,[0 1]-->2, [1 1]-->both)','frame number (use [] for all frames)',...
        'descriptor (randomN,randomNOriented,constriction_no_normalization,sort_by_constriction,constriction)',...
        'pixel to micron conversion factor'},'',1,defaultAnswer);
    
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
pos = get(hh,'position');
javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
pause(0.01);drawnow;
jObj.start;
    % do some long operation...
try
    figure('name','demograph','NumberTitle','off');
    demograph(cellList,str2double(input{1}),str2double(input{2}),str2double(input{3}),str2num(input{4}),...
              str2num(input{5}),input{6},str2double(input{7}));

catch
end
jObj.stop;
delete(hh)

end