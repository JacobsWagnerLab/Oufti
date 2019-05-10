function dispcellAllFcn
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
%#function [dispcellall]
global cellList rawS1Data
screenSize = get(0,'ScreenSize');
defaultAnswer = {'[1 1]'};
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

    % do some long operation...
        if isempty(rawS1Data)
            input = inputdlg({'frame range'},'',1,defaultAnswer);
            if isempty(input),return;end
            if sum(cellfun(@numel,cellList.meshData)) == 0,warndlg('First load cell meshes'),return;end
                    try
                                dataChoice = questdlg('stack?','data type','Yes','No','Yes');
                                switch dataChoice
                                    case 'Yes'
                                        [fileName,pathName] = uigetfile('*.tif');
                                        [~,data] = loadimagestack(3,[pathName '\' fileName],1,0);
                                    case 'No'
                                        pathName = uigetdir('*.tif');
                                        [data, ~, ~] = loadimageseries(pathName);
                                end
                        hh =  figure('pos',[(screenSize(3)/2)-100 (screenSize(4)/2)-100 100 100],'Toolbar','none',...
                                     'Menubar','none','NumberTitle','off','DockControls','off');
                        pause(0.05);drawnow;
                        pos = hh.Position;
                        javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
                        pause(0.01);drawnow;
                        jObj.start;
                        dispcellall(cellList,data,str2num(input{1}));      
                    catch
                    end
        else
            imageChoice = questdlg('Use current data set?','Image set','Yes','No','Yes');
            switch imageChoice
                case 'Yes'
                    data = rawS1Data;
                    defaultAnswer = {'[1 1]'};
                    input = inputdlg({'frame range'},'',1,defaultAnswer);
                    if isempty(input),return;end
                    if sum(cellfun(@numel,cellList.meshData)) == 0,warndlg('First load cell meshes'),return;end
                    frameRange = str2num(input{1});
                    try
                        hh =  figure('pos',[(screenSize(3)/2)-100 (screenSize(4)/2)-100 100 100],'Toolbar','none',...
                                     'Menubar','none','NumberTitle','off','DockControls','off');
                        pause(0.05);drawnow;
                        pos = hh.Position;
                        javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
                        pause(0.01);drawnow;
                        jObj.start;
                        dispcellall(cellList,data,frameRange);   
                    catch
                    end

                case 'No'
                        try
                                dataChoice = questdlg('stack?','data type','Yes','No','Yes');
                                switch dataChoice
                                    case 'Yes'
                                        [fileName,pathName] = uigetfile('*.tif');
                                        [~,data] = loadimagestack(3,[pathName '\' fileName],1,0);
                                    case 'No'
                                        pathName = uigetdir('*.tif');
                                        [data, ~, ~] = loadimageseries(pathName);
                                end

                            catch
                          end
                        input = inputdlg({'frame range'},'',1,defaultAnswer);
                        if isempty(input),return;end
                         
                        if sum(cellfun(@numel,cellList.meshData)) == 0,disp('First load cell meshes'),return;end
                        try
                            hh =  figure('pos',[(screenSize(3)/2)-100 (screenSize(4)/2)-100 100 100],'Toolbar','none',...
                                         'Menubar','none','NumberTitle','off','DockControls','off');
                            pause(0.05);drawnow;
                            pos = hh.Position;
                            javacomponent(jObj.getComponent, [1,1,pos(3),pos(4)],hh);
                            pause(0.01);drawnow;
                            jObj.start;
                                dispcellall(cellList,data,str2num(input{1}));      
                        catch
                        end

                otherwise
                    return;
            end
        end

    jObj.stop;
    delete(hh)
end