function fig = createdispfigure(celldata)
    global dhandles
    if exist('dhandles','var') && isfield(dhandles,'fig') && ishandle(dhandles.fig)
        fig = dhandles.fig;
        setdispfiguretitle(dhandles.fig,celldata,0)
        set(dhandles.fig,'UserData','');
        return
    end 
    dhandles.fig = figure('KeyPressFcn',@dispfitkeypress,'CloseRequestFcn',@dispfitclosereq,'Toolbar','none','Menubar','none','NumberTitle','off','IntegerHandle','off','UserData','');
    setdispfiguretitle(dhandles.fig,celldata,0)
    pos = get(dhandles.fig,'pos');
    pos = [pos(1)+pos(3)/2-200 pos(2)+pos(4)/2-300 400 430];
    set(dhandles.fig,'pos',pos);
    fig = dhandles.fig;
    dhandles.ax = axes('units','pixels','pos',[1 1 400 400],'box','off','tickdir','out','DataAspectRatio',[1 1 1]);
    dhandles.cpanel = uipanel(dhandles.fig,'units','pixels','pos',[1 401 400 30]);
    dhandles.next = uicontrol(dhandles.cpanel,'units','pixels','Position',[5 4 63 20],'String','Next step','callback',@dispfitcontrol,'KeyPressFcn',@dispfitkeypress);
    dhandles.next100 = uicontrol(dhandles.cpanel,'units','pixels','Position',[70 4 63 20],'String','+100 steps','callback',@dispfitcontrol,'KeyPressFcn',@dispfitkeypress);
    dhandles.skip = uicontrol(dhandles.cpanel,'units','pixels','Position',[135 4 63 20],'String','Skip cell','callback',@dispfitcontrol,'KeyPressFcn',@dispfitkeypress);
    dhandles.continue = uicontrol(dhandles.cpanel,'units','pixels','Position',[200 4 63 20],'String','Continue','callback',@dispfitcontrol,'KeyPressFcn',@dispfitkeypress);
    dhandles.finish = uicontrol(dhandles.cpanel,'units','pixels','Position',[265 4 63 20],'String','Finish','callback',@dispfitcontrol,'KeyPressFcn',@dispfitkeypress);
    dhandles.stop = uicontrol(dhandles.cpanel,'units','pixels','Position',[330 4 63 20],'String','Stop','callback',@dispfitcontrol,'KeyPressFcn',@dispfitkeypress);
    set(dhandles.fig,'ResizeFcn',@dispfitresizefcn);
    dhandles.ax;
    
    function dispfitkeypress(hObject,eventdata)
        if isempty(eventdata) || ~isfield(eventdata,'Key')
            return
        elseif strcmp(eventdata.Key,'rightarrow')
            set(dhandles.fig,'UserData','next');
        elseif strcmp(eventdata.Key,'downarrow')
            set(dhandles.fig,'UserData','next100');
        elseif strcmp(eventdata.Key,'escape')
            set(dhandles.fig,'UserData','stop');
        end
    end
    function dispfitcontrol(hObject,eventdata)
        if hObject==dhandles.next
            set(dhandles.fig,'UserData','next');
        elseif hObject==dhandles.next100
            set(dhandles.fig,'UserData','next100');
        elseif hObject==dhandles.skip
            set(dhandles.fig,'UserData','skip');
        elseif hObject==dhandles.continue
            set(dhandles.fig,'UserData','continue');
        elseif hObject==dhandles.stop
            set(dhandles.fig,'UserData','stop');
        elseif hObject==dhandles.finish
            set(dhandles.fig,'UserData','finish');
        end
    end
    function dispfitclosereq(hObject, eventdata)
        delete(dhandles.fig)
        clear('dhandles')
    end
    function dispfitresizefcn(hObject, eventdata)
        screenSize = get(0,'ScreenSize');
        pos = get(dhandles.fig,'pos');
        pos = [pos(1:2) max(pos(3:4),[400 430])];
        pos(2) = min(pos(2),screenSize(4)-460);
        set(dhandles.fig,'pos',pos);
        set(dhandles.ax,'pos',[1 1 pos(3) pos(4)-30]);
        set(dhandles.cpanel,'pos',[1 pos(4)-30+1 pos(3) 30]);
    end
end