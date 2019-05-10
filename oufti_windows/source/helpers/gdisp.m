function varargout = gdisp(varargin)
% alternative to text display to screen
%
% gdisp('VISIBLE') - makes figure visible
% gdisp('HIDE') - makes figure invisible
% gdisp('CLOSE') - closes figure

    persistent text gdispobj

    maxlines = 500;

    if nargin==0
        if ~exist('handles.gdispfig','var') || isempty(handles.gdispfig) || ~ishandle(handles.gdispfig)
            varargout(1)={[]};
        else
            varargout(1)={strcmp(get(handles.gdispfig,'visible'),'on')};
        end
        return
    else
        data = varargin{1};
    end

    if ~isa(data,'char'), return; end
    if ~exist('handles.gdispfig','var') || isempty(handles.gdispfig) || ~ishandle(handles.gdispfig)
        screenSize = get(0,'ScreenSize');
        screenSize = round(screenSize(3:4)/2);
        handles.gdispfig = figure('pos',[screenSize-200 400 400],'CloseRequestFcn',@closelogreq,'Toolbar','none','Menubar','none','Name','cellTracker log window','NumberTitle','off','IntegerHandle','off','ResizeFcn',@resizelogfcn,'visible','off');
        handles.wnd = uicontrol(handles.gdispfig,'units','pixels','Position',[1 1 400 400],'Style','edit','Min',1,'Max',50,'BackgroundColor',[1 1 1],'HorizontalAlignment','left');
        mde = com.mathworks.mde.desk.MLDesktop.getInstance;
        pause(0.005);
        jFigPanel = mde.getClient('cellTracker log window');
        gdispobj = jFigPanel.getComponent(0).getComponent(0).getComponent(0).getComponent(0).getComponent(0).getComponent(0).getComponent(0);
    end

    if strcmp(data,'CLOSE')
        delete(handles.gdispfig)
        handles.gdispfig = [];
    elseif strcmp(data,'HIDE')
        set(handles.gdispfig,'visible','off')
    elseif strcmp(data,'VISIBLE')
        set(handles.gdispfig,'visible','on')
    else
        text = strvcat(text,data);
        nlines = size(text,1);
        if nlines>maxlines
            text = text(nlines-maxlines+1:nlines,:);
        end
        set(handles.wnd,'String',text);
        pause(0.005);
        try
            gdispobj.setCaretPosition(gdispobj.getDocument.getLength);
        catch
        end
    end
end

function resizelogfcn(hObject, eventdata)
    figuresize = get(handles.gdispfig,'pos');
    set(handles.wnd,'pos',[1 1 figuresize(3:4)]);
end
function closelogreq(hObject, eventdata)
    set(handles.gdispfig,'visible','off')
end