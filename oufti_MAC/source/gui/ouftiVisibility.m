function ouftiVisibility(hObject,eventdata)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function ouftiVisibility(hObject,eventdata)
%oufti's Detection and Analysis panel's visibility is off while
%spotFinderPanel's visibility is on.
%oufti.v0.2.4
%@author:  Ahmad J Paintdakhi
%@date:    March 25, 2012
%@copyright 2012-2013 Yale University
%==========================================================================
%**********output********:
%**********Input********:
%oufti's Detection and Analysis panel is visible and spotFinder's
%panel is off.
%==========================================================================
global handles handles1 imageHandle
try
    if isfield(handles1,'objectDetectionPanel'),set(handles1.objectDetectionPanel,'visible','off');end
    if isfield(handles1,'spotFinderPanel')
        if ishandle(handles1.spotFinderPanel),set(findall(handles1.spotFinderPanel,'-property','visible'),'visible','off');end
    end
catch ME
    if isstruct(handles1) && isfield(handles1,'objectDetectionPanel')
        set(handles1.objectDetectionPanel,'Visible','off'); 
        set(handles.btnspanel,'Visible','on');
    end
    return;
end
try
    set(handles.btnspanel,'Visible','on');
    if isstruct(handles1) && isfield(handles1,'spotFinderPanel')
        if ishandle(handles.imslider),set(handles.imslider,'Enable','on');end
        %disables the constrast slider text when oufti button is pressed.
        set(handles1.contrastText,'Visible','off');
        %disables the contrast slider when oufti button is pressed.
        set(handles1.contrastSlider,'Visible','off');
        set(handles.dispimg,'Visible','on');
        set(handles1.spotFinderPanel,'Visible','off'); 
    % % %     if isstruct(imageHandle)
    % % %         try
    % % %             g = get(imageHandle.fig,'children');
    % % %             delete(g);
    % % % 
    % % %         catch ME
    % % %             if isstruct(handles1) && isfield(handles1,'objectDetectionPanel')
    % % %                 set(handles1.objectDetectionPanel,'Visible','off'); 
    % % %                 set(handles.btnspanel,'Visible','on');
    % % %             end
    % % %             return;
    % % %         end
    % % % 
    % % %     end 


    end
    if isstruct(handles1) && isfield(handles1,'objectDetectionPanel')
        set(handles1.objectDetectionPanel,'Visible','off'); 
        set(handles.btnspanel,'Visible','on');
    end

    if isstruct(handles1) && isfield(handles1,'spotFinderPanel')
        set(handles1.spotFinderPanel,'Visible','off'); 
        set(handles.btnspanel,'Visible','on');
    end

catch ME
    if isstruct(handles1) && isfield(handles1,'objectDetectionPanel')
        set(handles1.objectDetectionPanel,'Visible','off'); 
        set(handles.btnspanel,'Visible','on');
    end
    return;
end

end
%--------------------------------------------------------------------------