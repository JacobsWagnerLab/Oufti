
function objectDetectionVisibility(hObject,eventdata)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function objectDetectionVisibility(hObject,eventdata)
%oufti's Detection and Analysis panel's and spotFinder visibility is off while
%object Detection's visibility is on.
%oufti.v0.1.2
%@author:  Ahmad J Paintdakhi
%@date:    October 10, 2014
%@copyright 2012-2015 Yale University
%==========================================================================
%**********output********:
%**********Input********:
%==========================================================================
global handles handles1

if isfield(handles1,'objectDetectionPanel'),set(handles1.objectDetectionPanel,'visible','off');end
if isfield(handles1,'spotFinderPanel')
if ishandle(handles1.spotFinderPanel),set(findall(handles1.spotFinderPanel,'-property','visible'),'visible','off');end
end
set(handles.btnspanel,'Visible','off');

try
if isstruct(handles1),set(handles1.spotFinderPanel,'Visible','off'); end
if ishandle(handles.imslider),set(handles.imslider,'Enable','on');end
%disables the constrast slider text when oufti button is pressed.
set(handles1.contrastText,'Visible','off');
%disables the contrast slider when oufti button is pressed.
set(handles1.contrastSlider,'Visible','off');
set(handles.dispimg,'Visible','on');
set(handles.objectGui,'Selected','on');
if isstruct(imageHandle)
    try
        g = get(imageHandle.fig,'children');
        delete(g);
       
    catch ME
      
    end   
end
catch ME
   
end