function params = postProcessingParamWindow(params)
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
%function params = postProcessingParamWindow(params)
%oufti.v0.3.0
%@author:  Ahmad Paintdakhi
%@copyright 2012-2014 Yale University
%==========================================================================
%**********output********:
%params:    updated post-processing parameters
%**********Input********:
%params:    default parameters for the post-processing window of
%spotFinder.
%=========================================================================
% PURPOSE:
%generates a gui that lets users modify parameters on the fly in adjust
%mode of spotFinder.
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------

global handles1
screenSize = get(0,'screensize');
if isfield(handles1,'postProcessingPanel')...
    && ishandle(handles1.postProcessingPanel)
        set(handles1.postProcessingPanel,'visible','on');
   
else
handles1.postProcessingPanel = figure('units','pixels',...
                            'Position',[50 screenSize(4)-250 225 200],'ButtonDownFcn',@mainkeypress,...
                            'Interruptible','off','Name','Post-fit Processing','Toolbar','none','Menubar','none',...
                            'NumberTitle','off','IntegerHandle','off','uicontextmenu',[],'DockControls','off','Resize','off');
%-----------------------------------------------------------------------------------
%date: November 21 2012
%author:  Ahmad J. Paintdakhi
%new panel for the parameter window.
handles1.winPanel = uipanel('units','pixels','pos',[1 1 225 200],'BorderType','none');
uicontrol(handles1.winPanel,'units','pixels','Position',[5 165 120 16],...
          'Style','text','String','minHeight','HorizontalAlignment','left');
handles1.postMinHeight = uicontrol(handles1.winPanel,'units','pixels',...
                      'Position',[125 165 75 16],'Style','edit','String','0.0',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
uicontrol(handles1.winPanel,'units','pixels','Position',[5 145 120 16],...
          'Style','text','String','minWidth','HorizontalAlignment','left');                  
handles1.postMinWidth = uicontrol(handles1.winPanel,'units','pixels',...
                      'Position',[125 145 75 16],'Style','edit','String','0.5',...
                      'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
uicontrol(handles1.winPanel,'units','pixels','Position',[5 125 120 16],...
          'Style','text','String','maxWidth','HorizontalAlignment','left');
handles1.postMaxWidth = uicontrol(handles1.winPanel,'units','pixels','Position',...
                [125 125 75 16],'Style','edit','String','10','BackgroundColor',...
                [1 1 1],'HorizontalAlignment','left');  
uicontrol(handles1.winPanel,'units','pixels','Position',[5 105 120 16],...
          'Style','text','String','Adjusted Squared Error','HorizontalAlignment','left');
handles1.postError = uicontrol(handles1.winPanel,'units','pixels','Position',...
                [125 105 75 16],'Style','edit','String','0.0','BackgroundColor',...
                [1 1 1],'HorizontalAlignment','left');                       
                       
handles1.okButton = uicontrol(handles1.winPanel,'units','pixels','Position',[70 50 75 22],'String','OK','Callback','uiresume(gcbf)');
end
if isfield(params,'postMinWidth')   
    set(handles1.postMinHeight,'String',num2str(params.postMinHeight));
    set(handles1.postMinWidth,'String',num2str(params.postMinWidth));
    set(handles1.postMaxWidth,'String',num2str(params.postMaxWidth));
    set(handles1.postError,'String',num2str(params.postError)); 
end

    uiwait(gcf); 
    if ishandle(handles1.postMinHeight)
        set(handles1.postMinHeight,'String',num2str(get(handles1.postMinHeight,'string')));
        set(handles1.postMinWidth,'String',num2str(get(handles1.postMinWidth,'string')));
        set(handles1.postMaxWidth,'String',num2str(get(handles1.postMaxWidth,'string')));
        set(handles1.postError,'String',num2str(get(handles1.postError,'string')));
        params = getParameters(handles1,params);
        set(handles1.postProcessingPanel,'visible','off');  
    end
end


