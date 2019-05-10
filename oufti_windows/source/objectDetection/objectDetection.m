function objectDetection(hObject,eventdata)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function objectDetection(hObject,eventdata)
%This function is used for the objectDetection module.
%author:  Ahmad Paintdakhi
%@revision date:    September 16, 2014
%@copyright 2014-2015 Yale University
%==========================================================================
%********** input ********:
%hObject and eventData handles 
%********** output ********:
%
%==========================================================================
global handles1 handles

%clears oufti or spot detectin panels and turns on object detection panel.
objectDetectionVisibility();

pos = get(handles.maingui,'position');
screenSize = get(0,'ScreenSize');
pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600)))...
      max(pos(3:4),[1000 600])];

handles1.objectDetectionPanel = uipanel('Parent',handles.maingui,'units','pixels',...
                            'Position',[pos(3)-1000+725 pos(4)-840+485 272 290],'ButtonDownFcn',@mainkeypress,...
                            'ResizeFcn',@resizefcn,'Interruptible','off','Title','objectDetection');
                        
%---------------------------------------------------------------------------------------------
%image magnitude to be declared as background, if 0, other background subtraction algo will be used
handles1.objectDetection.manual = uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 240 200 18],...
          'Style','radiobutton','String','manual background threshold','HorizontalAlignment','left','callback',@bgSelection);
handles1.objectDetection.ManualBGSel = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 240 50 18],'Style','edit','Enable','off','String','0.1',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
%---------------------------------------------------------------------------------------------


%---------------------------------------------------------------------------------------------
%Background subtraction method
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 220 200 18],...
          'Style','text','String','background subtraction method','HorizontalAlignment','left');

handles1.objectDetection.BGMethod = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 220 50 18],'Style','edit','String','3',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left'); 
%---------------------------------------------------------------------------------------------


%---------------------------------------------------------------------------------------------
%filter size for bandpass filtering, used in background subtraction
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 200 200 18],...
          'Style','text','String','background subtraction threshold','HorizontalAlignment','left');

handles1.objectDetection.BGThreshold = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 200 50 18],'Style','edit','String','0.1',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
%---------------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------------
%filter size for bandpass filtering, used in background subtraction
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 180 200 18],...
          'Style','text','String','background filter size','HorizontalAlignment','left');

handles1.objectDetection.BGFilterSize = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 180 50 18],'Style','edit','String','8',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
%---------------------------------------------------------------------------------------------


%---------------------------------------------------------------------------------------------
%sigma of laplacian of gaussian filter
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 160 200 18],...
          'Style','text','String','smoothing range (pixels)','HorizontalAlignment','left');

handles1.objectDetection.logSigma = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 160 50 18],'Style','edit','String','3',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left'); 
%---------------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------------
%magnitude parameter of LoG filter
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 140 200 18],...
          'Style','text','String','magnitude of LOG filter','HorizontalAlignment','left');

handles1.objectDetection.magnitudeLog = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 140 50 18],'Style','edit','String','0.1',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');  
%---------------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------------
%sigma value of PSF
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 120 200 18],...
          'Style','text','String','sigma of PSF','HorizontalAlignment','left');

handles1.objectDetection.psfSigma = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 120 50 18],'Style','edit','String','1.62',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left'); 
%---------------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------------
%the fraction of the nucleoid that must be within the cell mesh to save
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 100 200 18],...
          'Style','text','String','fraction of object in cell','HorizontalAlignment','left');
handles1.objectDetection.inCellPercent = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 100 50 18],'Style','edit','String','0.4',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left'); 
%---------------------------------------------------------------------------------------------

%---------------------------------------------------------------------------------------------
%minimum of object area
uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 80 200 18],...
          'Style','text','String','minimum object area','HorizontalAlignment','left');
handles1.objectDetection.minObjectArea = uicontrol(handles1.objectDetectionPanel,'units','pixels',...
                      'Position',[175 80 50 18],'Style','edit','String','50',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left'); 
%---------------------------------------------------------------------------------------------

                  
handles1.objectDetection.objectRunThisFrame = uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[2 5 100 25],'String','Run (current frame)','Callback',@RunObjectDetection,'KeyPressFcn',@mainkeypress);
handles1.objectDetection.objectRunAllFrames = uicontrol(handles1.objectDetectionPanel,'units','pixels','Position',[105 5 100 25],'String','Run (all frames)','Callback',@RunObjectDetection,'KeyPressFcn',@mainkeypress);

if isfield(handles1,'objectParams')
    handles1.objectDetection.ManualBGSel.String = num2str(handles1.objectParams.ManualBGSel);
    handles1.objectDetection.BGFilterSize.String = num2str(handles1.objectParams.BGFilterSize);
    handles1.objectDetection.BGThreshold.String = num2str(handles1.objectParams.BGFilterThresh);
    handles1.objectDetection.logSigma.String = num2str(handles1.objectParams.logSigma);
    handles1.objectDetection.magnitudeLog.String = num2str(handles1.objectParams.magnitudeLog);
    handles1.objectDetection.psfSigma.String = num2str(handles1.objectParams.psfSigma);
    handles1.objectDetection.inCellPercent.String = num2str(handles1.objectParams.inCellPercent);
    handles1.objectDetection.minObjectArea.String = num2str(handles1.objectParams.minObjectArea);
    handles1.objectDetection.BGMethod.String = num2str(handles1.objectParams.BGMethod);
    if handles1.objectParams.manual == 1
        handles1.objectDetection.ManualBGSel.Enable = 'on';
        handles1.objectDetection.BGMethod.Enable = 'off';
        handles1.objectDetection.BGThreshold.Enable = 'off';
    else
        handles1.objectDetection.BGMethod.Enable = 'on';
        handles1.objectDetection.ManualBGSel.Enable = 'off';
        handles1.objectDetection.BGThreshold.Enable = 'on';
    end
end

end

function bgSelection(hObject, eventdata)
global handles1
if hObject.Value == 1
    handles1.objectDetection.ManualBGSel.Enable = 'on';
    handles1.objectDetection.BGMethod.Enable = 'off';
    handles1.objectDetection.BGThreshold.Enable = 'off';
else
        handles1.objectDetection.BGMethod.Enable = 'on';
        handles1.objectDetection.ManualBGSel.Enable = 'off';
        handles1.objectDetection.BGThreshold.Enable = 'on';
end
end



function mainkeypress(hObject, eventdata)
    
    
    return;
end

function resizefcn(hObject, eventdata)
global handles handles1
screenSize = get(0,'ScreenSize');
pos = get(handles.maingui,'position');
pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600))) max(pos(3:4),[1000 600])];
set(handles1.objectDetectionPanel,'pos',[pos(3)-1000+725 pos(4)-840+485 272 290]);

end
