
function spotFinderVisibility(hObject,eventdata)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function spotFinderVisibility(hObject,eventdata)
%oufti's Detection and Analysis panel's visibility is off while
%spotFinderPanel's visibility is on.
%oufti.v0.2.4
%@author:  Ahmad J Paintdakhi
%@date:    August 25 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%**********Input********:
%==========================================================================
global handles handles1
try
    if isfield(handles1,'objectDetectionPanel'),set(handles1.objectDetectionPanel,'visible','off');end
if isfield(handles1,'spotFinderPanel')
    if ishandle(handles1.spotFinderPanel),set(findall(handles1.spotFinderPanel,'-property','visible'),'visible','off');end
end
catch
    try
        set(handles1.objectDetectionPanel,'Visible','off');
    catch
        return;
    end
end

if ishandle(handles.btnspanel) && isfield(handles,'btnspanel')
 set(handles.btnspanel,'Visible','off');
end
if isfield(handles1,'contrastText'),set(handles1.contrastText,'Visible','off');end
%disables the contrast slider when oufti button is pressed.
if isfield(handles1,'contrastSlider'),set(handles1.contrastSlider,'Visible','off');end
spotDetection();
% % % screenSize = get(0,'ScreenSize');
% % % pos = get(handles.maingui,'position');
% % % pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600)))...
% % %       max(pos(3:4),[1000 600])];
% % % set(handles.maingui,'position',pos);
% % % set(handles1.spotFinderPanel,'pos',[pos(3)-1000+725 pos(4)-800+515 290 250]);
set(handles.imslider,'Enable','off');
set(handles.dispimg,'Visible','off');
%uicontrol for constrastSlider's label called Constrast Values:
handles1.contrastText = uicontrol('units','pixels','Position',...
                        [350 85 100 14],'Style','text','String',...
                        'Contrast Values:','HorizontalAlignment','left',...
                        'FontUnits','pixels','FontName','Helvetica',...
                        'FontSize',10);
%uicontrol for a slider that appears whenever spotFinder button is clicked
%on the menue of oufti window and disappears when oufti
%button is clicked.
handles1.contrastSlider = uicontrol('Style','slider','units','pixels',...
                          'Position',[450 85 150 15],'SliderStep',...
                          [0.001 0.01],'min',0,'max',1,'value',0,'Enable','on',...
                          'callback',@contrastSlider);
%this call is not supported in Matlab R2014b
%handles1.contrastSliderListner = handle.listener(handles1.contrastSlider,'ActionEvent',@contrastSlider);

end
