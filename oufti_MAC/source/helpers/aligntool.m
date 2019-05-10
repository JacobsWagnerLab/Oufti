function aligntool
% A GUI-based semi-manual tool for aligning frames in timelapse series 

% clear oufti data from old sessions, if any
global handles
if exist('handles','var') && isfield(handles,'maingui') && ishandle(handles.maingui)
    choice = questdlg('A MicrobeTracker or Align Tool session is running. Close it and continue?','Question','Close & continue','Keep & exit','Close & continue');
    if strcmp(choice,'Keep & exit'), return; end
end
cleardata

% detect if Bioformats is installed
bformats = checkbformats(1);

% define/redefine globals
global shiftframes imageFolders imageLimits handles imsizes pointsList logcheckw %#ok<REDEF>

% GUI

handles.maingui = figure('pos',[100 100 780 710],'WindowButtonMotionFcn',@mousemove,'windowButtonUpFcn',@dragbutonup,'windowButtonDownFcn',@selectclick,'KeyPressFcn',@mainkeypress,'CloseRequestFcn',@mainguiclosereq,'WindowScrollWheelFcn',@zoominout,'Toolbar','none','Menubar','none','Name','Image aligning tool','NumberTitle','off','IntegerHandle','off','ResizeFcn',@resizefcn);

%Image loading and displaying
handles.impanel = uipanel('units','pixels','pos',[17 170 750 600]);
handles.imslider = uicontrol(handles.maingui,'Style','slider','units','pixels','Position',[2 170 15 600],'SliderStep',[1 1],'min',1,'max',2,'value',1,'callback',@imslider,'Enable','off');

handles.loadpanel = uipanel('units','pixels','pos',[3 772 770 29],'BorderType','none');
handles.helpbtn = uicontrol(handles.loadpanel,'units','pixels','Position',[1 2 80 25],'String','Help','ForegroundColor',[0.8 0 0],'callback',@help_cbk,'FontSize',10);

handles.loadphase = uicontrol(handles.loadpanel,'units','pixels','Position',[98 2 80 25],'String','Load phase','callback',@loadstack,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.loads1 = uicontrol(handles.loadpanel,'units','pixels','Position',[183 2 80 25],'String','Load signal 1','callback',@loadstack,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.loads2 = uicontrol(handles.loadpanel,'units','pixels','Position',[267 2 80 25],'String','Load signal 2','callback',@loadstack,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.loadcheck = uicontrol(handles.loadpanel,'units','pixels','pos',[351 2 60 25],'style','checkbox','String','stack','FontSize',8,'KeyPressFcn',@mainkeypress);

uicontrol(handles.loadpanel,'units','pixels','Position',[480 6 70 15],'Style','text','String','Align frames:','FontSize',8);
handles.alignframes = uicontrol(handles.loadpanel,'units','pixels','Position',[550 2 41 25],'String','Align','callback',@alignphaseframes,'Enable','off','FontSize',8);
handles.alignfrompoints = uicontrol(handles.loadpanel,'units','pixels','Position',[595 2 41 25],'String','Points','callback',@alignphaseframes,'Enable','off','FontSize',8);
handles.loadalignment = uicontrol(handles.loadpanel,'units','pixels','Position',[640 2 41 25],'String','Load','callback',@alignphaseframes,'Enable','off','FontSize',8);
handles.savealignment = uicontrol(handles.loadpanel,'units','pixels','Position',[685 2 41 25],'String','Save','callback',@alignphaseframes,'Enable','off','FontSize',8);
handles.resetshift = uicontrol(handles.loadpanel,'units','pixels','Position',[730 2 41 25],'String','Reset','callback',@alignphaseframes,'Enable','off','FontSize',8);

% Zoom panel
handles.zoompanel = uipanel('units','pixels','pos',[179 5 150 71]);
handles.zoomin = uicontrol(handles.zoompanel,'units','pixels','pos',[115 45 20 20],'String','+','callback',@zoominout,'Enable','off','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.zoomout = uicontrol(handles.zoompanel,'units','pixels','pos',[15 45 20 20],'String','-','callback',@zoominout,'Enable','off','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.zoomcheck = uicontrol(handles.zoompanel,'units','pixels','pos',[5 25 140 20],'style','checkbox','String','Display zoomed image','callback',@zoomcheck,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.logcheck = uicontrol(handles.zoompanel,'units','pixels','pos',[5 5 50 20],'style','checkbox','String','Log /','callback',@logcheck,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.logcheckw = uicontrol(handles.zoompanel,'units','pixels','pos',[50 5 50 20],'style','checkbox','String','WS','callback',@logcheck,'Value',1,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.contrast = uicontrol(handles.zoompanel,'units','pixels','pos',[95 5 48 20],'String','Contrast','callback',@contrast_cbk,'Enable','on','FontSize',8,'KeyPressFcn',@mainkeypress);

% Frame and cell data
handles.datapanel = uipanel('units','pixels','pos',[5 5 170 71]);
uicontrol(handles.datapanel,'units','pixels','Position',[1 38 75 15],'Style','text','String','Image:','HorizontalAlignment','right','FontSize',8);
handles.currentimage = uicontrol(handles.datapanel,'units','pixels','Position',[80 38 85 15],'Style','text','String','','HorizontalAlignment','left','FontSize',8);
uicontrol(handles.datapanel,'units','pixels','Position',[1 23 75 15],'Style','text','String','Current frame:','HorizontalAlignment','right','FontSize',8);
handles.currentframe = uicontrol(handles.datapanel,'units','pixels','Position',[80 23 80 15],'Style','text','String','','HorizontalAlignment','left','FontSize',8);
uicontrol(handles.datapanel,'units','pixels','Position',[1 9 75 15],'Style','text','String','Cursor:','HorizontalAlignment','right','FontSize',8);
handles.celldata.coursor = uicontrol(handles.datapanel,'units','pixels','Position',[80 9 80 15],'Style','text','String','','HorizontalAlignment','left','FontSize',8);

% Display controls
handles.dcpanel = uipanel('units','pixels','pos',[333 5 227 71]);
handles.dispimg = uibuttongroup(handles.dcpanel,'units','pixels','Position',[5 10 210 20],'BorderType','none','SelectionChangeFcn',@dispimgcontrol,'FontSize',8);
uicontrol(handles.dispimg,'units','pixels','Position',[2 8 100 14],'Style','text','String','Channel:','HorizontalAlignment','left','FontSize',8);
handles.dispph = uicontrol(handles.dispimg,'units','pixels','Position',[44 8 62 16],'Style','radiobutton','String','Phase','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.disps1 = uicontrol(handles.dispimg,'units','pixels','Position',[101 8 62 16],'Style','radiobutton','String','Signal 1','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.disps2 = uicontrol(handles.dispimg,'units','pixels','Position',[158 8 57 16],'Style','radiobutton','String','Signal 2','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.dispsft = uibuttongroup(handles.dcpanel,'units','pixels','Position',[5 10 210 20],'BorderType','none','SelectionChangeFcn',@dispsftcontrol,'FontSize',8);
uicontrol(handles.dispsft,'units','pixels','Position',[2 28 100 14],'Style','text','String','Image:','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.disporign = uicontrol(handles.dispsft,'units','pixels','Position',[44 28 62 16],'Style','radiobutton','String','Original','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.dispshift = uicontrol(handles.dispsft,'units','pixels','Position',[101 28 62 16],'Style','radiobutton','String','Shifted','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);

% Param control
handles.prmpanel = uipanel('units','pixels','pos',[564 5 103 71]);
uicontrol(handles.prmpanel,'units','pixels','Position',[2 28 70 20],'Style','text','String','aligndepth:','FontSize',8,'HorizontalAlignment','right');
handles.aligndepth = uicontrol(handles.prmpanel,'units','pixels','Position',[73 33 25 17],'Style','edit','Min',1,'Max',50,'BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontSize',8,'String','10');
uicontrol(handles.prmpanel,'units','pixels','Position',[2 8 70 20],'Style','text','String','bgrErodeNum:','FontSize',8,'HorizontalAlignment','right');
handles.bgrErodeNum = uicontrol(handles.prmpanel,'units','pixels','Position',[73 13 25 17],'Style','edit','Min',1,'Max',50,'BackgroundColor',[1 1 1],'HorizontalAlignment','center','FontSize',8,'String','5');

% Background subtraction
handles.bgr = uipanel('units','pixels','pos',[671 5 103 71]);
handles.subtbgr = uicontrol(handles.bgr,'units','pixels','Position',[5 45 91 20],'String','Subtract bgrnd','callback',@subtbgrcbk,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.subtbgrtype = uibuttongroup(handles.bgr,'units','pixels','Position',[5 27 91 20],'BorderType','none','FontSize',8);
handles.subtbgrvis = uicontrol(handles.subtbgrtype,'units','pixels','Position',[1 2 55 16],'Style','radiobutton','String','Visible','HorizontalAlignment','left','Value',1,'FontSize',8,'KeyPressFcn',@mainkeypress);
handles.subtbgrall = uicontrol(handles.subtbgrtype,'units','pixels','Position',[56 2 35 16],'Style','radiobutton','String','All','HorizontalAlignment','left','FontSize',8,'KeyPressFcn',@mainkeypress);
handles.savebgr = uicontrol(handles.bgr,'units','pixels','Position',[5 5 91 20],'String','Save vis. signal','callback',@subtbgrcbk,'FontSize',8,'KeyPressFcn',@mainkeypress);

% Other objects
screenSize = get(0,'ScreenSize');
if screenSize(4)<=840, pos = get(handles.maingui,'position'); set(handles.maingui,'position',[pos(1) pos(2)-50 pos(3) 700]); end
if screenSize(4)<=740, pos = get(handles.maingui,'position'); set(handles.maingui,'position',[pos(1) pos(2)-100 pos(3) 600]); end
handles.hfig = figure('Toolbar','none','Menubar','none','Name','Zoomed image','NumberTitle','off','IntegerHandle','off','Visible','off','CloseRequestFcn',@hfigclosereq,'windowButtonDownFcn',@selectclick,'WindowButtonMotionFcn',@dragmouse,'windowButtonUpFcn',@dragbutonup,'WindowScrollWheelFcn',@zoominout,'KeyPressFcn',@mainkeypress);
    
set(handles.maingui,'Color',get(handles.imslider,'BackgroundColor'));
handles.cells = {};
handles.selectedCells = {};
handles.hpanel = -1;

% Variables intialization
initP; % Initialize parameters structure and some global variables
imsizes = zeros(5,3);
imageDispMode = 1;
shiftDispMode = 1;
pointsList = [];
pointsHandles = {};
btnDownPoint.x = Inf;
btnDownPoint.y = Inf;
frame = 1;
prevframe = 1;
magnification = 1;
zoomlocation = [];
iniMagnification = 100;
clear('pos');
handles.cells = {};
dragMode = false;
dragPosition = [];
shiftframes = [];
imageFolders = {'','','',''};
imageFiles = {'','','',''};
imageActive = false(1,4); % indicates whether the last image was loaded from file
logcheckw = true;
imageLimits = {[0 1],[0 1],[0 1],[0 1]};

displayImage
gdispinit;
1;

% End of main function code

function help_cbk(hObject, eventdata)
    folder = fileparts(which('oufti.m'));
    w = fullfile2(folder,'help','helpImageAlignTool.htm');
    if ~isempty(dir(w))
        web(w);
    end
end

% --- Aligning nested functions ---

function subtbgrcbk(hObject, eventdata)
    global rawPhaseData rawS1Data rawS2Data
    if hObject==handles.subtbgr
        channels = [];
        if get(handles.subtbgrvis,'Value')==1
            if imageDispMode==3, channels = 3;
            elseif imageDispMode==4, channels = 4;
            elseif  imageDispMode==1, displayImage, return
            end
        elseif get(handles.subtbgrall,'Value')==1
            if ~isempty(who('rawS1Data')) && ~isempty(rawS1Data), channels=3; end
            if ~isempty(who('rawS2Data')) && ~isempty(rawS2Data), channels=[channels 4]; end
        end
        subtractbgr(channels,[])
        displayImage
        displayCells
    elseif hObject==handles.savebgr
        if imageDispMode==1 && (isempty(who('rawPhaseData')) || isempty(rawPhaseData)), return; end
        if imageDispMode==3 && (isempty(who('rawS1Data')) || isempty(rawS1Data)), return; end
        if imageDispMode==4 && (isempty(who('rawS2Data')) || isempty(rawS2Data)), return; end
        [filename,pathname] = uiputfile('*.tif', 'Enter a filename for the first image');
        if(filename==0), return; end;
        if length(filename)>4 && strcmp(filename(end-3:end),'.tif'), filename = filename(1:end-4); end
        lng = imsizes(imageDispMode,3);
        ndig = ceil(log10(lng+1));
        istart = 1;
        for k=1:ndig
            if length(filename)>=k && ~isempty(str2num(filename(end-k+1:end)))
                istart = str2num(filename(end-k+1:end));
            else
                k=k-1;
                break
            end
        end
        filename = fullfile2(pathname,filename(1:end-k));
        w = waitbar(0, 'Saving files');
        for i=1:lng;
            fnum=i+istart-1;
            cfilename = [filename num2str(fnum,['%.' num2str(ndig) 'd']) '.tif'];
            if imageDispMode==1
                img = rawPhaseData(:,:,i);
            elseif imageDispMode==3
                img = rawS1Data(:,:,i);
            elseif imageDispMode==4
                img = rawS2Data(:,:,i);
            end
            if shiftDispMode==2 && ~isempty(shiftframes)
                img = shiftoneframe(img,shiftframes.x(frame),shiftframes.y(frame));
            end
            imwrite(img,cfilename,'tif','Compression','none');
            waitbar(i/lng, w);
        end
        close(w)
    end
end

function alignphaseframes(hObject, eventdata)
    
    if hObject==handles.alignfrompoints && ~isempty(pointsList)
        shiftframes = shiftfrompoints(pointsList);
        set(handles.alignfrompoints,'Enable','off');
        set(handles.resetshift,'Enable','on');
        set(handles.savealignment,'Enable','on');
        displayImage
        drawpoint
    elseif hObject==handles.alignframes
        p.aligndepth = str2num(get(handles.aligndepth,'String'));
        alignfrm
        if ~isempty(shiftframes)
            set(handles.resetshift,'Enable','on');
            set(handles.savealignment,'Enable','on');
            if ~isempty(pointsList)&&sum(pointsList.x~=0)>=2
                set(handles.alignfrompoints,'Enable','on');
            end
        end
        displayImage
        drawpoint
    elseif hObject==handles.savealignment
        if isempty(shiftframes), return; end
        [filename,pathname] = uiputfile('*.mat', 'Enter a filename to save alignment data to');
        if(filename==0), return; end;
        if length(filename)<5, filename = [filename '.mat']; end
        if ~strcmp(filename(end-3:end),'.mat'), filename = [filename '.mat']; end
        filename = fullfile2(pathname,filename);
        savealign(filename)
    elseif hObject==handles.loadalignment
        [filename,pathname] = uigetfile('*.mat', 'Enter a filename to save alignment data to');
        if(filename==0), return; end;
        filename = fullfile2(pathname,filename);
        loadalign(filename)
        set(handles.resetshift,'Enable','on');
        set(handles.savealignment,'Enable','on');
    elseif hObject==handles.resetshift
        shiftframes = [];
        set(handles.resetshift,'Enable','off');
        set(handles.savealignment,'Enable','off');
        if ~isempty(pointsList)&&sum(pointsList.x~=0)>=2
            set(handles.alignfrompoints,'Enable','on');
        elseif isempty(pointsList)||sum(pointsList.x~=0)<2
            set(handles.alignfrompoints,'Enable','off');
        end
    end
end 

% --- End of aligning nested functions ---

% --- GUI zoom and display nested functions ---

function resizefcn(hObject, eventdata)
    % resizes the main program window
    pos = get(handles.maingui,'position');
    pos = [max(pos(1),1) max(1,min(pos(2),screenSize(4)-20-max(pos(4),600))) max(pos(3:4),[780 510])];
    set(handles.maingui,'position',pos);
    set(handles.loadpanel,'pos',[3 pos(4)-800+772 780 29])
    set(handles.impanel,'pos',[17 80 pos(3)-770+750 pos(4)-800+600+90])
    set(handles.imslider,'pos',[2 80 15 pos(4)-800+600+90])   
end

function dispimgcontrol(hObject, eventdata)
    if get(handles.dispph,'Value')==1, imageDispMode=1; end
    if get(handles.disps1,'Value')==1, imageDispMode=3; end
    if get(handles.disps2,'Value')==1, imageDispMode=4; end
    displayImage
    drawpoint
end

function dispsftcontrol(hObject, eventdata)
    if get(handles.disporign,'Value')==1, shiftDispMode = 1; end
    if get(handles.dispshift,'Value')==1, shiftDispMode = 2; end
    displayImage
    drawpoint
end

function zoomcheck(hObject, eventdata)
    if ishandle(handles.hfig)
        if get(handles.zoomcheck,'Value')==1
            showhfig
        else
            hidehfig
        end
    end
end

function hfigclosereq(hObject, eventdata)
    set(handles.zoomcheck,'Value',0);
    hidehfig
end

function zoominout(hObject, eventdata)
    if strcmp(get(handles.hfig,'Visible'),'off'), return; end
    if hObject == handles.zoomin
        magnification = magnification*1.5;
    elseif hObject == handles.zoomout
        magnification = max(iniMagnification/100,magnification/1.5);
    elseif hObject==handles.hfig || (hObject==handles.maingui)
        if eventdata.VerticalScrollCount>0
            magnification = magnification*1.5;
        else
            magnification = max(1,magnification/1.5);
        end
    end
    apiMB = iptgetapi(handles.hMagBox);
    apiMB.setMagnification(magnification);
    apiSP = iptgetapi(handles.hpanel);
    apiSP.setMagnification(magnification);
    drawpoint
end

function hidehfig
    set(handles.hfig,'Visible','off');
    magnification = sscanf(get(handles.hMagBox,'String'),'%d')/100;
    apiMB = iptgetapi(handles.hMagBox);
    apiMB.setMagnification(0.1);
    apiSP = iptgetapi(handles.hpanel);
    zoomlocation = apiSP.getVisibleLocation();
    apiSP.setMagnification(0.1);
    set(handles.hMagBox,'Enable','off');
    set(handles.zoomin,'Enable','off');
    set(handles.zoomout,'Enable','off');
end

function showhfig
    set(handles.hfig,'Visible','on');
    apiMB = iptgetapi(handles.hMagBox);
    apiMB.setMagnification(magnification);
    apiSP = iptgetapi(handles.hpanel);
    apiSP.setMagnification(magnification);
    if ~isempty(zoomlocation), apiSP.setVisibleLocation(zoomlocation); end
    set(handles.hMagBox,'Enable','on');
    set(handles.zoomin,'Enable','on');
    set(handles.zoomout,'Enable','on');
end

function gdispinit
    % initiation of text display function
    % alternative to "disp" - text display to the workspace
    % modified from stand-alone version by removing 'CLOSE','VISIBLE','HIDE' commands 

    global gdisphandles

    if exist('gdisphandles','var') && isfield(gdisphandles,'gdispfig') && ~isempty(gdisphandles.gdispfig) && ishandle(gdisphandles.gdispfig)
        delete(gdisphandles.gdispfig)
    end
    
    screenSize2 = round(screenSize(3:4)/2);
    handles.gdispfig = figure('pos',[screenSize2-200 400 400],'CloseRequestFcn',@closelogreq,'Toolbar','none','Menubar','none','Name','cellTracker log window','NumberTitle','off','IntegerHandle','off','ResizeFcn',@resizelogfcn,'visible','off','KeyPressFcn',@gdispkeypress);
    handles.wnd = uicontrol(handles.gdispfig,'units','pixels','Position',[1 1 400 400],'Style','edit','Min',1,'Max',50,'BackgroundColor',[1 1 1],'HorizontalAlignment','left','FontSize',8);
    gdisphandles.gdispfig = handles.gdispfig;
    gdisphandles.wnd = handles.wnd;
    mde = com.mathworks.mde.desk.MLDesktop.getInstance;
    pause(0.005);
    try
        jFigPanel = mde.getClient('MicrobeTracker log window');
        gdisphandles.gdispobj = jFigPanel.getComponent(0).getComponent(0).getComponent(0).getComponent(0).getComponent(0).getComponent(0).getComponent(0);
    catch
    end
    gdisphandles.text = '';
end

function gdispkeypress(hObject, eventdata)
    % changes the color of display window between black and white
    c = get(handles.gdispfig,'CurrentCharacter');
    if isempty(c), return; end
    if strcmp(c,'b')
        set(handles.wnd,'BackgroundColor',[0 0 0],'ForegroundColor',[1 1 1]);
    elseif strcmp(c,'w')
        set(handles.wnd,'BackgroundColor',[1 1 1],'ForegroundColor',[0 0 0]);
    end
end
    
function logcheck(hObject, eventdata)
    if get(handles.logcheckw,'Value')==1
        logcheckw = true;
    else
        logcheckw = false;
    end
    if get(handles.logcheck,'Value')==1
        set(handles.gdispfig,'visible','on')
    else
        set(handles.gdispfig,'visible','off')
    end
end

function resizelogfcn(hObject, eventdata)
    figuresize = get(handles.gdispfig,'pos');
    set(handles.wnd,'pos',[1 1 figuresize(3:4)]);
end

function closelogreq(hObject, eventdata)
    set(handles.gdispfig,'visible','off')
    set(handles.logcheck,'Value',0);
end

% --- End of GUI zoom and display nested functions ---

function displayImage
    global rawPhaseData rawS1Data rawS2Data
    img = [];
    updateimsizes
    %if max(imsizeMAX)<1, return; end
    if frame<1, frame=1; end
    switch imageDispMode
     case 1
         if ~isempty(who('rawPhaseData'))
             if ~isempty(rawPhaseData)
                 if frame<=imsizes(1,3)
                    img = rawPhaseData(:,:,frame);
                 end
             end
         end
     case 3
         if ~isempty(who('rawS1Data'))
             if ~isempty(rawS1Data)
                 if frame<=imsizes(3,3)
                    img = rawS1Data(:,:,frame);
                 end
             end
         end
     case 4
         if ~isempty(who('rawS2Data'))
             if ~isempty(rawS2Data)
                 if frame<=imsizes(4,3)
                    img = rawS2Data(:,:,frame);
                 end
             end
         end
     otherwise
        %gdisp('No image loaded')
        %return
    end
    if isempty(img), img = ones(imsizes(end,1:2)); end
    if shiftDispMode==2 && ~isempty(shiftframes)
        img = shiftoneframe(img,shiftframes.x(frame),shiftframes.y(frame));
    end
    dellist = [];
    if ishandle(handles.hpanel)
        apiSP = iptgetapi(handles.hpanel);
        %magnification = apiSP.getMagnification();
        zoomlocation = apiSP.getVisibleLocation();
        dellist{1} = handles.hMagBox;
        dellist = [dellist get(handles.hfig,'Children')];
        dellist = [dellist get(handles.impanel,'Children')];
    end
    if strcmp(get(handles.zoomin,'Enable'),'off')
        set(handles.zoomcheck,'Enable','on');
        set(handles.zoomin,'Enable','on');
        set(handles.zoomout,'Enable','on');
    end
    if get(handles.zoomcheck,'Value')==0 && strcmp(get(handles.hfig,'Visible'),'on')
        set(handles.hfig,'Visible','off');
    elseif get(handles.zoomcheck,'Value')==1 && strcmp(get(handles.hfig,'Visible'),'off')
        set(handles.hfig,'Visible','on');
    end
    if ~isempty(dellist),
        for i=1:length(dellist)
            if ishandle(dellist{i})
                delete(dellist{i})
            end
        end
    else
        %screenSize = get(0,'ScreenSize');
        iniMagnification = 100;
        if size(img,2)<0.75*screenSize(4) || size(img,1)<0.75*screenSize(3)
            iniMagnification = min(100,floor(75*min(screenSize(4)/size(img,1),screenSize(3)/size(img,2))));
        end
        magnification = iniMagnification/100;
    end
    ax = axes('parent',handles.hfig);
    if ~ishandle(ax), ax = axes('parent',handles.hfig); gdisp('Error creating axes'); end
    if ~ishandle(ax), gdisp('Image display terminated: cannot create axes'); return; end
    pos = get(handles.hfig,'pos');
    warning off % ('off','backtrace');
    handles.himage = imshow(img,imageLimits{imageDispMode},'parent',ax,'ini',iniMagnification);
    if ~ishandle(handles.himage), gdisp('Image display terminated: cannot create h-image'); return; end
    warning on % ('on','backtrace');
    set(handles.hfig,'pos',pos);
    handles.hpanel = imscrollpanel(handles.hfig,handles.himage);
    if ~ishandle(handles.hpanel), gdisp('Image display terminated: cannot create h-panel'); return; end
    set(handles.hpanel,'Units','normalized','Position',[0 0 1 1]);
    handles.hMagBox = immagbox(handles.zoompanel,handles.himage);
    set(handles.hMagBox,'Position',[50 40 60 20]);
    handles.hovervw = imoverviewpanel(handles.impanel,handles.himage);
    apiMB = iptgetapi(handles.hMagBox);
    apiSP = iptgetapi(handles.hpanel);
    if get(handles.zoomcheck,'Value')==0, 
        set(handles.hMagBox,'Enable','off');
        set(handles.zoomin,'Enable','off');
        set(handles.zoomout,'Enable','off');
        apiMB.setMagnification(0.1);
        apiSP.setMagnification(0.1);
    else
        apiMB.setMagnification(magnification);
        apiSP.setMagnification(magnification);
        if ~isempty(zoomlocation), apiSP.setVisibleLocation(zoomlocation); end
    end
    imstring1 = {'ph','fm','s1','s2'};
    if imageActive(imageDispMode)==false
        fname = slashsplit2(imageFolders{imageDispMode});
    else
        fname = slashsplit2(imageFiles{imageDispMode});
    end
    set(handles.currentimage,'String',[fname ' (' imstring1{imageDispMode} ')']);
end
        
function imslider(hObject, eventdata)
    prevframe = frame;
    frame = imsizes(end,3)+1-round(get(hObject,'value'));
    displayImage
    drawpoint
    set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(imsizes(end,3))]);
end

function updateslider
    updateimsizes
    s = imsizes(end,3);
    frame = max(min(frame,s),1);
    if s>1
        set(handles.imslider,'min',1,'max',s,'Value',s+1-frame,'SliderStep',[1/(s-1) 1/(s-1)],'Enable','on');
        set(handles.currentframe,'String',[num2str(frame) ' of ' num2str(s)]);
    end
end

function mainkeypress(hObject, eventdata)
    % key press callback
    if hObject==handles.hfig
        c = get(handles.hfig,'CurrentCharacter');
    else
        c = get(handles.maingui,'CurrentCharacter');
    end
    if isempty(c), return; end
    if double(c)==30 % up key - moves to the previous frame
        set(handles.imslider,'value',min(imsizes(end,3),get(handles.imslider,'value')+1));
        imslider(handles.imslider, eventdata)
    elseif double(c)==31 % down key - moves to the next frame
        set(handles.imslider,'value',max(1,get(handles.imslider,'value')-1));
        imslider(handles.imslider, eventdata)
    elseif strcmp(c,'s') || double(c)==19 % s - save alignment
        alignphaseframes(handles.savealignment, eventdata)
    elseif strcmp(c,'l') || double(c)==12 % l - load alignment
        alignphaseframes(handles.loadalignment, eventdata)
    elseif double(c)==127 || double(c)==27 % delete or escape - remove the point on the current frame
         pointsList.x(frame) = 0;
         pointsList.y(frame) = 0;
         drawpoint
    elseif double(c)==26 % Control+Z - undo a manual operation
        doundo;
    end
end

function selectclick(hObject, eventdata)
     
     global rawPhaseData rawS1Data rawS2Data
     if imageDispMode==1 && (isempty(rawPhaseData)||frame>size(rawPhaseData,3)), return; end
     if imageDispMode==2 && (isempty(rawS1Data)||frame>size(rawS1Data,3)), return; end
     if imageDispMode==3 && (isempty(rawS2Data)||frame>size(rawS2Data,3)), return; end
     
     if hObject==handles.maingui
        ax = get(get(handles.impanel,'children'),'children');
        if iscell(ax), ax = ax{1}; end;
        extend = strcmpi(get(handles.maingui,'SelectionType'),'extend');
        control = strcmpi(get(handles.maingui,'SelectionType'),'alt');
        dblclick = strcmpi(get(handles.maingui,'SelectionType'),'open');
     else
        if ~ishandle(handles.himage), return; end
        ax = get(handles.himage,'parent');
        extend = strcmpi(get(handles.hfig,'SelectionType'),'extend');
        control = strcmpi(get(handles.hfig,'SelectionType'),'alt');
        dblclick = strcmpi(get(handles.hfig,'SelectionType'),'open');
     end
     ps = get(ax,'CurrentPoint');
     if ps(1,1)<0 || ps(1,1)>imsizes(end,2) || ps(1,2)<0 || ps(1,2)>imsizes(end,1), return; end;
     btnDownPoint.x = ps(1,1);
     btnDownPoint.y = ps(1,2);
     flag = true;
     if flag && hObject==handles.hfig && ~extend && ~control
         dragMode = true;
         dragPosition = getmousepos;
     end
     if strcmp(get(handles.hfig,'Visible'),'off') || dblclick || extend || control
         % Now draw a reper point
        if shiftDispMode==1 || isempty(shiftframes)
            pointsList.x(frame) = round(btnDownPoint.x);
            pointsList.y(frame) = round(btnDownPoint.y);
        else
            pointsList.x(frame) = round(btnDownPoint.x)-shiftframes.y(frame);
            pointsList.y(frame) = round(btnDownPoint.y)-shiftframes.x(frame);
        end
         drawpoint
         if sum(pointsList.x~=0)>=2
             set(handles.alignfrompoints,'Enable','on');
         end
     end
end

function drawpoint
    global rawPhaseData rawS1Data rawS2Data
    if isempty(pointsList) || length(pointsList.x)<frame || pointsList.x(frame)==0, return; end
    if imageDispMode==1 && (isempty(rawPhaseData)||frame>size(rawPhaseData,3)), return; end
    if imageDispMode==2 && (isempty(rawS1Data)||frame>size(rawS1Data,3)), return; end
    if imageDispMode==3 && (isempty(rawS2Data)||frame>size(rawS2Data,3)), return; end
    ax = get(get(handles.impanel,'children'),'children');
    ah = ~ishandle(ax);
    if ah(1) && ~iscell(ax), gdisp('Cells display terminated: cannot find axes'); return; end
    if iscell(ax), ax = ax{1}; end;
    ax(2) = get(handles.himage,'parent');
    col = [0 1 0];
    d = 20;
    d2 = d/magnification;
    if length(pointsHandles)>=frame && ~isempty(pointsHandles{frame}) && ishandle(pointsHandles{frame}(1))
        delete(pointsHandles{frame})
    end
    if shiftDispMode==1
        x = pointsList.x(frame);
        y = pointsList.y(frame);
    else
        x = pointsList.x(frame)+shiftframes.y(frame);
        y = pointsList.y(frame)+shiftframes.x(frame);
    end
    set(ax(1),'NextPlot','add');
    set(ax(2),'NextPlot','add');
    pointsHandles{frame}(1) = plot(ax(1),[x-d x+d],[y y],'color',col);
    pointsHandles{frame}(2) = plot(ax(1),[x x],[y-d y+d],'color',col);
    pointsHandles{frame}(3) = plot(ax(2),[x-d2 x+d2],[y y],'color',col);
    pointsHandles{frame}(4) = plot(ax(2),[x x],[y-d2 y+d2],'color',col);
    set(ax(1),'NextPlot','replace');
    set(ax(2),'NextPlot','replace');
end


    
function dragbutonup(hObject, eventdata)
    dragMode = false;
end

function pos = getmousepos
    ax = get(handles.himage,'parent');
    ps = get(ax,'CurrentPoint');
    pos.x = ps(1,1);
    pos.y = ps(1,2);
    if ps(1,1)<0 || ps(1,1)>imsizes(end,2) || ps(1,2)<0 || ps(1,2)>imsizes(end,1), pos = []; end;
end

function mousemove(hObject, eventdata)
    if hObject==handles.maingui
        ax = get(get(handles.impanel,'children'),'children');
        if iscell(ax), ax = ax{1}; end;
        extend = strcmp(get(handles.maingui,'SelectionType'),'extend');
    else
        if ~ishandle(handles.himage), return; end
        ax = get(handles.himage,'parent');
        extend = strcmp(get(handles.hfig,'SelectionType'),'extend');
    end
    if isempty(ax), return; end
    pt = get(ax,'CurrentPoint');
    if isempty(pt), return; end
    set(handles.maingui,'Pointer','arrow') % TODO: create more proper cursor control
    pt = round(pt(1,1:2));
    if pt(1)>0 && pt(2)>0 && pt(1)<imsizes(end,2) && pt(2)<imsizes(end,1)
        set(handles.celldata.coursor,'String',['x=' num2str(pt(1)) ', y=' num2str(pt(2))]);
    else
        set(handles.celldata.coursor,'String','');
    end
end

function dragmouse(hObject, eventdata)
    mousemove(hObject, eventdata);
    if dragMode
        dragPositionNew = getmousepos;
        if isempty(dragPositionNew), dragMode=false; return; end
        apiHP = iptgetapi(handles.hpanel);
        pos = apiHP.getVisibleLocation();
        rect = apiHP.getVisibleImageRect();
        apiHP.setVisibleLocation(min(imsizes(end,2)-rect(3),max(0,pos(1)+dragPosition.x-dragPositionNew.x)),...
            min(imsizes(end,1)-rect(4),max(0,pos(2)+dragPosition.y-dragPositionNew.y)));
    end
end


% --- Other GUI nested functions ---

function mainguiclosereq(hObject, eventdata)
    cleardata
end

function contrast_cbk(hObject, eventdata)
    if ~ishandle(handles.hpanel), return; end
    if ~ishandle(handles.hfig), return; end
    ax = get(get(handles.impanel,'children'),'children');
    if iscell(ax), ax = ax{1}; end;
    imgh = findall(ax,'Type','image');
    img = get(imgh,'CData');
    if strcmp(class(img),'double')
        set(imgh,'CData',im2uint16(get(imgh,'CData')));
        set(ax,'CLim',get(ax,'CLim')*2^16);
    end
    clim = get(ax,'CLim');
    if clim(1)<min(min(img)), clim=double(min(min(img)))+[0 clim(2)-clim(1)] ; end
    if clim(2)>max(max(img)), clim(1)= max(double(max(max(img)))+(-clim(2)+clim(1)),double(min(min(img)))); clim(2)=double(max(max(img))); end
    if clim(2)<=clim(1), clim(1)=clim(2)-1; end
    set(ax,'CLim',clim);
    handles.ctrfigure = imcontrast(ax);
    set(handles.ctrfigure,'CloseRequestFcn',@ctrclosereq)
end

function ctrclosereq(hObject, eventdata)
    ax = get(get(handles.impanel,'children'),'children');
    if iscell(ax), ax = ax{1}; end;
    imageLimits{imageDispMode} = get(ax,'CLim');
    delete(handles.ctrfigure)
end

% --- Parameters GUI nested functions ---

function initP
    global se maskdx maskdy
    se = strel('arb',[0 1 0;1 1 1;0 1 0]); % erosion mask, can be 4 or 8 neighbors
    maskdx = fliplr(fspecial('sobel')'); % masks for computing x & y derivatives
    maskdy = fspecial('sobel');
end

% --- End of parameters GUI nested functions ---

% --- Loading and saving images nested functions ---

function res = loadstackdisp(n,filename)
    res = loadimagestack(n,filename);
    updateslider
    displayImage
    enableDetectionControls
end

function loadimagesdisp(n,folder)
    loadimages(n,folder)
    updateslider
    displayImage
    enableDetectionControls
end

function enableDetectionControls
    % Enable cell detection controls
    set(handles.alignframes,'Enable','on');
    set(handles.loadalignment,'Enable','on');
end

function loadstack(hObject, eventdata)
    chk = get(handles.loadcheck,'value'); % if yes, load image stack using Bioformats, otherwise load TIFFs
    if hObject==handles.loadphase
        if chk
            if bformats
                [filename,pathname] = uigetfile('*.*','Select Stack File with Phase Images...',imageFiles{1});
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Phase Images...',imageFiles{1});
            end
            if isequal(filename,0), return; end;
            filename = fullfile(pathname,filename);
            filenametmp = imageFiles{1};
            imageFiles{1} = filename;
            res = loadstackdisp(1,filename);
            if res
                imageActive(1) = true;
            else
                imageFiles{1} = filenametmp;
            end
        else
            loadphase(hObject, eventdata)
        end
    elseif hObject==handles.loads1
        if chk
            if bformats
                [filename,pathname] = uigetfile('*.*','Select Stack File with Signal 1 Images...',imageFiles{3});
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Signal 1 Images...',imageFiles{3});
            end
            if isequal(filename,0), return; end;
            filename = fullfile(pathname,filename);
            filenametmp = imageFiles{3};
            imageFiles{3} = filename;
            res = loadstackdisp(3,filename);
            if res
                imageActive(3) = true;
            else
                imageFiles{3} = filenametmp;
            end
        else
            loads1(hObject, eventdata)
        end
    elseif hObject==handles.loads2
        if chk
            if bformats
                [filename,pathname] = uigetfile('*.*','Select Stack File with Signal 2 Images...',imageFiles{4});
            else
                [filename,pathname] = uigetfile({'*.tif';'*.tiff'},'Select Stack File with Signal 2 Images...',imageFiles{4});
            end
            if isequal(filename,0), return; end;
            filename = fullfile(pathname,filename);
            filenametmp = imageFiles{4};
            imageFiles{4} = filename;
            res = loadstackdisp(4,filename);
            if res
                imageActive(4) = true;
            else
                imageFiles{4} = filenametmp;
            end
        else
            loads2(hObject, eventdata)
        end
    end
end

function loadphase(hObject, eventdata)
    global rawPhaseFolder
    rawPhaseFolder = uigetdir(imageFolders{1},'Select Directory with Phase Images...');
    if isequal(rawPhaseFolder,0), return; end;
    imageActive(1) = false;
    loadimagesdisp(1,rawPhaseFolder)
end

function loads1(hObject, eventdata)
    global rawS1Folder
    rawS1Folder = uigetdir(imageFolders{3},'Select Directory with Signal 1 Images...');
    if isequal(rawS1Folder,0), return; end;
    imageActive(3) = false;
    loadimagesdisp(3,rawS1Folder)
end

function loads2(hObject, eventdata)
    global rawS2Folder
    rawS2Folder = uigetdir(imageFolders{4},'Select Directory with Signal 2 Images...');
    if isequal(rawS2Folder,0), return; end;
    imageActive(4) = false;
    loadimagesdisp(4,rawS2Folder)
end

% --- End of loading and saving images nested functions ---

end % ------------------------- END MAIN FUNCTION -------------------------

%% Aligning global functions

function s = shiftfrompoints(pl)
    global rawPhaseData
    if isempty(pl)||sum(pl.x~=0)==0||isempty(rawPhaseData)||2>size(rawPhaseData,3), s=[]; return; end
    lng = size(rawPhaseData,3);
    s.x = [];
    s.y = [];
    f0 = find(pl.x~=0);
    for f = 1:lng
        f1 = max(f0(f0<=f));
        f2 = min(f0(f0>=f));
        if isempty(f1)
            s.y(f) = pl.x(f2);
            s.x(f) = pl.y(f2);
        elseif isempty(f2)
            s.y(f) = pl.x(f1);
            s.x(f) = pl.y(f1);
        elseif f1==f2
            s.y(f) = pl.x(f1);
            s.x(f) = pl.y(f1);
        else
            s.y(f) = (pl.x(f1)*(f2-f)+pl.x(f2)*(f-f1))/(f2-f1);
            s.x(f) = (pl.y(f1)*(f2-f)+pl.y(f2)*(f-f1))/(f2-f1);
        end
    end
    s.x = round(s.x(1)-s.x);
    s.y = round(s.y(1)-s.y);
end

function loadalign(filename)
    global shiftframes
    % This function loads aligning data from file <filename>
    % The file must exist and be a .mat file
    % Intended use: with "alignphaseframes" callback & batch files
    loaded = load(filename,'shiftframes');
    if ~isfield(loaded,'shiftframes'), gdisp('This file does not contain alignment data'); return; end
    shiftframestmp = loaded.shiftframes;
    if ~isstruct(shiftframestmp), gdisp('This file does not contain alignment data'); return; end
    if ~isfield(shiftframestmp,'x') || ~isfield(shiftframestmp,'y'), gdisp('This file does not contain alignment data'); return; end
    shiftframes.x = shiftframestmp.x;
    shiftframes.y = shiftframestmp.y;
    gdisp('Alignment data loaded')
end

function savealign(filename)
    global shiftframes %#ok<NUSED>
    % This function saves aligning data to file <filename>
    % The file must be a .mat file
    % Intended use: with "alignphaseframes" callback & batch files
    save(filename,'shiftframes');
    gdisp('Alignment data saved')
end

function alignfrm
    % This function alignes phase images
    % The result is stored in "shiftframes" structure with x & y fields of the main function 
    % Intended use: with "alignphaseframes" callback & batch files
    global rawPhaseData p shiftframes pointsList handles
    p.aligndepth = str2num(get(handles.aligndepth,'String'));
    if isempty(p.aligndepth), gdisp('Images not aligned: parameter "aligndepth" not provided.'); return; end
    if isempty(rawPhaseData), gdisp('Images not aligned: no phase images loaded.'); return; end
    shiftframes=alignframes(rawPhaseData,p.aligndepth,shiftfrompoints(pointsList)); % 
    gdisp('Images aligned')
end

%% Initialization global functions

function cleardata
    global rawPhaseData rawS1Data rawS2Data shiftframes imsizes handles %#ok<NUSED>
    % close open windows
    if exist('handles','var') && isstruct(handles)
        fields = fieldnames(handles);
        for i=1:length(fields)
            eval(['cfield = handles.' fields{i} ';'])
            if ishandle(cfield)
                delete(cfield);
            elseif isstruct(cfield)
                fields2 = fieldnames(cfield);
                for k=1:length(cfield)
                    for j=1:length(fields2)
                        eval(['if ishandle(cfield(' num2str(k) ').' fields2{j} '), delete(cfield(' num2str(k) ').' fields2{j} '); end'])
                    end
                end
            end
        end
    end
    % cleas variables
    clear global rawPhaseData rawS1Data rawS2Data shiftframes imsizes handles
end

%% Images global function

function subtractbgr(channels,range)
    % background subrtaction routine:
    % "channels" - list of channels (3-signal 1, 4-signal 2)
    % "range" - [first_frame last_frame] (empty = all frames)
    
    global rawPhaseData rawS1Data rawS2Data imsizes se handles
    
    p.bgrErodeNum = str2num(get(handles.bgrErodeNum,'String'));
    if isempty(p.bgrErodeNum) || ~strcmp(class(p.bgrErodeNum),'double')
        gdisp('Background subtraction failed: parameter "bgrErodeNum" not provided.');
        return
    end
    if isempty(channels), channels = [3 4]; end
    if min(imsizes(channels,1))<2, return; end
    if isempty(rawPhaseData), gdisp('Background subtraction failed: no phase images loaded'); return; end
    if isempty(range), range = [1 10000]; end
    if length(range)==1, range = [range range]; end
    f = channels*0;
    for g=1:length(channels)
        if channels(g)==3
            if imsizes(3,1)<2, continue;
            else crange=[max(1,range(1)) min(imsizes(3,3),range(2))];
            end
        elseif channels(g)==4
            if imsizes(4,1)<2, continue; % isempty(who('rawS2Data')) || isempty(rawS2Data), 
            else crange=[max(1,range(1)) min(imsizes(4,3),range(2))];
            end
        else
            continue
        end
        for i=crange(1):crange(2)
            f(g) = 1;
            imgP = rawPhaseData(:,:,i);
            if isempty(imgP), continue; end
            if channels(g)==3, img = rawS1Data(:,:,i); end
            if channels(g)==4, img = rawS2Data(:,:,i); end
            thres = graythreshreg(imgP);
            mask = im2bw(imgP,thres);
            for k=1:p.bgrErodeNum, mask = imerode(mask,se); end
            bgr = mean(img(mask));
            img0 = int32(img);
            img1 = img0-bgr;
            img2 = max(0,img1);
            img = uint16(img2);
            if channels(g)==3, rawS1Data(:,:,i) = img; end
            if channels(g)==4, rawS2Data(:,:,i) = img; end
            if mod(i,5)==0, gdisp(['Subtracting backgroung from signal ' num2str(channels(g)-2) ', frame ' num2str(i)]); end
        end
    end
    if sum(f)>1
        gdisp(['Subtracting backgroung completed from ' sum(f) ' channels']);
    elseif sum(f)==1
        gdisp(['Subtracting backgroung completed from channel ' num2str(channels(f))]);
    end
end

function bgr = phasebgr(img,thres)
    global se p
    mask = ~im2bw(img,thres);
    for k=1:p.bgrErodeNum, mask = imerode(mask,se); end
    bgr = mean(img(mask));
end

function res = loadimagestack(n,filename)
    % loads image stacks using Bioformats
    % "n" - channel (1-phase, 2-extra, 3-signal1, 4-signal2)
    % "filename" - stack file name
    global rawPhaseData rawS1Data rawS2Data imsizes imageLimits
    bformats = checkbformats(0);
    res = false;
    if n==1
        str='rawPhaseData';
    elseif n==3
        str='rawS1Data';
    elseif n==4
        str='rawS2Data';
    else
        gdisp('Error loading images: channel not supported');
    end
    if (length(filename)>4 && strcmpi(filename(end-3:end),'.tif')) || (length(filename)>5 && strcmpi(filename(end-4:end),'.tiff'))
        % loading TIFF files
        try
            info = imfinfo(filename);
            numImages = numel(info);
            w = waitbar(0, 'Loading images, please wait...');
            lng = info(1).BitDepth;
            if lng==8
                cls='uint8';
            elseif lng==16
                cls='uint16';
            elseif lng==32
                cls='uint32';
            else
                gdisp('Error in image bitdepth loading multipage TIFF images: no images loaded');return;
            end
            eval([str '=zeros(' num2str(info(1).Height) ',' num2str(info(1).Width) ',' num2str(numImages) ',''' cls ''');'])
            for i = 1:numImages
                img = imread(filename,i,'Info',info);
                eval([str '(:,:,' num2str(i) ')=img;'])
                waitbar(i/numImages, w);
            end
            close(w)
            eval(['imageLimits{n} = 2^' num2str(lng) '*mean(stretchlim(' str ',[0.0001 0.9999]),2);']);
            eval(['imsizes(n,:) = [size(' str ',1) size(' str ',2) size(' str ',3)];']);
            gdisp(['Loaded ' num2str(imsizes(n,3)) ' images from a multipage TIFF'])
            updateimsizes
            res = true;
        catch
            gdisp('Error loading multipage TIFF images: no images loaded');
        end
    elseif bformats
        % loading all formats other than TIFF
        try
            breader = loci.formats.ChannelFiller();
            breader = loci.formats.ChannelSeparator(breader);
            breader = loci.formats.gui.BufferedImageReader(breader);
            breader.setId(filename);
            numSeries = breader.getSeriesCount();
            if numSeries~=1, gdisp('Incorrect image stack format: no images loaded'); return; end; 
            breader.setSeries(0);
            wd = breader.getSizeX();
            hi = breader.getSizeY();
            shape = [wd hi];
            numImages = breader.getImageCount();
            if numImages<1, gdisp('Incorrect image stack format: no images loaded'); return; end;
            nBytes = loci.formats.FormatTools.getBytesPerPixel(breader.getPixelType());
            if nBytes==1
                cls = 'uint8';
            else
                cls = 'uint16';
            end
            eval([str '=zeros(' num2str(hi) ',' num2str(wd) ',' num2str(numImages) ',''' cls ''');'])
            w = waitbar(0, 'Loading images, please wait...');
            for i = 1:numImages
                img = breader.openImage(i-1);
                pix = img.getData.getPixels(0, 0, wd, hi, []);
                arr = reshape(pix, shape)';
                if nBytes==1
                    arr2 = uint8(arr/256);
                else
                    arr2 = uint16(arr);
                end
                eval([str '(:,:,' num2str(i) ')=arr2;'])
                waitbar(i/numImages, w);
            end
            close(w)
            % eval(['cls = class(' str ');']);
            if strcmp(cls,'uint8'), lng=8; elseif strcmp(cls,'uint16'), lng=16; elseif strcmp(cls,'uint32'), lng=32;
                else gdisp('Error in image bitdepth loading images using BioFormats: no images loaded');return; end
            eval(['imageLimits{n} = 2^' num2str(lng) '*mean(stretchlim(' str ',[0.0001 0.9999]),2);']);
            eval(['imsizes(n,:) = [size(' str ',1) size(' str ',2) size(' str ',3)];']);
            gdisp(['Loaded ' num2str(imsizes(n,3)) ' images using BioFormats'])
            updateimsizes
            res = true;
        catch
            gdisp('Error loading images using BioFormats: no images loaded');
        end
    else % unsupported format of images
        gdisp('Error loading images: the stack must be in TIFF format for BioFormats must be loaded');
    end
end

function loadimages(n,folder)
    % loads TIFF (image) files into the specified channel:
    % "n" - channel (1-phase, 2-extra, 3-signal1, 4-signal2)
    % "folder" - folder name
    % for actual loading uses loadimageseries routine
    global rawPhaseData rawS1Data rawS2Data imsizes imageFolders imageLimits %#ok<NUSED>
    if n==1, str='rawPhaseData'; end
    % if n==2, str='rawFMData'; end
    if n==3, str='rawS1Data'; end
    if n==4, str='rawS2Data'; end
    filenames = ''; %#ok<NASGU>
    dirname = ''; %#ok<NASGU>
    imageFolders{n} = folder;
    eval(['[' str ', filenames, folder] = loadimageseries(folder,1);']);
    eval(['cls = class(' str ');']);
    if strcmp(cls,'uint8'), lng=8; elseif strcmp(cls,'uint16'), lng=16; elseif strcmp(cls,'uint32'), lng=32;
        else gdisp('No images loaded');return; end
    eval(['imageLimits{n} = 2^' num2str(lng) '*mean(stretchlim(' str ',[0.0001 0.9999]),2);']);
    %eval(['imageLimits{n} = im2double([min(min(min(' str '))) max(max(max(' str ')))]);']);
    if(folder==-1), return; end; 
    eval(['imsizes(n,:) = [size(' str ',1) size(' str ',3) size(' str ',3)];']);
    gdisp(['Loaded ' num2str(imsizes(n,3)) ' files'])
    updateimsizes
end

function updateimsizes
    % Updates the structure "imsizes" chat contains the information about 
    % the size of each images stack (phase, extra, signa1, signal2) and
    % the area occupied by the meshes. Needed for display purposes.
    global rawPhaseData rawS1Data rawS2Data imsizes
    imsizes(1,:)=[size(rawPhaseData,1) size(rawPhaseData,2) size(rawPhaseData,3)];
    % imsizes(2,:)=[size(rawFMData,1) size(rawFMData,2) size(rawFMData,3)];
    imsizes(3,:)=[size(rawS1Data,1) size(rawS1Data,2) size(rawS1Data,3)];
    imsizes(4,:)=[size(rawS2Data,1) size(rawS2Data,2) size(rawS2Data,3)];
    imsizes(end,:) = max(imsizes(1:end-1,:));
    if imsizes(end,1)==0, imsizes(end,:) = [400 500 1]; end
end

% ------------- Functions, that used to be in separate files --------------

function res = graythreshreg(img)
    % threshold calculated in a regionSelectionRect region
    global regionSelectionRect
    sz = size(img);
    if isempty(regionSelectionRect)
        res = graythresh(img(ceil(sz(1)*0.05):floor(sz(1)*0.95),ceil(sz(2)*0.05):floor(sz(2)*0.95),1));
    else
        res = graythresh(imcrop(img,regionSelectionRect));
    end
end

%% Shifting frames

function res=alignframes(A,depth,guess)
    
    mrg = round(min(size(A,1),size(A,2))*0.05);
    fld = [size(A,1)-2*mrg size(A,2)-2*mrg];
    time1 = clock;
    x0=[0 1 1 0 -1 -1 -1 0 1];
    y0=[0 0 1 1 1 0 -1 -1 -1];
    nframes = size(A,3);
    %field = [size(A,1) size(A,2)];
    memory = double(A(:,:,1));
    score = zeros(1,9);
    shiftX = zeros(1,nframes);
    shiftY = zeros(1,nframes);
    for frame=2:nframes
        memory = memory*(1-1/depth) + double(A(:,:,frame-1))/depth;
        sc2memory = imresize(memory,0.5);
        sc4memory = imresize(memory,0.25);
        cframe = double(A(:,:,frame));
        sc2cframe = imresize(cframe,0.5);
        sc4cframe = imresize(cframe,0.25);
        if ~isempty(guess)
            gx1 = guess.x(frame)-guess.x(frame-1);
            gy1 = guess.y(frame)-guess.y(frame-1);
        else
            gx1 = 0;
            gy1 = 0;
        end
        gx2 = round(gx1/2);
        gy2 = round(gy1/2);
        gx3 = round(gx1/4);
        gy3 = round(gy1/4);
        [xF,yF] = alignoneframe(sc4cframe,sc4memory,gx3,gy3,round(mrg/4));
        [xF,yF] = alignoneframe(sc2cframe,sc2memory,2*(xF-gx3)+gx2,2*(yF-gy3)+gy2,round(mrg/2));
        [xF,yF] = alignoneframe(cframe,memory,2*(xF-gx2)+gx1,2*(yF-gy2)+gy1,mrg);
        shiftX(frame) = xF;
        shiftY(frame) = yF;
        if depth>1 && (xF~=0 || yF~=0)
            fldX = max(1,xF+1):min(fld(1),fld(1)+xF);
            fldY = max(1,yF+1):min(fld(2),fld(2)+yF);
            fldX2 = max(1,-xF+1):min(fld(1),fld(1)-xF);
            fldY2 = max(1,-yF+1):min(fld(2),fld(2)-yF);
            memory(fldX2,fldY2) = memory(fldX,fldY);
        end
        gdisp(['frame = ' num2str(frame) ', shift ' num2str(xF) ',' num2str(yF) ' pixels'])
    end
    shiftX = cumsum(shiftX);
    shiftY = cumsum(shiftY);
    time2 = clock;
    gdisp(['Finised, elapsed time ' num2str(etime(time2,time1)) ' s']);  

    function [x,y] = alignoneframe(cframe,memory,x,y,margin)
        cframetmp = cframe(margin+1:end-margin,margin+1:end-margin);
        memorytmp = memory(margin+1:end-margin,margin+1:end-margin);
        field = [size(cframe,1)-2*margin size(cframe,2)-2*margin];
        while true
            for j=1:9
                dx=x0(j);
                dy=y0(j);
                xJ = x + dx;
                yJ = y + dy;
                fieldX = max(1,xJ+1):min(field(1),field(1)+xJ);
                fieldY = max(1,yJ+1):min(field(2),field(2)+yJ);
                fieldX2 = max(1,-xJ+1):min(field(1),field(1)-xJ);
                fieldY2 = max(1,-yJ+1):min(field(2),field(2)-yJ);
                score(j) = corel(memorytmp(fieldX,fieldY),cframetmp(fieldX2,fieldY2));
            end
            [scmax,ind] = max(score);
            if ind==1, break; end
            x = x+x0(ind);
            y = y+y0(ind);
        end
    end
    res.x = shiftX;
    res.y = shiftY;
end

% function B = shiftstack(A,varargin)
%     if length(varargin)==1
%         shift=varargin{1};
%     else
%         shift.x=varargin{1};
%         shift.y=varargin{2};
%     end
%     field = [size(A,1) size(A,2)];
%     B = ones(size(A),class(A));
%     for frame = 1:size(A,3)
%         xJ = shift.x(frame);
%         yJ = shift.y(frame);
%         fieldX = max(1,xJ+1):min(field(1),field(1)+xJ);
%         fieldY = max(1,yJ+1):min(field(2),field(2)+yJ);
%         fieldX2 = max(1,-xJ+1):min(field(1),field(1)-xJ);
%         fieldY2 = max(1,-yJ+1):min(field(2),field(2)-yJ);
%         B(:,:,frame) = B(:,:,frame)*max(max(A(:,:,frame)));
%         B(fieldX,fieldY,frame) = A(fieldX2,fieldY2,frame);
%     end
% end

function B = shiftoneframe(A,xJ,yJ)
    field = [size(A,1) size(A,2)];
    fieldX = max(1,xJ+1):min(field(1),field(1)+xJ);
    fieldY = max(1,yJ+1):min(field(2),field(2)+yJ);
    fieldX2 = max(1,-xJ+1):min(field(1),field(1)-xJ);
    fieldY2 = max(1,-yJ+1):min(field(2),field(2)-yJ);
    B = ones(size(A),class(A))*mean(mean(A(:,:)));
    B(fieldX,fieldY) = A(fieldX2,fieldY2);
end

function y=corel(X,Y)
y = mean(mean((X-mean(mean(X))).*(Y-mean(mean(Y)))));%/sqrt(mean(mean((X-mean(mean(X))).^2))/sqrt(mean(mean((Y-mean(mean(Y))).^2))));
end

%% --- Loading images ---

function [loadedData,filenames,dirName] = loadimageseries(pathToFolder,useWaitBar) %#ok<DEFNU>
    % This function loads a set of TIFF images
    gdisp(['Loading images from: ',pathToFolder]);

    % Set up some local variables to store the data
    filenames = [];
    dirName = 'None';
    
    % Try to open the selected directory and read files
    if(useWaitBar), w = waitbar(0, 'Loading image files, please wait...'); end;
    try
        files = dir([pathToFolder '/*.tif*']);
        name_counter = 0;
        loadedDataTmp=-1;
        for i=1:length(files)
            if(files(i).isdir == 1), continue; end;
            if(loadedDataTmp==-1)
                loadedDataTmp = imread(fullfile2(pathToFolder,files(i).name));
                filenames = [];
            end
            name_counter = name_counter+1;
        end;
        sz = size(loadedDataTmp);
        loadedData = zeros([sz(1:2) name_counter],class(loadedDataTmp));
        name_counter = 1;
        for i=1:length(files)
            if(files(i).isdir == 1), continue; end;
            loadedDataTmp = imread(fullfile2(pathToFolder,files(i).name));
            if prod((size(loadedDataTmp)==sz)*1)
                warning off
                eval(['loadedData(:,:,name_counter) = ' class(loadedDataTmp) '(mean(loadedDataTmp,3));']);
                warning on
            end
            filenames{name_counter} = files(i).name;
            name_counter = name_counter+1;
            if(useWaitBar),waitbar(i/length(files), w);end;
        end;
        if(loadedData==-1)
            errordlg('No image files to open in that folder!', 'Error loading files');
            if(useWaitBar),close(w);end;
            return;
        end;
    catch
        loadedData=-1;
        errordlg(['Could not open files!  Make sure you selected the correct ', ...
            'folder, all the filenames are the same length in that folder, ', ...
            'and there are no non-image files in that folder'], 'Error loading files');
        if(useWaitBar),close(w);end;
        return;
    end;
    if(useWaitBar),close(w);end;
    
    %If we got this far, then it was a success, so grab the directory
    %name that we loaded so we can display it later
    split = splitstr('/', pathToFolder);
    split = splitstr('\', split{end}); %I need this for windows cause windows does things backwards...
    dirName = split{end};
end

function res = slashsplit2(str)
    % This function truncates the path to a folder leaving the two highest
    % level folder names
    split = splitstr('/', str);
    if length(split)>1, split = [split{end-1} '/' split{end}]; else split = split{end}; end
    split = splitstr('\', split);
    if length(split)>1, split = [split{end-1} '\' split{end}]; else split = split{end}; end
    res = split;
end

function parts = splitstr(divider, str)
% This function splits a string into pieces at every occurrence of
% "divider" and returns the result as a cell array of strings. "divider"
% is not included in the output.
   splitlen = length(divider);
   parts = {};
   while 1
      k = strfind(str, divider);
      if isempty(k)
         parts{end+1} = str;
         break
      end
      parts{end+1} = str(1 : k(1)-1);
      str = str(k(1)+splitlen : end);
   end
end

function gdisp(data)
    % text display function
    % alternative to text display to screen
    % modified from stand-alone version by removing 'CLOSE','VISIBLE','HIDE' commands 

    global gdisphandles logcheckw
    
    if logcheckw
        disp(data)
    end
    
    if ~exist('gdisphandles','var') || ~isfield(gdisphandles,'gdispfig') || isempty(gdisphandles.gdispfig) || ~ishandle(gdisphandles.gdispfig)
        return
    end
    
    maxlines = 200;

    if ~isa(data,'char'), return; end

    gdisphandles.text = strvcat(gdisphandles.text,data);
    nlines = size(gdisphandles.text,1);
    if nlines>maxlines
        gdisphandles.text = gdisphandles.text(nlines-maxlines+1:nlines,:);
    end
    set(gdisphandles.wnd,'String',gdisphandles.text);
    refresh(gdisphandles.gdispfig)
    pause(0.005);
    try
        gdisphandles.gdispobj.setCaretPosition(gdisphandles.gdispobj.getDocument.getLength);
    catch
    end
end

function res = fullfile2(varargin)
    % This function replaces standard fullfile function in order to correct
    % a MATLAB bug that appears under Mac OS X
    % It produces results identical to fullfile under any other OS
    arg = '';
    for i=1:length(varargin)
        if ~strcmp(varargin{i},'\') && ~strcmp(varargin{i},'/')
            if i>1, arg = [arg ',']; end
            arg = [arg '''' varargin{i} ''''];
        end
    end
    eval(['res = fullfile(' arg ');']);
end

function res = checkparam(p,varargin)
    % this function checks if at least one of the provided parameters is
    % missing
    res = false;
    if isempty(p)
        res = true;
    end
    for i=1:length(varargin)
        if ~isfield(p,varargin{i})
            res = true;
        end
    end
end